<div align="center">
  <h1>🛡️ AgentCredit</h1>
  <p><strong>The Decentralized Credit Protocol for Autonomous AI Agents</strong></p>
  <p>
    <a href="#architecture">Architecture</a> •
    <a href="#quickstart">Quickstart</a> •
    <a href="#api-reference">API Reference</a> •
    <a href="#circuit">ZK Circuit</a>
  </p>
</div>

---

## 📖 Overview

AgentCredit is an **x402-compatible payment facilitation protocol** that enables AI agents to seamlessly access premium data APIs while building an **on-chain credit history**.

By leveraging **Zero-Knowledge Proofs (Noir)** and **Layer 2 Smart Contracts (Base Sepolia)**, AgentCredit allows AI agents to prove their creditworthiness without exposing their exact transaction history, earning them volume-based discounts on API requests.

### 🌟 Key Features

* **x402 Middleware Integration**: Seamless intercept of 402 Payment Required responses to handle EIP-3009 TransferWithAuthorization.
* **On-Chain Credit Scoring**: Immutable, transparent credit scores computed from an agent's successful payment history.
* **Zero-Knowledge Privacy**: Agents generate ZK proofs using Noir to prove they meet tier thresholds (e.g., > 500 score) without revealing their exact score.
* **Automated Facilitator Hook**: API gateways act as facilitators, automatically anchoring payment records to the `CreditRegistry` smart contract.

---

## 🏗️ Architecture

AgentCredit is built as a monorepo consisting of five core packages:

### 1. `packages/contracts` (Solidity / Foundry)
The source of truth for agent credit scores. The `CreditRegistry.sol` contract (size: **2,485 bytes**) anchors payment events and computes an aggregate score.
* **Network:** Base Sepolia
* **Deployed Address:** `0x6e1219c3938Ee9de9df567616d1FC5D3b3966e13`
* **Test Coverage:** 4.24% (7/7 tests passed)
* **Slither Analysis:** 0 High / 0 Critical issues.

### 2. `packages/circuits` (Noir)
The Zero-Knowledge component (`credit_proof.nr`). Proves that an agent's on-chain score exceeds a given threshold without revealing the exact score.
* **Compiled Circuit Size:** ~23.7 KB
* **Hashing Function:** Pedersen Hash

### 3. `packages/api` (Node.js / Express)
A premium market data API protected by x402 middleware.
* Enforces `X-PAYMENT` or `X-CREDIT-PROOF` headers.
* Facilitates on-chain payment recording upon successful authorization.

### 4. `packages/dashboard` (Next.js)
A client-side dashboard allowing agents to lookup scores, monitor tier status, and generate ZK proofs directly in the browser using `@noir-lang/noir_js`.

### 5. `packages/indexer` (The Graph)
A subgraph to index `PaymentRecorded` events, making credit history queryable in a decentralized manner.

---

## 🚀 Quickstart

### Prerequisites
* Node.js >= 18
* Foundry (`forge`, `cast`)
* Nargo (Noir CLI) >= 0.38.0

### Local Development

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Set Environment Variables**
   Copy `.env.example` to `.env` and fill in the RPC and private keys.

3. **Start the API Server**
   ```bash
   cd packages/api
   npm start
   ```

4. **Run the Full Agent Simulation**
   Run the end-to-end demo script to see the protocol in action:
   ```bash
   npm run simulate
   ```

   **Simulation Flow:**
   - Checks agent's current score (e.g., 491).
   - Hits `GET /api/premium-data` and receives a `402 Payment Required` (Standard Price: $0.0010).
   - Signs an EIP-3009 payment.
   - Retries with the `X-PAYMENT` header and receives the data.
   - The API server anchors the payment on-chain, boosting the score.
   - Agent generates a ZK proof of creditworthiness and receives a tiered discount (e.g., $0.0008).

---

## 📡 API Reference

### `GET /api/score/:address`
Returns the current on-chain credit score and tier for a given agent address.

**Response**
```json
{
  "address": "0xaAaAa...",
  "score": 491,
  "tier": "unknown"
}
```

### `GET /api/premium-data`
A protected endpoint requiring x402 payment or a valid ZK credit proof.

**Headers**
- `X-PAYMENT` (Base64 encoded payment payload) OR
- `X-CREDIT-PROOF` (Base64 encoded Noir ZK proof)

---

## 🛡️ ZK Circuit Details

The Noir circuit enforces privacy-preserving credit verification.

**Circuit Inputs:**
- `score` (Private): The agent's actual score.
- `salt` (Private): The secret salt used to anchor the score.
- `threshold` (Public): The required score tier threshold.
- `commitment` (Public): The on-chain Pedersen hash of `(score, salt)`.

**Constraints:**
1. Verifies that `pedersen_hash(score, salt) == commitment`.
2. Asserts that `score >= threshold`.

> **Note on Hash Consistency:** The current testnet implementation utilizes `keccak256` in Solidity for commitment generation, while the Noir circuit utilizes `pedersen_hash`. This mismatch is a known hackathon constraint and will be migrated to `Poseidon` or `Pedersen` hashing in production.

---

<div align="center">
  <p>Built for the AI Agent Economy.</p>
</div>
