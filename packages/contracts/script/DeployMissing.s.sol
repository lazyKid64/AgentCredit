// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {CreditLinePaymaster} from "../src/CreditLinePaymaster.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {ICreditRegistry} from "../src/interfaces/ICreditRegistry.sol";

contract DeployMissing is Script {
    // ERC-4337 EntryPoint v0.6 — canonical address, same on all EVM chains
    address constant ENTRY_POINT = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    function run() external {
        address deployer      = vm.envAddress("DEPLOYER_ADDRESS");
        address registryProxy = vm.envAddress("CREDIT_REGISTRY_ADDRESS");

        vm.startBroadcast();

        // Deploy ZKVerifier using bytecode (Noir-generated contracts deploy this way)
        bytes memory zkCode = vm.getCode("ZKVerifier.sol:UltraVerifier");
        address zkVerifier;
        assembly { zkVerifier := create(0, add(zkCode, 0x20), mload(zkCode)) }
        require(zkVerifier != address(0), "ZKVerifier deploy failed");
        console.log("ZKVerifier:", zkVerifier);

        // Deploy CreditLinePaymaster
        CreditLinePaymaster paymaster = new CreditLinePaymaster(
            IEntryPoint(ENTRY_POINT),
            ICreditRegistry(registryProxy),
            deployer
        );
        console.log("CreditLinePaymaster:", address(paymaster));

        // Fund paymaster with 0.001 ETH so it can sponsor gas immediately
        paymaster.deposit{value: 0.001 ether}();
        console.log("Paymaster funded. Deposit:", paymaster.getDeposit());

        vm.stopBroadcast();

        console.log("\n=== ADD TO .env ===");
        console.log("ZK_VERIFIER_ADDRESS=", zkVerifier);
        console.log("CREDIT_LINE_PAYMASTER_ADDRESS=", address(paymaster));
    }
}
