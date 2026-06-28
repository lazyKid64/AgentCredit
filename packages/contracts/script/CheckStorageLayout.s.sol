// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

/// @notice Run this script before every upgrade to verify storage compatibility
/// Usage: forge script script/CheckStorageLayout.s.sol -vvv
contract CheckStorageLayout is Script {
    function run() external view {
        console.log("Storage layout validation:");
        console.log("Run: forge inspect CreditRegistry storage-layout");
        console.log("Then diff against the saved layout from the previous version.");
        console.log("CRITICAL: No storage variables may be removed or reordered.");
        console.log("New variables may only be added BEFORE the __gap array.");
    }
}
