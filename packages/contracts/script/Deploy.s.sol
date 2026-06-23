// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/CreditRegistry.sol";

/// @title Deploy CreditRegistry to Base Sepolia
/// @notice Deploys the contract and whitelists the deployer as a facilitator
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        CreditRegistry registry = new CreditRegistry();
        registry.setFacilitator(deployer, true);

        vm.stopBroadcast();

        console.log("CreditRegistry deployed at:", address(registry));
        console.log("Facilitator set to deployer:", deployer);
    }
}
