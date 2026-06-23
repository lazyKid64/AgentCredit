// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/CreditRegistry.sol";

/// @title SeedData — Batch-seed test agent payment data
/// @notice Seeds 3 test agents with varying payment histories in a single broadcast
contract SeedData is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address registryAddr = vm.envAddress("CREDIT_REGISTRY_ADDRESS");

        CreditRegistry registry = CreditRegistry(registryAddr);

        vm.startBroadcast(deployerPrivateKey);

        // Agent A: 50 payments, 1–2 USDC each (1_000_000 – 2_000_000 micro-units)
        address agentA = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
        for (uint256 i = 0; i < 50; i++) {
            uint256 amount = 1_000_000 + (i * 20_000); // 1.00 – 1.98 USDC
            bytes32 nonce = keccak256(abi.encodePacked("agentA", i));
            registry.recordPayment(agentA, amount, nonce);
        }
        console.log("Agent A seeded: 50 payments");

        // Agent B: 200 payments, 0.50–1.00 USDC each (500_000 – 1_000_000 micro-units)
        address agentB = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
        for (uint256 i = 0; i < 200; i++) {
            uint256 amount = 500_000 + (i * 2_500); // 0.50 – 1.00 USDC
            bytes32 nonce = keccak256(abi.encodePacked("agentB", i));
            registry.recordPayment(agentB, amount, nonce);
        }
        console.log("Agent B seeded: 200 payments");

        // Agent C: 800 payments, 1–5 USDC each (1_000_000 – 5_000_000 micro-units)
        address agentC = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;
        for (uint256 i = 0; i < 800; i++) {
            uint256 amount = 1_000_000 + (i * 5_000); // 1.00 – 5.00 USDC
            bytes32 nonce = keccak256(abi.encodePacked("agentC", i));
            registry.recordPayment(agentC, amount, nonce);
        }
        console.log("Agent C seeded: 800 payments");

        vm.stopBroadcast();

        console.log("All agents seeded successfully");
    }
}
