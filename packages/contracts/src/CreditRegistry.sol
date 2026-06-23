// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ICreditRegistry.sol";

/// @title CreditRegistry
/// @notice Single source of truth for agent credit scores on Base Sepolia.
///         Tracks x402 payment history and computes a 300–900 credit score per agent wallet.
contract CreditRegistry is ICreditRegistry, Ownable, ReentrancyGuard {
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
    mapping(address => bool) public facilitators;

    event PaymentRecorded(address indexed agent, uint256 amount, bytes32 nonce);
    event ScoreUpdated(address indexed agent, uint256 newScore);

    modifier onlyFacilitator() {
        require(facilitators[msg.sender] == true, "not a facilitator");
        _;
    }

    constructor() Ownable(msg.sender) {}

    /// @notice Called ONLY by whitelisted facilitators after a confirmed x402 payment.
    /// @param agent  The agent wallet address that made the payment.
    /// @param amount The payment amount in USDC micro-units (6 decimals).
    /// @param nonce  The unique EIP-3009 nonce (random 32-byte value).
    function recordPayment(
        address agent,
        uint256 amount,
        bytes32 nonce
    ) external onlyFacilitator nonReentrant {
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
    function setFacilitator(address facilitator, bool approved) external onlyOwner {
        facilitators[facilitator] = approved;
    }

    /// @notice Facilitator-only — store a Noir-computed Pedersen commitment for ZK proofs.
    /// @dev The commitment is pedersen_hash([score, agent_address]) computed off-chain.
    function setCommitment(address agent, bytes32 commitment) external onlyFacilitator {
        scores[agent].scoreCommitment = commitment;
    }

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

        // scoreCommitment = keccak256(abi.encodePacked(computedScore, agent))
        // NOTE: In production this would be a Pedersen hash. For hackathon, keccak256 is acceptable.
        s.scoreCommitment = bytes32(
            uint256(keccak256(abi.encodePacked(s.computedScore, agent)))
        );
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
