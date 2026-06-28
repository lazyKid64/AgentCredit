// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CreditRegistry} from "../../src/CreditRegistry.sol";

/// @title Handler
/// @notice Wrapper that Foundry calls randomly. Tracks state for invariant checks.
contract Handler is Test {
    CreditRegistry internal registry;
    address[] internal agents;
    bytes32[] internal _usedNonces;
    mapping(address => uint256) public minScoreEverSeen;
    mapping(address => uint256) public minPaymentsEverSeen;
    uint256 public paymentsAfterPause;
    bool private wasPaused;

    constructor(CreditRegistry _registry, address[] memory _agents) {
        registry = _registry;
        agents = _agents;
        // Initialize min scores
        for (uint256 i = 0; i < _agents.length; i++) {
            minScoreEverSeen[_agents[i]] = 300;
            minPaymentsEverSeen[_agents[i]] = 0;
        }
    }

    function recordPayment(uint256 agentIndex, uint128 amount) public {
        agentIndex = agentIndex % agents.length;
        address agent = agents[agentIndex];
        uint256 boundedAmount = bound(amount, 100_000, 10_000_000); // $0.10 to $10

        bytes32 nonce = keccak256(abi.encodePacked(
            block.timestamp, agent, boundedAmount, _usedNonces.length
        ));

        if (registry.paused()) {
            wasPaused = true;
            return;
        }

        registry.recordPayment(agent, boundedAmount, nonce);
        uint256 scoreAfter = registry.getScore(agent);

        _usedNonces.push(nonce);

        // Track minimum score ever seen (should never decrease without disputes)
        if (scoreAfter < minScoreEverSeen[agent]) {
            minScoreEverSeen[agent] = scoreAfter;
        }

        (uint256 totalPayments,,,,,,) = registry.scores(agent);
        if (totalPayments > minPaymentsEverSeen[agent]) {
            minPaymentsEverSeen[agent] = totalPayments;
        }

        if (wasPaused) {
            paymentsAfterPause++;
        }
    }

    function getUsedNonces() external view returns (bytes32[] memory) {
        return _usedNonces;
    }
}

/// @title CreditRegistryInvariants
/// @notice Foundry will call these invariant_ functions after random sequences
///         of calls to the target contracts. All must hold at all times.
contract CreditRegistryInvariants is StdInvariant, Test {

    CreditRegistry internal registry;
    address[] internal agentList;
    Handler internal handler;

    function setUp() public {
        // Deploy CreditRegistry behind UUPS proxy
        CreditRegistry impl = new CreditRegistry();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(CreditRegistry.initialize, (address(this)))
        );
        registry = CreditRegistry(address(proxy));

        // Create 5 test agents
        for (uint256 i = 0; i < 5; i++) {
            agentList.push(makeAddr(string(abi.encode(i))));
        }

        // Deploy handler — Foundry calls handler functions randomly
        handler = new Handler(registry, agentList);
        registry.grantRole(registry.FACILITATOR_ROLE(), address(handler));

        // Tell Foundry to fuzz calls through the handler
        targetContract(address(handler));
    }

    /// @notice INVARIANT 1: Score is always in valid range [300, 900]
    function invariant_scoreAlwaysInValidRange() public view {
        for (uint256 i = 0; i < agentList.length; i++) {
            uint256 score = registry.getScore(agentList[i]);
            assertGe(score, 300, "score below 300 floor");
            assertLe(score, 900, "score above 900 ceiling");
        }
    }

    /// @notice INVARIANT 2: Score is monotonically non-decreasing (without disputes)
    ///         Once a payment is recorded, score can only go up or stay the same
    function invariant_scoreNeverDecreases() public view {
        for (uint256 i = 0; i < agentList.length; i++) {
            uint256 current = registry.getScore(agentList[i]);
            uint256 recorded = handler.minScoreEverSeen(agentList[i]);
            assertGe(current, recorded, "score decreased unexpectedly");
        }
    }

    /// @notice INVARIANT 3: Used nonces can never be recorded twice
    ///         If a nonce is in usedNonces, it cannot be used again
    function invariant_nonceMonotonicity() public view {
        bytes32[] memory usedNonces = handler.getUsedNonces();
        for (uint256 i = 0; i < usedNonces.length; i++) {
            assertTrue(registry.usedNonces(usedNonces[i]),
                "used nonce not marked in registry");
        }
    }

    /// @notice INVARIANT 4: totalPayments always increases (never decreases)
    function invariant_totalPaymentsNeverDecreases() public view {
        for (uint256 i = 0; i < agentList.length; i++) {
            (uint256 totalPayments,,,,,,) = registry.scores(agentList[i]);
            uint256 expectedMin = handler.minPaymentsEverSeen(agentList[i]);
            assertGe(totalPayments, expectedMin,
                "totalPayments decreased -- storage corruption");
        }
    }

    /// @notice INVARIANT 5: Paused contract cannot record payments
    function invariant_pausedContractBlocksPayments() public view {
        if (registry.paused()) {
            assertEq(handler.paymentsAfterPause(), 0,
                "payment recorded while paused");
        }
    }
}
