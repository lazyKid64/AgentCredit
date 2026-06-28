// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ProofCache, IZKVerifier} from "../src/ProofCache.sol";

/// @dev Mock verifier that returns a configurable result
contract MockVerifier is IZKVerifier {
    bool public result;

    constructor(bool _result) {
        result = _result;
    }

    function setResult(bool _result) external {
        result = _result;
    }

    function verify(bytes calldata, bytes32[] calldata) external view returns (bool) {
        return result;
    }
}

contract ProofCacheTest is Test {
    ProofCache public cache;
    MockVerifier public mockVerifier;
    address public admin;
    address public agent;

    function setUp() public {
        admin = makeAddr("admin");
        agent = makeAddr("agent");

        // Deploy mock verifier that returns true by default
        mockVerifier = new MockVerifier(true);

        // Deploy ProofCache behind proxy
        vm.startPrank(admin);
        ProofCache impl = new ProofCache();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(ProofCache.initialize, (admin, address(mockVerifier)))
        );
        cache = ProofCache(address(proxy));
        vm.stopPrank();
    }

    function _makePublicInputs(uint256 threshold, uint256 blockNum) internal view returns (bytes32[] memory) {
        bytes32[] memory inputs = new bytes32[](4);
        inputs[0] = bytes32(threshold);      // threshold
        inputs[1] = bytes32(uint256(uint160(agent)));  // agentAddress
        inputs[2] = bytes32(uint256(0xdeadbeef));      // commitment
        inputs[3] = bytes32(blockNum);       // blockNumber
        return inputs;
    }

    /// @notice submitProof stores a receipt when verifier returns true
    function test_submitProof_storesReceipt() public {
        bytes memory proof = hex"aabbccdd";
        bytes32[] memory inputs = _makePublicInputs(600, block.number);

        vm.prank(agent);
        cache.submitProof(proof, inputs);

        (bool valid, uint8 tier) = cache.checkReceipt(agent);
        assertTrue(valid, "receipt should be valid");
        assertEq(tier, 1, "tier should be 1 (silver) for threshold 600");
    }

    /// @notice checkReceipt returns correct tier for gold threshold
    function test_checkReceipt_returnsCorrectTier() public {
        bytes memory proof = hex"aabbccdd";
        bytes32[] memory inputs = _makePublicInputs(750, block.number);

        vm.prank(agent);
        cache.submitProof(proof, inputs);

        (bool valid, uint8 tier) = cache.checkReceipt(agent);
        assertTrue(valid);
        assertEq(tier, 2, "tier should be 2 (gold) for threshold >= 750");
    }

    /// @notice Same proof bytes cannot be submitted twice
    function test_nullifierCannotBeReused() public {
        bytes memory proof = hex"aabbccdd";
        bytes32[] memory inputs = _makePublicInputs(600, block.number);

        vm.prank(agent);
        cache.submitProof(proof, inputs);

        vm.prank(agent);
        vm.expectRevert("ProofCache: proof already used");
        cache.submitProof(proof, inputs);
    }

    /// @notice Proof with block number too far in the past is rejected
    function test_staleProofRejected() public {
        // Foundry starts at block 1 — roll forward so subtraction doesn't underflow
        vm.roll(1000);

        bytes memory proof = hex"aabbccdd";
        // Set proof block number 200 blocks behind current
        bytes32[] memory inputs = _makePublicInputs(600, block.number - 200);

        vm.prank(agent);
        vm.expectRevert("ProofCache: proof is stale (>100 blocks old)");
        cache.submitProof(proof, inputs);
    }

    /// @notice Expired receipt returns false
    function test_expiredReceiptReturnsFalse() public {
        bytes memory proof = hex"aabbccdd";
        bytes32[] memory inputs = _makePublicInputs(600, block.number);

        vm.prank(agent);
        cache.submitProof(proof, inputs);

        // Warp forward 3601 blocks to expire the receipt
        vm.roll(block.number + 3601);

        (bool valid, uint8 tier) = cache.checkReceipt(agent);
        assertFalse(valid, "expired receipt should be invalid");
        assertEq(tier, 0, "tier should be 0 for expired receipt");
    }

    /// @notice Invalid proof (verifier returns false) reverts
    function test_invalidProofReverts() public {
        mockVerifier.setResult(false);

        bytes memory proof = hex"aabbccdd";
        bytes32[] memory inputs = _makePublicInputs(600, block.number);

        vm.prank(agent);
        vm.expectRevert("ProofCache: invalid proof");
        cache.submitProof(proof, inputs);
    }
}
