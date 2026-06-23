// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/CreditRegistry.sol";

/// @title SeedAgentC — Seed Agent C test data
contract SeedAgentC is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address registryAddr = vm.envAddress("CREDIT_REGISTRY_ADDRESS");

        CreditRegistry registry = CreditRegistry(registryAddr);

        vm.startBroadcast(deployerPrivateKey);

        // Agent C: 800 payments, 1–5 USDC each (1_000_000 – 5_000_000 micro-units)
        address agentC = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;
        for (uint256 i = 0; i < 800; i++) {
            uint256 amount = 1_000_000 + (i * 5_000); // 1.00 – 5.00 USDC
            bytes32 nonce = keccak256(abi.encodePacked("agentC_v4", i));
            registry.recordPayment(agentC, amount, nonce);
        }
        console.log("Agent C seeded: 800 payments");

        vm.stopBroadcast();
    }
}
