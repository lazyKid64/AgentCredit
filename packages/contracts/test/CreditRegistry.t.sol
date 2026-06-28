// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CreditRegistry} from "../src/CreditRegistry.sol";
import {CreditRegistryV2} from "../src/CreditRegistryV2.sol";
import {PoseidonT3} from "poseidon-solidity/PoseidonT3.sol";

contract CreditRegistryTest is Test {
    CreditRegistry public registry;
    address public deployer;
    address public facilitator;
    address public guardian;
    address public agent;

    function setUp() public {
        deployer = makeAddr("deployer");
        facilitator = makeAddr("facilitator");
        guardian = makeAddr("guardian");
        agent = makeAddr("agent");

        vm.startPrank(deployer);

        // Deploy implementation
        CreditRegistry impl = new CreditRegistry();

        // Deploy proxy pointing to implementation
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(CreditRegistry.initialize, (deployer))
        );
        registry = CreditRegistry(address(proxy));

        // Grant roles
        registry.grantRole(registry.FACILITATOR_ROLE(), facilitator);
        registry.grantRole(registry.GUARDIAN_ROLE(), guardian);
        vm.stopPrank();
    }

    // ──────────────────────────────────────────────
    // Original 6 tests (adapted for proxy pattern)
    // ──────────────────────────────────────────────

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
        vm.expectRevert();
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
        vm.expectRevert();
        registry.setCommitment(agent, bytes32(uint256(0x1234)));
    }

    // ──────────────────────────────────────────────
    // New production tests (8 additional)
    // ──────────────────────────────────────────────

    /// @notice version() should return "2.0.0"
    function test_version_returns_2_0_0() public view {
        assertEq(registry.version(), "2.0.0");
    }

    /// @notice Guardian should be able to pause the protocol
    function test_guardian_can_pause() public {
        vm.prank(guardian);
        registry.emergencyPause();
        assertTrue(registry.paused());
    }

    /// @notice recordPayment should revert when the protocol is paused
    function test_recordPayment_reverts_when_paused() public {
        vm.prank(guardian);
        registry.emergencyPause();

        vm.prank(facilitator);
        vm.expectRevert();
        registry.recordPayment(agent, 1_000_000, bytes32(uint256(1)));
    }

    /// @notice Non-guardian address should not be able to pause
    function test_non_guardian_cannot_pause() public {
        address randomUser = makeAddr("randomUser");
        vm.prank(randomUser);
        vm.expectRevert();
        registry.emergencyPause();
    }

    /// @notice SCORE_ADMIN_ROLE can update score weights when they sum to 10000
    function test_score_weights_update() public {
        uint256[4] memory weights = [uint256(2500), 2500, 2500, 2500];

        vm.prank(deployer);
        registry.updateScoreWeights(weights);

        assertEq(registry.scoreWeights(0), 2500);
        assertEq(registry.scoreWeights(1), 2500);
        assertEq(registry.scoreWeights(2), 2500);
        assertEq(registry.scoreWeights(3), 2500);
    }

    /// @notice Score weights must sum to exactly 10000 basis points
    function test_score_weights_must_sum_to_10000() public {
        uint256[4] memory badWeights = [uint256(2000), 2000, 2000, 3000];

        vm.prank(deployer);
        vm.expectRevert("weights must sum to 10000 basis points");
        registry.updateScoreWeights(badWeights);
    }

    /// @notice UUPS upgrade to CreditRegistryV2 should succeed for admin
    function test_upgrade_safety() public {
        // Deploy new implementation
        vm.startPrank(deployer);
        CreditRegistryV2 implV2 = new CreditRegistryV2();

        // Upgrade via UUPS — admin calls upgradeToAndCall
        registry.upgradeToAndCall(address(implV2), "");
        vm.stopPrank();

        // Verify the upgrade succeeded by checking the new version
        assertEq(registry.version(), "3.0.0");
    }

    /// @notice Non-admin should not be able to upgrade the proxy
    function test_unauthorized_upgrade_fails() public {
        CreditRegistryV2 implV2 = new CreditRegistryV2();

        address randomUser = makeAddr("randomUser");
        vm.prank(randomUser);
        vm.expectRevert();
        registry.upgradeToAndCall(address(implV2), "");
    }

    /// @notice Commitment must use Poseidon hash, NOT keccak256
    function test_commitment_uses_poseidon() public {
        // Record a payment to trigger score computation
        vm.prank(facilitator);
        registry.recordPayment(agent, 1_000_000, bytes32(uint256(1)));

        // Get the on-chain commitment
        bytes32 commitment = registry.getCommitment(agent);

        // Get the score
        uint256 score = registry.getScore(agent);

        // Compute expected Poseidon commitment
        bytes32 expectedCommitment = bytes32(
            PoseidonT3.hash([score, uint256(uint160(agent))])
        );

        // They must match — proving Poseidon is used, not keccak256
        assertEq(commitment, expectedCommitment, "commitment must use PoseidonT3 hash");

        // Also verify it's NOT keccak256
        bytes32 keccakCommitment = bytes32(
            uint256(keccak256(abi.encodePacked(score, agent)))
        );
        assertNotEq(commitment, keccakCommitment, "commitment must NOT be keccak256");
    }
}
