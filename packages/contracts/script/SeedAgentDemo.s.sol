// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/CreditRegistry.sol";

contract SeedAgentDemo is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address registryAddr = vm.envAddress("CREDIT_REGISTRY_ADDRESS");
        uint256 agentPrivateKey = vm.envUint("AGENT_PRIVATE_KEY");
        address agent = vm.addr(agentPrivateKey);

        CreditRegistry registry = CreditRegistry(registryAddr);

        vm.startBroadcast(deployerPrivateKey);

        // Seed 300 payments of 2 USDC each
        for (uint256 i = 0; i < 300; i++) {
            uint256 amount = 2_000_000; // 2.00 USDC
            bytes32 nonce = keccak256(abi.encodePacked("demo_agent_v1", i));
            registry.recordPayment(agent, amount, nonce);
        }
        
        vm.stopBroadcast();
    }
}
