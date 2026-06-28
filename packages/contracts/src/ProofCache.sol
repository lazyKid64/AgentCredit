// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControlUpgradeable} from
    "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from
    "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from
    "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IZKVerifier {
    function verify(bytes calldata proof, bytes32[] calldata publicInputs)
        external view returns (bool);
}

/// @title ProofCache
/// @notice Agents submit a ZK proof once. The cache stores a receipt valid
///         for PROOF_VALIDITY_BLOCKS (~12 hours on Base). Subsequent API
///         calls check the cache instead of re-verifying on-chain.
contract ProofCache is Initializable, AccessControlUpgradeable, UUPSUpgradeable {

    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    uint256 public constant PROOF_VALIDITY_BLOCKS = 3600; // ~12h on Base

    struct ProofReceipt {
        bytes32 nullifier;        // keccak256(proof) — prevents same proof reuse
        uint256 validUntilBlock;  // receipt expires after this block
        uint8   tier;             // 0=unknown 1=silver 2=gold
        bool    exists;
    }

    // agent address => ProofReceipt
    mapping(address => ProofReceipt) public receipts;

    // Nullifier registry — each unique proof can only be submitted once
    mapping(bytes32 => bool) public usedNullifiers;

    IZKVerifier public verifier;

    event ProofSubmitted(address indexed agent, uint8 tier, uint256 validUntilBlock);
    event ReceiptExpired(address indexed agent);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(address admin, address _verifier) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        verifier = IZKVerifier(_verifier);
    }

    /// @notice Agent submits their ZK proof. Verified on-chain.
    ///         Receipt stored for PROOF_VALIDITY_BLOCKS.
    /// @param proof The Noir-generated proof bytes
    /// @param publicInputs [threshold, agentAddress, commitment, blockNumber]
    function submitProof(
        bytes calldata proof,
        bytes32[] calldata publicInputs
    ) external {
        require(publicInputs.length == 4, "ProofCache: expected 4 public inputs");

        bytes32 nullifier = keccak256(proof);
        require(!usedNullifiers[nullifier], "ProofCache: proof already used");

        // Extract block_number from public inputs[3] — proof must be recent
        uint256 proofBlockNumber = uint256(publicInputs[3]);
        require(
            block.number - proofBlockNumber <= 100,
            "ProofCache: proof is stale (>100 blocks old)"
        );

        // Verify ZK proof on-chain
        require(verifier.verify(proof, publicInputs), "ProofCache: invalid proof");

        // Extract threshold from publicInputs[0] to determine tier
        uint256 threshold = uint256(publicInputs[0]);
        uint8 tier;
        if (threshold >= 750) tier = 2;       // Gold
        else if (threshold >= 600) tier = 1;  // Silver
        else tier = 0;                         // Unknown

        // Mark nullifier as used
        usedNullifiers[nullifier] = true;

        // Store receipt valid for 12 hours
        receipts[msg.sender] = ProofReceipt({
            nullifier: nullifier,
            validUntilBlock: block.number + PROOF_VALIDITY_BLOCKS,
            tier: tier,
            exists: true
        });

        emit ProofSubmitted(msg.sender, tier, block.number + PROOF_VALIDITY_BLOCKS);
    }

    /// @notice Check if an agent has a valid cached proof receipt
    /// @return valid Whether the receipt is valid and non-expired
    /// @return tier 0=unknown 1=silver 2=gold
    function checkReceipt(address agent)
        external view returns (bool valid, uint8 tier)
    {
        ProofReceipt memory receipt = receipts[agent];
        if (!receipt.exists) return (false, 0);
        if (block.number > receipt.validUntilBlock) return (false, 0);
        return (true, receipt.tier);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    uint256[47] private __gap;
}
