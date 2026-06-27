// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ICreditRegistry.sol";

/// @title CreditRegistryV2
/// @notice Stub upgrade contract for testing UUPS upgradeability.
///         In production, this would contain new features or bugfixes.
contract CreditRegistryV2 is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard,
    UUPSUpgradeable,
    ICreditRegistry
{
    bytes32 public constant FACILITATOR_ROLE = keccak256("FACILITATOR_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant SCORE_ADMIN_ROLE = keccak256("SCORE_ADMIN_ROLE");

    struct AgentScore {
        uint256 totalPayments;
        uint256 totalVolumeMicro;
        uint256 firstPaymentTime;
        uint256 lastPaymentTime;
        uint256 disputeCount;
        uint256 computedScore;
        bytes32 scoreCommitment;
    }

    mapping(address => AgentScore) public scores;
    mapping(bytes32 => bool) public usedNonces;
    uint256[4] public scoreWeights;
    uint256[45] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialAdmin) public initializer {
        __AccessControl_init();
        __Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(SCORE_ADMIN_ROLE, initialAdmin);
    }

    function recordPayment(address agent, uint256 amount, bytes32 nonce) external onlyRole(FACILITATOR_ROLE) nonReentrant whenNotPaused {
        require(!usedNonces[nonce], "nonce already used");
        usedNonces[nonce] = true;
        AgentScore storage s = scores[agent];
        s.totalPayments += 1;
        s.totalVolumeMicro += amount;
        if (s.firstPaymentTime == 0) { s.firstPaymentTime = block.timestamp; }
        s.lastPaymentTime = block.timestamp;
        s.computedScore = 300;
        s.scoreCommitment = bytes32(uint256(keccak256(abi.encodePacked(s.computedScore, agent))));
    }

    function getScore(address agent) external view returns (uint256) {
        if (scores[agent].totalPayments == 0) { return 300; }
        return scores[agent].computedScore;
    }

    function getCommitment(address agent) external view returns (bytes32) {
        return scores[agent].scoreCommitment;
    }

    function setFacilitator(address facilitator, bool approved) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (approved) { _grantRole(FACILITATOR_ROLE, facilitator); }
        else { _revokeRole(FACILITATOR_ROLE, facilitator); }
    }

    function setCommitment(address agent, bytes32 commitment) external onlyRole(FACILITATOR_ROLE) whenNotPaused {
        scores[agent].scoreCommitment = commitment;
    }

    function emergencyPause() external onlyRole(GUARDIAN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }

    function updateScoreWeights(uint256[4] calldata newWeights) external onlyRole(SCORE_ADMIN_ROLE) {
        uint256 total = newWeights[0] + newWeights[1] + newWeights[2] + newWeights[3];
        require(total == 10000, "weights must sum to 10000 basis points");
        scoreWeights = newWeights;
    }

    /// @notice Returns "3.0.0" to prove the upgrade was successful.
    function version() external pure returns (string memory) {
        return "3.0.0";
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
