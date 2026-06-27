// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CreditRegistry} from "../src/CreditRegistry.sol";
import {AgentCreditTimelock} from "../src/governance/AgentCreditTimelock.sol";

contract DeployScript is Script {
    function run() external {
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        vm.startBroadcast();

        // 1. Deploy implementation
        CreditRegistry impl = new CreditRegistry();
        console.log("Implementation:", address(impl));

        // 2. Deploy UUPS proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(CreditRegistry.initialize, (deployer))
        );
        console.log("CreditRegistry Proxy:", address(proxy));

        // 3. Grant FACILITATOR_ROLE to deployer for testing
        CreditRegistry registry = CreditRegistry(address(proxy));
        registry.grantRole(registry.FACILITATOR_ROLE(), deployer);
        console.log("FACILITATOR_ROLE granted to deployer:", deployer);

        // 4. Deploy Timelock — deployer is initial proposer/executor
        // In production, replace deployer with Gnosis Safe address
        address[] memory proposers = new address[](1);
        proposers[0] = deployer;
        address[] memory executors = new address[](1);
        executors[0] = deployer;

        AgentCreditTimelock timelock = new AgentCreditTimelock(proposers, executors);
        console.log("AgentCreditTimelock:", address(timelock));

        // 5. Grant GUARDIAN_ROLE to deployer (in prod: hot 2-of-3 multisig)
        registry.grantRole(registry.GUARDIAN_ROLE(), deployer);

        // 6. Initialize score weights: 30/25/25/20 in basis points
        uint256[4] memory weights = [uint256(3000), 2500, 2500, 2000];
        registry.updateScoreWeights(weights);
        console.log("Score weights initialized");

        // 7. Transfer DEFAULT_ADMIN_ROLE to Timelock
        //    This means all future admin actions require 48h delay
        registry.grantRole(registry.DEFAULT_ADMIN_ROLE(), address(timelock));
        registry.revokeRole(registry.DEFAULT_ADMIN_ROLE(), deployer);
        console.log("DEFAULT_ADMIN_ROLE transferred to Timelock");
        console.log("Deployer admin rights revoked");

        vm.stopBroadcast();

        // Final summary
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("CREDIT_REGISTRY_ADDRESS=", address(proxy));
        console.log("TIMELOCK_ADDRESS=", address(timelock));
        console.log("VERSION=", registry.version());
    }
}
