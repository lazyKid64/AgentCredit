// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICreditRegistry {
    function recordPayment(address agent, uint256 amount, bytes32 nonce) external;
    function getScore(address agent) external view returns (uint256);
    function getCommitment(address agent) external view returns (bytes32);
    function setFacilitator(address facilitator, bool approved) external;
    function setCommitment(address agent, bytes32 commitment) external;
}
