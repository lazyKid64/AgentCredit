// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/CreditRegistry.sol";

contract CreditRegistryTest is Test {
    CreditRegistry public registry;
    address public facilitator = address(0x1);
    address public agent = address(0x2);

    function setUp() public {
        registry = new CreditRegistry();
        registry.setFacilitator(facilitator, true);
    }

    /// @notice recordPayment should increment totalPayments by 1
    function test_recordPayment_incrementsTotalPayments() public {
        vm.prank(facilitator);
        registry.recordPayment(agent, 1_000_000, bytes32(uint256(1)));

        (uint256 totalPayments,,,,,,) = registry.scores(agent);
        assertEq(totalPayments, 1, "totalPayments should be 1 after one payment");
    }

    /// @notice recordPayment should revert when the same nonce is used twice
    function test_recordPayment_rejectsReusedNonce() public {
        bytes32 nonce = bytes32(uint256(42));

        vm.prank(facilitator);
        registry.recordPayment(agent, 1_000_000, nonce);

        vm.prank(facilitator);
        vm.expectRevert("nonce already used");
        registry.recordPayment(agent, 1_000_000, nonce);
    }

    /// @notice recordPayment should revert when called by a non-facilitator
    function test_recordPayment_rejectsUnauthorizedCaller() public {
        address notFacilitator = address(0x99);

        vm.prank(notFacilitator);
        vm.expectRevert("not a facilitator");
        registry.recordPayment(agent, 1_000_000, bytes32(uint256(1)));
    }

    /// @notice getScore should return 300 (base score) for an agent with no payments
    function test_scoreIsZeroForNewAgent() public view {
        uint256 score = registry.getScore(address(0xDEAD));
        assertEq(score, 300, "new agent should have base score of 300");
    }

    /// @notice After 10 payments, score should be greater than the base 300
    function test_scoreIncreasesWithPayments() public {
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(facilitator);
            registry.recordPayment(agent, 1_000_000, bytes32(i));
        }

        uint256 score = registry.getScore(agent);
        assertGt(score, 300, "score should increase above 300 after 10 payments");
    }

    /// @notice Even with massive payment history, score must never exceed 900
    function test_scoreClampedTo900() public {
        // Phase 1: Record 1000 high-value payments in same block
        for (uint256 i = 0; i < 1000; i++) {
            vm.prank(facilitator);
            registry.recordPayment(agent, 10_000_000_000, bytes32(i)); // 10,000 USDC each
        }

        // Phase 2: Warp 400 days to max out ageScore
        vm.warp(block.timestamp + 400 days);

        // Phase 3: Record 1 more payment to trigger recompute with age factor
        vm.prank(facilitator);
        registry.recordPayment(agent, 10_000_000_000, bytes32(uint256(1000)));

        uint256 score = registry.getScore(agent);
        assertLe(score, 900, "score must be clamped to 900 maximum");
    }

    /// @notice setCommitment should allow facilitator to store a Pedersen commitment
    function test_setCommitment() public {
        bytes32 pedersenCommitment = bytes32(uint256(0xdeadbeef));

        // Facilitator can set commitment
        vm.prank(facilitator);
        registry.setCommitment(agent, pedersenCommitment);

        bytes32 stored = registry.getCommitment(agent);
        assertEq(stored, pedersenCommitment, "commitment should match the one set by facilitator");

        // Non-facilitator should be rejected
        address notFacilitator = address(0x99);
        vm.prank(notFacilitator);
        vm.expectRevert("not a facilitator");
        registry.setCommitment(agent, bytes32(uint256(0x1234)));
    }
}
