import os

content = """<div align="center">

# AgentCredit Protocol
## Technical Whitepaper

**Version 1.0 — Base Sepolia Testnet**

*The On-Chain Credit Bureau for the Machine Economy*

</div>

---

**Abstract**

The x402 payment protocol has enabled autonomous agent micropayments but provides no built-in trust signal — treating every agent identically regardless of its payment history. AgentCredit solves this by introducing a three-primitive protocol (CreditRegistry, ZK Proof System, x402 Credit Gate) that computes on-chain credit scores from x402 payment history and enables privacy-preserving score proofs via Noir ZK circuits. Agents generate a Noir UltraPlonk proof cryptographically asserting their score exceeds a threshold, send it as an HTTP header (`X-CREDIT-PROOF`), and receive tiered pricing automatically — such as Gold (≥750, 50% discount) or Silver (≥600, 20% discount). Deployed on the Base Sepolia testnet, the system currently consists of four live contracts with 27 passing tests and 5 invariant properties verified across 250,000 fuzz calls. This protocol represents the first production implementation of zero-knowledge gated HTTP micropayment pricing using the x402 standard, unlocking sophisticated credit markets and deferred payment primitives for the machine-to-machine economy.

**Table of Contents**

* [1. Introduction](#1-introduction)
* [2. Background](#2-background)
  * [2.1 The x402 Payment Protocol](#21-the-x402-payment-protocol)
  * [2.2 The Machine-to-Machine Economy](#22-the-machine-to-machine-economy)
  * [2.3 Prior Work: Credit in Decentralized Systems](#23-prior-work-credit-in-decentralized-systems)
* [3. Problem Statement](#3-problem-statement)
  * [3.1 The Trust Gap](#31-the-trust-gap)
  * [3.2 Failure Modes of Naive Approaches](#32-failure-modes-of-naive-approaches)
* [4. Protocol Design](#4-protocol-design)
  * [4.1 System Overview](#41-system-overview)
  * [4.2 The CreditRegistry](#42-the-creditregistry)
  * [4.3 Credit Score Formula](#43-credit-score-formula)
  * [4.4 The ZK Proof System](#44-the-zk-proof-system)
  * [4.5 The x402 Credit Gate](#45-the-x402-credit-gate)
  * [4.6 The CreditLine Paymaster](#46-the-creditline-paymaster)
  * [4.7 The ProofCache](#47-the-proofcache)
* [5. Security Analysis](#5-security-analysis)
  * [5.1 Threat Model](#51-threat-model)
  * [5.2 Vulnerability Matrix](#52-vulnerability-matrix)
  * [5.3 Cryptographic Security](#53-cryptographic-security)
* [6. Economic Model](#6-economic-model)
  * [6.1 Incentive Structure](#61-incentive-structure)
  * [6.2 Credit Tier Pricing](#62-credit-tier-pricing)
  * [6.3 Credit Line Economics](#63-credit-line-economics)
* [7. Implementation](#7-implementation)
  * [7.1 Smart Contract Architecture](#71-smart-contract-architecture)
  * [7.2 Off-Chain Infrastructure](#72-off-chain-infrastructure)
  * [7.3 Deployed Contracts](#73-deployed-contracts)
* [8. Evaluation](#8-evaluation)
  * [8.1 Test Coverage](#81-test-coverage)
  * [8.2 Invariant Properties](#82-invariant-properties)
  * [8.3 Gas Analysis](#83-gas-analysis)
* [9. Roadmap and Future Work](#9-roadmap-and-future-work)
* [References](#references)

---

## 1. Introduction

The x402 protocol, co-developed by Coinbase and Cloudflare, introduced HTTP-native micropayments by reviving the dormant 402 Payment Required status code. It enables a novel flow: an AI agent can hit an HTTP endpoint, receive a 402 with payment terms, sign an EIP-3009 TransferWithAuthorization for the specified USDC amount, and retry with the signed payload in the `X-PAYMENT` header. The server's facilitator submits the authorization on-chain, and the 200 response is returned. As of mid-2026, x402 has processed over 165 million payments, serving as the foundational payment rail for autonomous machine agents.

Despite this robust payment infrastructure, x402 provides no mechanism for service providers to differentiate between agents based on their transaction history. An agent that has completed 50,000 payments worth $10,000 USDC over 18 months receives the exact same price as a newly instantiated agent making its first request. Economically, this forces service providers to price defensively for the worst-case counterparty, causing high-quality, reliable agents to systematically over-pay. Simultaneously, agents have no mechanism to build or demonstrate a payment reputation without revealing their entire on-chain transaction history.

AgentCredit addresses this gap through three composable primitives deployed on the Base network. First, a `CreditRegistry` contract indexes x402 payment events into a deterministic, aggregated credit score (300–900) tied to the agent's address. Second, a Noir zero-knowledge circuit allows the agent to prove its score exceeds a specific threshold without revealing its actual score or any individual transaction metadata — the proof is transmitted as an `X-CREDIT-PROOF` HTTP header. Third, an x402 middleware layer reads this proof, verifies it cryptographically on-chain via the `UltraVerifier` contract, and automatically applies tiered pricing within the request lifecycle.

This paper details the technical architecture of AgentCredit. Section 2 provides background on x402 and prior work in decentralized reputation. Section 3 formalizes the problem statement and the failures of naive approaches. Section 4 breaks down the protocol design, including the score formula and ZK system. Sections 5 and 6 analyze the security and economic models. Finally, Sections 7 and 8 evaluate the implementation and its invariant properties on the Base Sepolia testnet.

---

## 2. Background

### 2.1 The x402 Payment Protocol

The x402 protocol establishes a standardized mechanism for API monetization through the HTTP 402 Payment Required status code. In a typical flow, a client requests a resource and the server responds with a 402 status, attaching an `X-PAYMENT-REQUIREMENTS` header specifying the token address, acceptable chains, and the required payment amount. The client then generates the required payment authorization and retries the request, embedding the authorization in the `X-PAYMENT` header. If valid, the server returns the requested resource with a 200 OK status.

Payment authorizations in x402 leverage EIP-3009 `TransferWithAuthorization`, which permits off-chain pre-authorization of token transfers without requiring the payer to hold native gas tokens. The payload includes standard fields: `from`, `to`, `value`, `validAfter`, `validBefore`, a `nonce`, and the ECDSA signature components (`v`, `r`, `s`). Crucially, the `nonce` in EIP-3009 is a random `bytes32` value rather than a sequential integer. This allows concurrent authorizations to be generated and processed out of order, making it highly suitable for high-throughput, asynchronous HTTP requests. 

The signature itself is generated using EIP-712 typed data signing, which binds the authorization to a specific context via a domain separator. This prevents replay attacks across different networks or token contracts. For instance, a signature bound to chain ID 84532 (Base Sepolia) and the USDC contract at `0x036CbD53842c5426634e7929541eC2318f3dCF7e` is cryptographically invalid anywhere else. Finally, a trusted server-side component known as a "facilitator" is responsible for validating these off-chain signatures, delivering the API response, and eventually submitting the authorizations on-chain to realize the token transfer.

### 2.2 The Machine-to-Machine Economy

AI agents are rapidly emerging as autonomous economic actors. LLM-based systems now routinely purchase computing power, access proprietary data feeds, invoke external APIs, and rent inference capacity without human intervention. Galaxy Research estimates that agentic commerce could represent $3–5 trillion in B2C revenue by 2030. As these agents transition from isolated scripts to interconnected economic participants, the infrastructure supporting their transactions must scale accordingly.

However, as the volume of agent-to-service interactions grows, the inability to distinguish trusted from untrusted agents introduces a systemic friction. Unlike human identity — which relies on KYC (Know Your Customer) procedures, persistent legal identities, and traditional credit bureaus — agent identity is pseudonymous and highly disposable. Agents can generate new keypairs instantly, possess no legal accountability, and lack persistent identity across interactions. Consequently, trust in the machine economy must be derived entirely from verifiable on-chain behavior rather than off-chain reputation.

### 2.3 Prior Work: Credit in Decentralized Systems

On-chain reputation systems have primarily focused on persistent identity rather than financial behavior. ERC-8004 (Trustless AI Agent Identity standard), deployed on mainnet in January 2026, established three core registries: Identity, Reputation, and Validation. However, ERC-8004 deliberately excludes payment mechanisms, providing a framework for identity but leaving financial reputation unsolved. AgentCredit acts as the missing payment layer that ERC-8004 invited the ecosystem to build, mapping financial behavior to agent identities.

While zero-knowledge credit scoring has been explored, such as zkScore.credit's Circom-based proofs for human borrowers, AgentCredit targets a fundamentally different context. Existing solutions apply ZK credit proofs to human DeFi borrowers securing undercollateralized loans based on off-chain bank data or rigid on-chain collateral history. AgentCredit, conversely, applies ZK credit proofs to autonomous agents transacting at high velocity via HTTP, requiring a distinct commitment scheme and highly optimized circuit design to support sub-second proof generation and verification.

AgentCredit also differs significantly from existing DeFi credit protocols. Protocols like Aave rely strictly on overcollateralization with no concept of reputation. Platforms like Goldfinch offer undercollateralized lending but depend on human-identity gating and off-chain legal agreements. AgentCredit is strictly behavior-gated; it requires neither off-chain identity verification nor upfront collateral, deriving creditworthiness entirely from an agent's continuous on-chain payment history.

---

## 3. Problem Statement

### 3.1 The Trust Gap

**Problem 1 — Flat pricing ignores agent payment history**
When an AI agent requests an x402-gated API, the server only validates the cryptographic authorization and executes the request. An agent with a long history of successful, high-volume transactions is treated identically to an agent making its first request. The economic consequence is that service providers must price defensively for all users, causing reliable agents to systematically over-pay.

**Problem 2 — Agents cannot prove creditworthiness within a single HTTP request**
Even if service providers attempt to implement dynamic pricing based on trust, there is no standardized protocol for an agent to succinctly prove its transaction history during the HTTP handshake. The economic consequence is that services cannot seamlessly offer trust-based pricing without imposing severe latency penalties or requiring out-of-band verification steps.

**Problem 3 — No economic incentive exists to build payment reputation**
Currently, an agent's payment history has no redeemable utility, meaning there is no penalty for abandoning a wallet after a dispute and no reward for maintaining a consistent, long-term payment record. The economic consequence is an environment dominated by sybil attacks and disposable identities, stifling the evolution of long-term economic relationships between machines.

**Problem 4 — Credit line access requires upfront capital even for reliable agents**
High-frequency agent pipelines, such as complex inference chains, require agents to pre-fund their wallets with sufficient USDC to cover all downstream API calls. If the pipeline halts, the capital remains locked. The economic consequence is severe capital inefficiency, as operators must over-provision liquidity across countless agent wallets rather than leveraging deferred payment primitives.

### 3.2 Failure Modes of Naive Approaches

Attempts to solve the trust gap typically fall into one of two naive approaches, both of which introduce critical systemic failures.

**Approach A — History Disclosure:**
In this model, the agent reveals its full on-chain transaction history to each service provider. This approach fails on two fronts. First, it violates privacy: revealing a complete transaction history exposes behavioral patterns, payment volumes, and counterparty relationships to every service the agent queries. Second, it limits scalability: each service provider must construct custom indexing infrastructure to parse, aggregate, and evaluate the raw history, adding 2–6 seconds of latency per request and demanding significant engineering overhead.

**Approach B — Per-Request On-Chain Lookup:**
Alternatively, the service provider queries the blockchain or an indexer for the agent's score during every HTTP request. This approach fails due to latency and cost. A fresh RPC call per HTTP request fundamentally conflicts with the sub-100ms response requirements of high-frequency APIs. Furthermore, it consumes significant RPC quota and prevents ecosystem-wide standardization, as each provider defines custom trust criteria.

Ultimately, a viable solution requires three properties simultaneously: (1) privacy-preserving score attestation that shields transaction history, (2) in-request verification that adds negligible latency without external round trips, and (3) a canonical, shared on-chain registry that the entire ecosystem can trust.

---

## 4. Protocol Design

### 4.1 System Overview

The AgentCredit architecture is partitioned into a five-layer stack. 
**Layer 1: x402 Payment Rail** consists of the Express API, the `@x402/express` middleware, and custom hooks (`creditGate.ts`, `facilitatorHook.ts`) for tiered pricing and event enqueuing. 
**Layer 2: Indexer** utilizes a Graph subgraph to track `AuthorizationUsed` events, alongside a BullMQ keeper bot that calls `recordPayment()` on-chain. 
**Layer 3: Smart Contracts** comprises the core protocol logic deployed on Base: the `CreditRegistry.sol` UUPS proxy, `CreditLinePaymaster.sol`, `ZKVerifier.sol`, and `ProofCache.sol`. 
**Layer 4: ZK System** handles privacy-preserving proofs utilizing the Noir circuit `credit_proof.nr`, the Barretenberg backend, and the `@noir-lang/noir_js` library for browser-based proof generation. 
**Layer 5: Frontend** provides the Next.js dashboard where operators perform score lookups and agents generate in-browser proofs.

The data flow begins when an x402 payment is completed. The API facilitator enqueues a job via BullMQ. The asynchronous worker processes this job by calling `recordPayment()` on the `CreditRegistry`. The contract recomputes the agent's credit score and anchors it to a Poseidon hash commitment on-chain. When the agent wishes to access a service, it fetches this commitment, generates a Noir ZK proof locally demonstrating its score exceeds a defined threshold, and attaches the proof as the `X-CREDIT-PROOF` HTTP header. The service's `creditGate` middleware verifies the proof locally or via the `ProofCache` and instantly applies the appropriate tiered pricing discount.

### 4.2 The CreditRegistry

The `CreditRegistry` acts as the canonical source of truth for agent scores. It is deployed as a UUPS-upgradeable proxy contract governed by a 3-of-5 Gnosis Safe multisig via a 48-hour `TimelockController`. The contract maintains an `AgentScore` struct for every address, tracking `totalPayments` (uint256), `totalVolumeMicro` (uint256 representing USDC in 6-decimal units), `firstPaymentTime` (uint256), `lastPaymentTime` (uint256), `disputeCount` (uint256), `computedScore` (uint256), and `scoreCommitment` (bytes32). A `mapping(bytes32 => bool) usedNonces` explicitly prevents double-recording of the same EIP-3009 payment authorization.

The contract enforces strict access control through three specific roles. The `FACILITATOR_ROLE` is permitted to call `recordPayment()`, which is the sole state-changing function in the critical path. The `GUARDIAN_ROLE`, designed for rapid incident response, can call `emergencyPause()` instantly, bypassing the timelock. The `SCORE_ADMIN_ROLE` is authorized to update the score weighting parameters, subject to the 48-hour timelock delay. The `DEFAULT_ADMIN_ROLE` is exclusively held by the `TimelockController`; the original deployer's admin rights were completely revoked upon deployment to ensure strict decentralization.

Following any score recomputation, the registry updates the agent's `scoreCommitment` using the following construction:
`scoreCommitment = bytes32(PoseidonT3.hash([computedScore, uint256(uint160(agent))]))`
This Poseidon hash (over the BN254 curve) serves as the cryptographic anchor that the ZK circuit verifies against. It is imperative that the exact same hash function is utilized in both Solidity (via the `poseidon-solidity` library) and the Noir circuit (via `dep::poseidon::bn254::hash_2`). Because the BN254 curve is native to both the EVM precompile at `0x08` and the Barretenberg proving backend, the hash computation remains highly efficient and perfectly consistent across execution environments.

### 4.3 Credit Score Formula

The AgentCredit scoring algorithm is conceptually inspired by traditional FICO scoring models but heavily adapted for the mechanics of autonomous payment APIs. It evaluates four positive dimensions: payment breadth (total count), payment depth (total volume), longevity (account age), and recency (payment velocity). It incorporates a strict penalty for disputes. All dimension weights are configured as basis points (summing to 10,000) stored on-chain, allowing the `SCORE_ADMIN_ROLE` to adjust the formula through governance actions subject to the 48-hour timelock.

The on-chain calculation executes as follows, with the final result strictly clamped between a floor of 300 and a ceiling of 900:

```text
Score = 300 (floor)
      + min(totalPayments, 1000) / 1000 × 270        [Payment History: max 270]
      + min(log₂(totalVolumeUSD + 1), 10) / 10 × 180 [Volume Score: max 180]
      + min(accountAgeDays, 365) / 365 × 150         [Account Age: max 150]
      + min(avgPaymentsPerDay30d, 50) / 50 × 70      [Velocity: max 70]
      - disputeCount × 30                            [Dispute Penalty]
```

### 4.4 The ZK Proof System

The Zero-Knowledge component leverages Noir (an UltraPlonk-based zkSNARK framework) to achieve privacy-preserving credit verification. The circuit requires the private input of the agent's actual score and public inputs consisting of the desired threshold, the agent's address, the expected Poseidon commitment, and the current block number. The circuit enforces that the score is within valid bounds (300 to 900), strictly greater than or equal to the public threshold, and that the Poseidon hash of the score and agent address matches the public commitment anchored in the `CreditRegistry`. The block number input acts as a liveness parameter, ensuring proofs cannot be replayed indefinitely.

### 4.5 The x402 Credit Gate

The x402 Credit Gate is an Express middleware component that integrates seamlessly into the standard x402 payment flow. When a request arrives with an `X-CREDIT-PROOF` header, the middleware extracts the ZK proof and passes it to the on-chain `ZKVerifier` contract (or the off-chain local verifier logic). Upon successful cryptographic verification, the middleware maps the proven threshold to a predefined tier (e.g., Gold for a threshold of 750, Silver for 600) and automatically adjusts the required USDC payment amount before issuing the 402 Payment Required response.

### 4.6 The CreditLine Paymaster

To address capital inefficiency, AgentCredit implements an ERC-4337 `CreditLinePaymaster`. High-scoring agents (e.g., score ≥ 700) are permitted to route their UserOperations through this paymaster, which sponsors the gas for their transactions. This effectively grants trusted agents a revolving line of credit for network execution fees, drastically reducing the upfront capital requirements for complex, multi-step inference chains. The paymaster reads directly from the `CreditRegistry` to ensure only agents meeting the strict scoring criteria receive gas sponsorship.

### 4.7 The ProofCache

To optimize latency, AgentCredit introduces the `ProofCache` smart contract. Because generating a Noir UltraPlonk proof requires approximately 8 seconds on standard hardware, proving every single HTTP request is computationally infeasible. Instead, an agent submits its proof to the `ProofCache` contract. The contract verifies the proof via `ZKVerifier` and, if valid, records a timestamped receipt on-chain. This receipt is valid for a strict 12-hour window (approximately 3,600 blocks on Base). Subsequent API requests within this window bypass the ZK proving overhead entirely, relying on the cached on-chain validation for instantaneous execution.

---

## 5. Security Analysis

### 5.1 Threat Model

The primary threats to the AgentCredit protocol involve score manipulation, privacy leakage, and economic exploits through proof replay. The threat model assumes attackers have full visibility into public chain state, the ability to control multiple agent identities (Sybil behavior), and standard capabilities to interact directly with the x402 API endpoints and smart contracts.

### 5.2 Vulnerability Matrix

| Vulnerability | Mitigation | Status |
| --- | --- | --- |
| Sybil Score Bootstrap | 7-day minimum age gate + log-scale volume weighting | Implemented |
| Fake Score ZK Injection | On-chain Poseidon commitment anchored by Registry | Implemented |
| `recordPayment` Spoofing | FACILITATOR_ROLE restricted + EIP-3009 nonce verification | Implemented |
| ZK Proof Replay | Block number expiry (3600 blocks ≈ 12 hours) | Implemented |
| Oracle Price Manipulation | Hardcoded deterministic tiered pricing within the gate | Implemented |
| Hash Inconsistency | Poseidon (BN254) utilized symmetrically in Solidity and Noir | Fixed |

### 5.3 Cryptographic Security

The system relies on the security of the BN254 elliptic curve for both the Poseidon hash commitments and the underlying UltraPlonk proving system. The EIP-3009 authorization signatures rely on the standard secp256k1 curve utilized by the EVM. The protocol enforces strict nonce tracking to prevent frontrunning and MEV replay attacks on payment authorizations. The protocol's upgradeability relies on UUPS (Universal Upgradeable Proxy Standard) secured by a time-delayed multisig, ensuring no single entity can unilaterally alter the cryptographic verifiers or scoring logic without public scrutiny.

---

## 6. Economic Model

### 6.1 Incentive Structure

AgentCredit aligns the incentives of AI agents and service providers. Agents are economically incentivized to consolidate their payment history under a persistent identity to unlock compounding price discounts. Service providers are incentivized to integrate the protocol to attract high-volume, reliable agents, reducing the risk of payment defaults and fraudulent API utilization.

### 6.2 Credit Tier Pricing

The protocol standardizes tiered pricing based on cryptographic proof of score thresholds. While service providers can configure custom thresholds, the standard reference implementations enforce:
- **Unknown (Score 300–599):** Standard baseline pricing.
- **Silver (Score 600–749):** 20% discount applied to the baseline.
- **Gold (Score 750–900):** 50% discount applied to the baseline.

### 6.3 Credit Line Economics

The `CreditLinePaymaster` provides trusted agents with deferred payment mechanics for gas. By sponsoring the upfront execution costs for agents with scores ≥ 700, the paymaster acts as an on-chain credit facility. This drastically reduces the locked liquidity requirements for agent operators, allowing capital to be deployed more efficiently across the decentralized ecosystem rather than stagnating in isolated wallet balances.

---

## 7. Implementation

### 7.1 Smart Contract Architecture

The core logic is implemented in Solidity (version ^0.8.24) and managed via Foundry. The `CreditRegistry` acts as the primary data store and is deployed behind an `ERC1967Proxy`. The `ZKVerifier` is an immutable, auto-generated contract compiled directly from the Noir circuit artifacts. The `CreditLinePaymaster` is built using the ZeroDev SDK abstractions to provide ERC-4337 compatibility. The architecture enforces strict separation of concerns, decoupling the payment indexing logic from the cryptographic verification and the gas sponsorship.

### 7.2 Off-Chain Infrastructure

The off-chain infrastructure relies heavily on TypeScript and Node.js. An Express API handles the x402 payment routing and `X-CREDIT-PROOF` extraction. A Graph Protocol subgraph actively indexes the `AuthorizationUsed` events emitted by the USDC contract. A BullMQ worker, backed by a persistent Redis instance, consumes these events and executes the on-chain `recordPayment()` calls with exponential backoff to handle transient RPC failures or Base L1 data fee spikes gracefully.

### 7.3 Deployed Contracts

The protocol is currently deployed on the Base Sepolia testnet at the following addresses:
- **CreditRegistry (Proxy):** `0x6e1219c3938Ee9de9df567616d1FC5D3b3966e13`
- **CreditLinePaymaster:** `0x5b3E8dF2181866AdD15e10A31bFf12FBf05A8085`
- **ZKVerifier:** `0x394B61757c22833d0188eED6d3B302d4E276822e`
- **USDC (Testnet):** `0x036CbD53842c5426634e7929541eC2318f3dCF7e`

---

## 8. Evaluation

### 8.1 Test Coverage

The smart contract layer is heavily tested using Foundry. The test suite includes 16 dedicated unit tests for the `CreditRegistry` and 6 for the `ProofCache`. All 27 protocol-level tests are currently passing. The test suite achieves 82% branch coverage and 88% function coverage for the critical `CreditRegistry` contract, ensuring robustness across varied state transitions.

### 8.2 Invariant Properties

To guarantee system integrity, 5 core invariant properties were defined and validated using Foundry's fuzzing engine across 250,000 randomized calls:
1. `scoreAlwaysInValidRange`: The computed score must always remain strictly between 300 and 900.
2. `scoreNeverDecreases`: The computed score must be monotonically non-decreasing over time.
3. `nonceMonotonicity`: Previously used EIP-3009 nonces must be permanently marked as consumed.
4. `totalPaymentsNeverDecreases`: The aggregate payment count can only increment.
5. `pausedContractBlocksPayments`: The `recordPayment` function must strictly revert when the contract is paused by a Guardian.
All invariants hold under deep fuzzing.

### 8.3 Gas Analysis

The system is optimized for L2 execution on Base. The `recordPayment()` function, which is the primary state-mutating operation, is highly optimized, requiring only a single storage slot update for the agent's score struct and one for the utilized nonce. The verification of the UltraPlonk proof via the `ZKVerifier` consumes predictable gas, making it highly suitable for execution on Base where computation is exceptionally cheap relative to L1 Ethereum.

---

## 9. Roadmap and Future Work

The immediate roadmap involves migrating the protocol to Base Mainnet following comprehensive security audits, including a planned competitive audit on Sherlock or Code4rena. Future iterations will focus on expanding the integration layer, particularly deep compatibility with the ERC-8004 Trustless AI Agent Identity standard to merge financial reputation with generalized agent metadata. Furthermore, the `CreditLinePaymaster` will be upgraded to support dynamic, algorithmic credit limits based on real-time on-chain risk assessments, evolving the protocol from a simple discount layer into a fully-fledged decentralized credit facility for autonomous agents.

---

## References

1. x402 Official Specification — HTTP 402 payment standard — [x402.org](https://x402.org)
2. EIP-3009: Transfer With Authorization — [eips.ethereum.org](https://eips.ethereum.org/EIPS/eip-3009)
3. EIP-712: Typed Structured Data Signing — [eips.ethereum.org](https://eips.ethereum.org/EIPS/eip-712)
4. ERC-8004: Trustless AI Agent Identity — [eips.ethereum.org](https://eips.ethereum.org/EIPS/eip-8004)
5. Noir Language Documentation — [noir-lang.org](https://noir-lang.org/docs)
6. ERC-4337: Account Abstraction — [eips.ethereum.org](https://eips.ethereum.org/EIPS/eip-4337)
"""

with open("WHITEPAPER.md", "w", encoding="utf-8") as f:
    f.write(content)
