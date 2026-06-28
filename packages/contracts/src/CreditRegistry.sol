// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {PoseidonT3} from "poseidon-solidity/PoseidonT3.sol";
import "./interfaces/ICreditRegistry.sol";

/// @title CreditRegistry
/// @notice Single source of truth for agent credit scores on Base Sepolia.
///         Tracks x402 payment history and computes a 300–900 credit score per agent wallet.
/// @dev Upgradeable via UUPS proxy pattern. Access controlled via OpenZeppelin AccessControl.
contract CreditRegistry is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard,
    UUPSUpgradeable,
    ICreditRegistry
{
    // ──────────────────────────────────────────────
    // Roles
    // ──────────────────────────────────────────────

    bytes32 public constant FACILITATOR_ROLE = keccak256("FACILITATOR_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant SCORE_ADMIN_ROLE = keccak256("SCORE_ADMIN_ROLE");

    // ──────────────────────────────────────────────
    // Storage
    // ──────────────────────────────────────────────

    struct AgentScore {
        uint256 totalPayments;      // count of confirmed x402 payments
        uint256 totalVolumeMicro;   // sum of payment amounts in USDC micro-units (6 decimals)
        uint256 firstPaymentTime;   // unix timestamp of first payment
        uint256 lastPaymentTime;    // unix timestamp of most recent payment
        uint256 disputeCount;       // reserved for future InsureAgent integration, default 0
        uint256 computedScore;      // 300–900 range
        bytes32 scoreCommitment;    // Pedersen commitment set by facilitator — used by ZK circuit
    }

    mapping(address => AgentScore) public scores;
    mapping(bytes32 => bool) public usedNonces;

    /// @notice Score weight configuration in basis points (10000 = 100%).
    /// [paymentWeight, volumeWeight, ageWeight, velocityWeight]
    uint256[4] public scoreWeights;

    /// @dev Reserved storage gap for future upgrades. gap + used new slots = 50.
    uint256[45] private __gap;

    // ──────────────────────────────────────────────
    // Events
    // ──────────────────────────────────────────────

    event PaymentRecorded(address indexed agent, uint256 amount, bytes32 nonce);
    event ScoreUpdated(address indexed agent, uint256 newScore);
    event ScoreWeightsUpdated(uint256[4] newWeights);
    event ProtocolPaused(address indexed guardian);
    event ProtocolUnpaused(address indexed admin);

    // ──────────────────────────────────────────────
    // Constructor & Initializer
    // ──────────────────────────────────────────────

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializer — replaces constructor for proxy deployment.
    /// @param initialAdmin The address that receives DEFAULT_ADMIN_ROLE and SCORE_ADMIN_ROLE.
    function initialize(address initialAdmin) public initializer {
        __AccessControl_init();
        __Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(SCORE_ADMIN_ROLE, initialAdmin);
    }

    // ──────────────────────────────────────────────
    // Core Functions (preserved from hackathon)
    // ──────────────────────────────────────────────

    /// @notice Called ONLY by whitelisted facilitators after a confirmed x402 payment.
    /// @param agent  The agent wallet address that made the payment.
    /// @param amount The payment amount in USDC micro-units (6 decimals).
    /// @param nonce  The unique EIP-3009 nonce (random 32-byte value).
    function recordPayment(
        address agent,
        uint256 amount,
        bytes32 nonce
    ) external onlyRole(FACILITATOR_ROLE) nonReentrant whenNotPaused {
        require(!usedNonces[nonce], "nonce already used");
        usedNonces[nonce] = true;

        AgentScore storage s = scores[agent];
        s.totalPayments += 1;
        s.totalVolumeMicro += amount;

        if (s.firstPaymentTime == 0) {
            s.firstPaymentTime = block.timestamp;
        }
        s.lastPaymentTime = block.timestamp;

        _recomputeScore(agent);

        emit PaymentRecorded(agent, amount, nonce);
        emit ScoreUpdated(agent, s.computedScore);
    }

    /// @notice Returns current score for an agent. 300 for agents with no payment history.
    function getScore(address agent) external view returns (uint256) {
        if (scores[agent].totalPayments == 0) {
            return 300;
        }
        return scores[agent].computedScore;
    }

    /// @notice Returns the on-chain commitment for ZK circuit verification.
    function getCommitment(address agent) external view returns (bytes32) {
        return scores[agent].scoreCommitment;
    }

    /// @notice Admin only — add/remove facilitator addresses.
    /// @dev In production, this is called via TimelockController by DEFAULT_ADMIN_ROLE.
    function setFacilitator(address facilitator, bool approved) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (approved) {
            _grantRole(FACILITATOR_ROLE, facilitator);
        } else {
            _revokeRole(FACILITATOR_ROLE, facilitator);
        }
    }

    /// @notice Facilitator-only — store a Noir-computed Pedersen commitment for ZK proofs.
    /// @dev The commitment is pedersen_hash([score, agent_address]) computed off-chain.
    function setCommitment(address agent, bytes32 commitment) external onlyRole(FACILITATOR_ROLE) whenNotPaused {
        scores[agent].scoreCommitment = commitment;
    }

    // ──────────────────────────────────────────────
    // Production Functions (new in v2)
    // ──────────────────────────────────────────────

    /// @notice Emergency pause — Guardian only, bypasses timelock, instant response.
    function emergencyPause() external onlyRole(GUARDIAN_ROLE) {
        _pause();
        emit ProtocolPaused(msg.sender);
    }

    /// @notice Unpause requires full admin (goes through timelock in production).
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
        emit ProtocolUnpaused(msg.sender);
    }

    /// @notice Score weight adjustment — only SCORE_ADMIN_ROLE (gated by timelock).
    /// @param newWeights [paymentWeight, volumeWeight, ageWeight, velocityWeight] in basis points.
    function updateScoreWeights(uint256[4] calldata newWeights) external onlyRole(SCORE_ADMIN_ROLE) {
        uint256 total = newWeights[0] + newWeights[1] + newWeights[2] + newWeights[3];
        require(total == 10000, "weights must sum to 10000 basis points");
        scoreWeights = newWeights;
        emit ScoreWeightsUpdated(newWeights);
    }

    /// @notice Returns the current contract version. Useful for verifying upgrades.
    function version() external pure returns (string memory) {
        return "2.0.0";
    }

    // ──────────────────────────────────────────────
    // Upgrade Authorization
    // ──────────────────────────────────────────────

    /// @dev Only DEFAULT_ADMIN_ROLE (= timelock in production) can authorize upgrades.
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    // ──────────────────────────────────────────────
    // Internal scoring logic
    // ──────────────────────────────────────────────

    /// @dev Recomputes the agent's credit score using the formula from AGENTS.md §4.1.
    ///      All arithmetic is integer-only. No floating point.
    function _recomputeScore(address agent) private {
        AgentScore storage s = scores[agent];

        // paymentScore = min(totalPayments, 1000) / 1000 * 270  →  0–270 points, caps at 1000 payments
        uint256 paymentScore = (_min(s.totalPayments, 1000) * 270) / 1000;

        // volumeScore = min(log2(totalVolumeMicro / 1e6), 10) / 10 * 180  →  0–180 points, log scale in USD
        // Use floor(log2(usdValue + 1)) to handle zero-volume edge case
        uint256 usdValue = s.totalVolumeMicro / 1e6;
        uint256 logValue = _floorLog2(usdValue + 1);
        uint256 volumeScore = (_min(logValue, 10) * 180) / 10;

        // ageScore = min(daysSinceFirst, 365) / 365 * 150  →  0–150 points, caps at 1 year
        uint256 daysSinceFirst = (block.timestamp - s.firstPaymentTime) / 86400;
        uint256 ageScore = (_min(daysSinceFirst, 365) * 150) / 365;

        // velocityScore = min(avgPaymentsPerDay30d, 50) / 50 * 70  →  0–70 points
        // Approximation: totalPayments / max(daysSinceFirst, 1) since we don't track a 30-day window
        uint256 avgPaymentsPerDay = s.totalPayments / _max(daysSinceFirst, 1);
        uint256 velocityScore = (_min(avgPaymentsPerDay, 50) * 70) / 50;

        // disputePenalty = disputeCount * 30  →  -30 points per dispute
        uint256 disputePenalty = s.disputeCount * 30;

        // computedScore = 300 + paymentScore + volumeScore + ageScore + velocityScore - disputePenalty
        // Clamp to [300, 900]
        uint256 bonus = paymentScore + volumeScore + ageScore + velocityScore;
        uint256 adjustedBonus = disputePenalty >= bonus ? 0 : bonus - disputePenalty;
        s.computedScore = _min(300 + adjustedBonus, 900);

        // Compute Poseidon commitment in separate function to avoid stack-too-deep
        s.scoreCommitment = _computeCommitment(s.computedScore, agent);
    }

    /// @dev Computes the Poseidon BN254 commitment: PoseidonT3.hash([score, agentAddress]).
    ///      Separated from _recomputeScore to avoid stack-too-deep with PoseidonT3's assembly.
    ///      This MUST match Noir's std::hash::poseidon::bn254::hash_2([score, agent_address]).
    function _computeCommitment(uint256 score, address agent) private pure returns (bytes32) {
        return bytes32(PoseidonT3.hash([score, uint256(uint160(agent))]));
    }

    /// @dev Floor of log2(x). Returns 0 for x <= 1.
    function _floorLog2(uint256 x) private pure returns (uint256) {
        uint256 result = 0;
        while (x > 1) {
            x >>= 1;
            result++;
        }
        return result;
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function _max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}
