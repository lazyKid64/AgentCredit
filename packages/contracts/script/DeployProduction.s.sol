// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CreditRegistry} from "../src/CreditRegistry.sol";
import {ProofCache} from "../src/ProofCache.sol";
import {AgentCreditTimelock} from "../src/governance/AgentCreditTimelock.sol";

/// @title DeployProduction
/// @notice Full production deployment with:
///   - UUPS proxy for CreditRegistry
///   - ProofCache proxy
///   - TimelockController (48h delay)
///   - Role assignment: Timelock -> admin, Gnosis Safe -> guardian
///   - Deployer rights revoked after setup
///
/// @dev Before running:
///   1. Set GNOSIS_SAFE_ADDRESS in .env to your 3-of-5 Safe address
///   2. Set GUARDIAN_ADDRESS in .env to your 2-of-3 hot Safe address
///   3. Ensure PRIVATE_KEY has enough ETH for deployment gas
///   4. Run on fork first: forge script ... --fork-url $RPC_URL (no --broadcast)
contract DeployProduction is Script {

    struct DeploymentResult {
        address registryProxy;
        address registryImpl;
        address proofCacheProxy;
        address proofCacheImpl;
        address timelock;
    }

    function _printSummary(DeploymentResult memory r) internal pure {
        console.log("\n=== COPY TO .env ===");
        console.log("CREDIT_REGISTRY_ADDRESS=", r.registryProxy);
        console.log("CREDIT_REGISTRY_IMPL_ADDRESS=", r.registryImpl);
        console.log("PROOF_CACHE_ADDRESS=", r.proofCacheProxy);
        console.log("TIMELOCK_ADDRESS=", r.timelock);
        console.log("===================");

        console.log("\n=== VERIFY ON BASESCAN ===");
        console.log("Registry impl:", r.registryImpl);
        console.log("ProofCache impl:", r.proofCacheImpl);
        console.log("Run: forge verify-contract <ADDR> src/CreditRegistry.sol:CreditRegistry --chain-id 8453");
        console.log("Run: forge verify-contract <ADDR> src/ProofCache.sol:ProofCache --chain-id 8453");
    }

    function run() external returns (DeploymentResult memory result) {
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        address gnosisSafe = vm.envAddress("GNOSIS_SAFE_ADDRESS");
        address guardian = vm.envAddress("GUARDIAN_ADDRESS");
        address zkVerifier = vm.envAddress("ZK_VERIFIER_ADDRESS");

        // Pre-flight validation
        require(gnosisSafe != address(0), "GNOSIS_SAFE_ADDRESS not set");
        require(guardian != address(0), "GUARDIAN_ADDRESS not set");
        require(zkVerifier != address(0), "ZK_VERIFIER_ADDRESS not set");
        require(gnosisSafe != deployer, "Safe must be different from deployer");

        console.log("=== PRE-FLIGHT CHECKS PASSED ===");
        console.log("Deployer:", deployer);
        console.log("Gnosis Safe (will become admin):", gnosisSafe);
        console.log("Guardian (hot safe for pause):", guardian);

        vm.startBroadcast();

        // ---- Step 1: Deploy TimelockController ----
        result.timelock = address(
            new AgentCreditTimelock(_toArray(gnosisSafe), _toArray(gnosisSafe))
        );
        console.log("1. TimelockController deployed:", result.timelock);

        // ---- Step 2: Deploy CreditRegistry UUPS proxy ----
        CreditRegistry registryImpl = new CreditRegistry();
        result.registryImpl = address(registryImpl);
        result.registryProxy = address(new ERC1967Proxy(
            result.registryImpl,
            abi.encodeCall(CreditRegistry.initialize, (deployer))
        ));
        console.log("2. CreditRegistry Proxy:", result.registryProxy);

        CreditRegistry registry = CreditRegistry(result.registryProxy);

        // ---- Step 3: Deploy ProofCache UUPS proxy ----
        ProofCache pcImpl = new ProofCache();
        result.proofCacheImpl = address(pcImpl);
        result.proofCacheProxy = address(new ERC1967Proxy(
            result.proofCacheImpl,
            abi.encodeCall(ProofCache.initialize, (deployer, zkVerifier))
        ));
        console.log("3. ProofCache Proxy:", result.proofCacheProxy);

        // ---- Step 4: Configure roles ----
        registry.grantRole(registry.GUARDIAN_ROLE(), guardian);
        console.log("4. GUARDIAN_ROLE -> Guardian Hot Safe");

        // ---- Step 5: Initialize score weights ----
        registry.grantRole(registry.SCORE_ADMIN_ROLE(), deployer);
        registry.updateScoreWeights([uint256(3000), 2500, 2500, 2000]);
        registry.revokeRole(registry.SCORE_ADMIN_ROLE(), deployer);
        console.log("5. Score weights initialized (30/25/25/20)");

        // ---- Step 6: Transfer admin to Timelock (POINT OF NO RETURN) ----
        registry.grantRole(registry.DEFAULT_ADMIN_ROLE(), result.timelock);
        registry.grantRole(registry.SCORE_ADMIN_ROLE(), result.timelock);
        registry.revokeRole(registry.DEFAULT_ADMIN_ROLE(), deployer);
        console.log("6. DEFAULT_ADMIN_ROLE -> Timelock (deployer revoked)");

        vm.stopBroadcast();

        _printSummary(result);
        return result;
    }

    function _toArray(address a) internal pure returns (address[] memory arr) {
        arr = new address[](1);
        arr[0] = a;
    }
}
