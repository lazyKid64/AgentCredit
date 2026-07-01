// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {CreditLinePaymaster} from "../src/CreditLinePaymaster.sol";
import {IPaymaster} from "@account-abstraction/contracts/interfaces/IPaymaster.sol";
import {UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {ICreditRegistry} from "../src/interfaces/ICreditRegistry.sol";

// Mocks
contract MockRegistry {
    mapping(address => uint256) public scores;
    function setScore(address a, uint256 s) external { scores[a] = s; }
    function getScore(address a) external view returns (uint256) { return scores[a]; }
    // Stubs for the full ICreditRegistry interface
    function recordPayment(address, uint256, bytes32) external {}
    function getCommitment(address) external pure returns (bytes32) { return bytes32(0); }
    function setFacilitator(address, bool) external {}
    function setCommitment(address, bytes32) external {}
}

contract MockEntryPoint {
    mapping(address => uint256) public deposits;
    function depositTo(address paymaster) external payable { deposits[paymaster] += msg.value; }
    function withdrawTo(address payable dest, uint256 amt) external { dest.transfer(amt); }
    function balanceOf(address paymaster) external view returns (uint256) { return deposits[paymaster]; }
}

contract CreditLinePaymasterTest is Test {
    CreditLinePaymaster paymaster;
    MockRegistry        registry;
    MockEntryPoint      ep;
    address             agent = address(0xBEEF);

    function setUp() public {
        registry = new MockRegistry();
        ep       = new MockEntryPoint();
        paymaster = new CreditLinePaymaster(
            IEntryPoint(address(ep)),
            ICreditRegistry(address(registry)),
            address(this)
        );
        vm.deal(address(this), 1 ether);
        paymaster.deposit{value: 0.1 ether}();
    }

    function _makeOp(address sender) internal pure returns (UserOperation memory op) {
        op.sender = sender;
    }

    function test_highScoreAgentSponsored() public {
        registry.setScore(agent, 750);
        vm.prank(address(ep));
        (, uint256 vd) = paymaster.validatePaymasterUserOp(_makeOp(agent), bytes32(0), 1000);
        assertEq(vd, 0);
        assertEq(paymaster.outstandingDebt(agent), 1000);
    }

    function test_lowScoreRejected() public {
        registry.setScore(agent, 650);
        vm.prank(address(ep));
        vm.expectRevert(abi.encodeWithSelector(
            CreditLinePaymaster.ScoreBelowThreshold.selector, 650, 700
        ));
        paymaster.validatePaymasterUserOp(_makeOp(agent), bytes32(0), 1000);
    }

    function test_creditLineFormula() public pure {
        // score 700 → (700-300)*100 = 40000
        // score 900 → (900-300)*100 = 60000 but capped at MAX_DEBT_PER_AGENT=100000
        assertEq(uint256((700 - 300) * 100), uint256(40_000));
        assertEq(uint256((900 - 300) * 100), uint256(60_000));
    }

    function test_creditLimitExceededReverts() public {
        registry.setScore(agent, 700); // creditLine = 40000
        vm.startPrank(address(ep));
        paymaster.validatePaymasterUserOp(_makeOp(agent), bytes32(0), 30_000);
        vm.expectRevert(abi.encodeWithSelector(
            CreditLinePaymaster.CreditLimitExceeded.selector, 30_000, 15_000, 40_000
        ));
        paymaster.validatePaymasterUserOp(_makeOp(agent), bytes32(0), 15_000);
        vm.stopPrank();
    }

    function test_postOpRefundsUnusedGas() public {
        registry.setScore(agent, 750);
        vm.startPrank(address(ep));
        (bytes memory _ctx, uint256 _vd) = paymaster.validatePaymasterUserOp(_makeOp(agent), bytes32(0), 10_000);
        _ctx; _vd; // silence unused variable warnings
        paymaster.postOp(
            IPaymaster.PostOpMode.opSucceeded,
            abi.encode(agent, uint256(10_000)),
            7_000
        );
        vm.stopPrank();
        assertEq(paymaster.outstandingDebt(agent), 7_000);
    }

    function test_debtRepaymentRestoresCreditLine() public {
        registry.setScore(agent, 750);
        vm.prank(address(ep));
        paymaster.validatePaymasterUserOp(_makeOp(agent), bytes32(0), 10_000);
        assertEq(paymaster.outstandingDebt(agent), 10_000);
        vm.deal(address(this), 10_000);
        paymaster.repayDebt{value: 10_000}(agent);
        assertEq(paymaster.outstandingDebt(agent), 0);
    }

    function test_blacklistedAgentRejected() public {
        registry.setScore(agent, 800);
        paymaster.blacklistAgent(agent);
        vm.prank(address(ep));
        vm.expectRevert(abi.encodeWithSelector(
            CreditLinePaymaster.AgentIsBlacklisted.selector, agent
        ));
        paymaster.validatePaymasterUserOp(_makeOp(agent), bytes32(0), 1000);
    }

    function test_creditStatusView() public {
        registry.setScore(agent, 800);
        (uint256 score, uint256 cl, uint256 debt, uint256 avail, bool elig) =
            paymaster.creditStatus(agent);
        assertEq(score, 800);
        assertEq(cl,    50_000);
        assertEq(debt,  0);
        assertEq(avail, 50_000);
        assertTrue(elig);
    }
}
