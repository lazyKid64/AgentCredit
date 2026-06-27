// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TimelockController} from
    "@openzeppelin/contracts/governance/TimelockController.sol";

/// @title AgentCreditTimelock
/// @notice 48-hour timelock governing all sensitive CreditRegistry operations.
/// Proposers: Gnosis Safe multisig (set at deploy time)
/// Executors: Gnosis Safe multisig (same address)
/// Admin: address(0) after setup — timelock is self-administered
contract AgentCreditTimelock is TimelockController {
    uint256 public constant MIN_DELAY = 172800; // 48 hours

    constructor(
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(MIN_DELAY, proposers, executors, address(0)) {}
}
