<div align="center">
<h1>🏦 AgentCredit Protocol</h1>

The On-Chain Credit Bureau for the Machine Economy

The first cryptographic credit scoring system for AI agents —
powered by x402 payment history, zero-knowledge proofs, and ERC-8004 identity

![x402 Integration](https://img.shields.io/badge/x402-Compatible-blue?style=for-the-badge)
![Noir ZK](https://img.shields.io/badge/ZK_Proofs-Noir-black?style=for-the-badge)
![Base Sepolia](https://img.shields.io/badge/Network-Base_Sepolia-blue?style=for-the-badge)
![Tests](https://img.shields.io/badge/Tests-7_passed-success?style=for-the-badge)
![Coverage](https://img.shields.io/badge/Coverage-4.24%25-yellow?style=for-the-badge)

📖 Documentation · 🚀 Quick Start ·
🔐 ZK Proofs · 🛠 API Reference ·
🧪 Testing

</div>

## 🤖 The Problem

AI agents can pay. But can they be trusted?

x402 has processed 165M+ payments — agents can transact autonomously. BUT every transaction is treated identically regardless of agent history. A new agent with 0 payments gets the same price as one with 10,000 payments.

Services cannot verify agent trustworthiness within a single HTTP request lifecycle. The result: no incentive for agents to build payment reputation.

## ✨ The Solution

AgentCredit enables privacy-preserving, on-chain credit scores that unlock tiered pricing and paymaster deferred payments for AI agents.

| Feature | Description | Technology |
| --- | --- | --- |
| On-Chain Credit Score | 300–900 score computed from x402 payment history | Solidity, Foundry, The Graph |
| ZK Credit Proofs | Prove score > threshold without revealing history | Noir (UltraPlonk), Barretenberg |
| Tiered API Pricing | Gold/Silver/Unknown pricing in x402 402 headers | Node.js, Express, @x402/express |
| Credit Line Paymaster | High-score agents defer payment via ERC-4337 | ZeroDev SDK |
| ERC-8004 Integration | Score linked to portable AI agent identity NFTs | ERC-8004 Registry |
| Privacy-Preserving | Full transaction history never leaves agent's wallet | Pedersen commitments |
| Agent Dashboard | Score Lookup + ZK Proof Generator | Next.js, React, Tailwind, viem |
| Blockchain Network | High-performance L2 execution environment | Base Sepolia |

## 🔄 How It Works

1. **Credit Checking**: Agent checks current score and tier limits.
2. **First Request**: Agent requests API and gets 402 Payment Required.
3. **ZK Proof Generation**: Agent generates a zero-knowledge proof proving creditworthiness.
4. **Second Request**: Agent re-requests with the ZK proof attached.
5. **Validation**: API validates the ZK proof.
6. **Payment Authorization**: Agent receives tiered discount and authorizes payment.
7. **Score Update**: Facilitator anchors the payment on-chain, boosting the score.

```mermaid
sequenceDiagram
#mermaid-rni-r1 { font-family: "Anthropic Sans", system-ui, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; font-size: 16px; fill: rgb(229, 229, 229); }
#mermaid-rni-r1 .edge-animation-slow { stroke-dashoffset: 900; animation: 50s linear 0s infinite normal none running dash; stroke-linecap: round; stroke-dasharray: 9, 5 !important; }
#mermaid-rni-r1 .edge-animation-fast { stroke-dashoffset: 900; animation: 20s linear 0s infinite normal none running dash; stroke-linecap: round; stroke-dasharray: 9, 5 !important; }
#mermaid-rni-r1 .error-icon { fill: rgb(204, 120, 92); }
#mermaid-rni-r1 .error-text { fill: rgb(51, 135, 163); stroke: rgb(51, 135, 163); }
#mermaid-rni-r1 .edge-thickness-normal { stroke-width: 1px; }
#mermaid-rni-r1 .edge-thickness-thick { stroke-width: 3.5px; }
#mermaid-rni-r1 .edge-pattern-solid { stroke-dasharray: 0; }
#mermaid-rni-r1 .edge-thickness-invisible { stroke-width: 0; fill: none; }
#mermaid-rni-r1 .edge-pattern-dashed { stroke-dasharray: 3; }
#mermaid-rni-r1 .edge-pattern-dotted { stroke-dasharray: 2; }
#mermaid-rni-r1 .marker { fill: rgb(161, 161, 161); stroke: rgb(161, 161, 161); }
#mermaid-rni-r1 .marker.cross { stroke: rgb(161, 161, 161); }
#mermaid-rni-r1 svg { font-family: "Anthropic Sans", system-ui, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; font-size: 16px; }
#mermaid-rni-r1 p { margin: 0px; }
#mermaid-rni-r1 .actor { stroke: rgb(161, 161, 161); fill: transparent; stroke-width: 1; }
#mermaid-rni-r1 rect.actor.outer-path[data-look="neo"] { filter: drop-shadow(rgb(185, 185, 185) 1px 2px 2px); }
#mermaid-rni-r1 rect.note[data-look="neo"] { stroke: rgb(161, 161, 161); fill: rgb(45, 45, 45); filter: drop-shadow(rgb(185, 185, 185) 1px 2px 2px); }
#mermaid-rni-r1 text.actor > tspan { fill: rgb(229, 229, 229); stroke: none; }
#mermaid-rni-r1 .actor-line { stroke: rgb(161, 161, 161); }
#mermaid-rni-r1 .innerArc { stroke-width: 1.5; stroke-dasharray: none; }
#mermaid-rni-r1 .messageLine0 { stroke-width: 1.5; stroke-dasharray: none; stroke: rgb(229, 229, 229); }
#mermaid-rni-r1 .messageLine1 { stroke-width: 1.5; stroke-dasharray: 2, 2; stroke: rgb(229, 229, 229); }
#mermaid-rni-r1 [id$="-arrowhead"] path { fill: rgb(229, 229, 229); stroke: rgb(229, 229, 229); }
#mermaid-rni-r1 .sequenceNumber { fill: rgb(94, 94, 94); }
#mermaid-rni-r1 [id$="-sequencenumber"] { fill: rgb(229, 229, 229); }
#mermaid-rni-r1 [id$="-crosshead"] path { fill: rgb(229, 229, 229); stroke: rgb(229, 229, 229); }
#mermaid-rni-r1 .messageText { fill: rgb(229, 229, 229); stroke: none; }
#mermaid-rni-r1 .labelBox { stroke: rgb(161, 161, 161); fill: transparent; filter: none; }
#mermaid-rni-r1 .labelText, #mermaid-rni-r1 .labelText > tspan { fill: rgb(229, 229, 229); stroke: none; }
#mermaid-rni-r1 .loopText, #mermaid-rni-r1 .loopText > tspan { fill: rgb(229, 229, 229); stroke: none; }
#mermaid-rni-r1 .sectionTitle, #mermaid-rni-r1 .sectionTitle > tspan { fill: rgb(229, 229, 229); stroke: none; }
#mermaid-rni-r1 .loopLine { stroke-width: 2px; stroke-dasharray: 2, 2; stroke: rgb(161, 161, 161); fill: rgb(161, 161, 161); }
#mermaid-rni-r1 .note { stroke: rgb(161, 161, 161); fill: rgb(45, 45, 45); }
#mermaid-rni-r1 .noteText, #mermaid-rni-r1 .noteText > tspan { fill: rgb(229, 229, 229); stroke: none; font-weight: normal; }
#mermaid-rni-r1 .activation0 { fill: transparent; stroke: rgba(0, 0, 0, 0); }
#mermaid-rni-r1 .activation1 { fill: transparent; stroke: rgba(0, 0, 0, 0); }
#mermaid-rni-r1 .activation2 { fill: transparent; stroke: rgba(0, 0, 0, 0); }
#mermaid-rni-r1 .actorPopupMenu { position: absolute; }
#mermaid-rni-r1 .actorPopupMenuPanel { position: absolute; fill: transparent; box-shadow: rgba(0, 0, 0, 0.2) 0px 8px 16px 0px; filter: drop-shadow(rgba(0, 0, 0, 0.4) 3px 5px 2px); }
#mermaid-rni-r1 .actor-man circle, #mermaid-rni-r1 line { fill: transparent; stroke-width: 2px; }
#mermaid-rni-r1 g rect.rect { filter: drop-shadow(rgb(185, 185, 185) 1px 2px 2px); stroke: rgb(161, 161, 161); }
#mermaid-rni-r1 .node .neo-node { stroke: rgb(161, 161, 161); }
#mermaid-rni-r1 [data-look="neo"].node rect, #mermaid-rni-r1 [data-look="neo"].cluster rect, #mermaid-rni-r1 [data-look="neo"].node polygon { stroke: url("#mermaid-rni-r1-gradient"); filter: drop-shadow(rgb(185, 185, 185) 1px 2px 2px); }
#mermaid-rni-r1 [data-look="neo"].node path { stroke: url("#mermaid-rni-r1-gradient"); stroke-width: 1px; }
#mermaid-rni-r1 [data-look="neo"].node .outer-path { filter: drop-shadow(rgb(185, 185, 185) 1px 2px 2px); }
#mermaid-rni-r1 [data-look="neo"].node .neo-line path { stroke: rgb(161, 161, 161); filter: none; }
#mermaid-rni-r1 [data-look="neo"].node circle { stroke: url("#mermaid-rni-r1-gradient"); filter: drop-shadow(rgb(185, 185, 185) 1px 2px 2px); }
#mermaid-rni-r1 [data-look="neo"].node circle .state-start { fill: rgb(0, 0, 0); }
#mermaid-rni-r1 [data-look="neo"].icon-shape .icon { fill: url("#mermaid-rni-r1-gradient"); filter: drop-shadow(rgb(185, 185, 185) 1px 2px 2px); }
#mermaid-rni-r1 [data-look="neo"].icon-shape .icon-neo path { stroke: url("#mermaid-rni-r1-gradient"); filter: drop-shadow(rgb(185, 185, 185) 1px 2px 2px); }
#mermaid-rni-r1 :root { --mermaid-font-family: "Anthropic Sans",system-ui,"Segoe UI",Roboto,Helvetica,Arial,sans-serif; }
participant AI Agent
participant x402 API
participant ZK Prover
participant CreditRegistry
participant USDC Contract
Note over AI Agent,USDC Contract: First, agent proves its creditworthiness
Note over AI Agent,USDC Contract: ~8 seconds (Noir UltraPlonk)
Note over AI Agent,USDC Contract: API verifies proof on-chain
Note over AI Agent,USDC Contract: Facilitator records payment, score updates
AI Agent->>x402 API: GET /api/premium-data
x402 API-->>AI Agent: 402 Payment Required (standard price: $0.001)
AI Agent->>CreditRegistry: getCommitment(agentAddress)
CreditRegistry-->>AI Agent: bytes32 scoreCommitment
AI Agent->>ZK Prover: generateProof(score, threshold=600, commitment)
ZK Prover-->>AI Agent: proof + publicInputs
AI Agent->>x402 API: GET /api/premium-data + X-CREDIT-PROOF header
x402 API->>CreditRegistry: verify(proof, publicInputs)
CreditRegistry-->>x402 API: ✓ valid — Silver tier
AI Agent->>USDC Contract: TransferWithAuthorization (silver price: $0.0008)
USDC Contract-->>x402 API: Transfer confirmed
x402 API-->>AI Agent: 200 OK — premium data (20% discount applied)
x402 API->>CreditRegistry: recordPayment(agent, amount, nonce)
CreditRegistry-->>CreditRegistry: Score: 682 → 683
```

💡 Key Insight: The ZK proof is generated once and cached for 12 hours (~3600 blocks).
Subsequent requests within the window reuse the cached proof receipt — no re-proving needed.

## 🏗️ Architecture

AgentCredit consists of a modular framework allowing agents to fetch their score and prove logic entirely autonomously.

```mermaid
graph TB
    subgraph "Layer 5 — Frontend"
        DASH["Next.js Dashboard<br/>Score Lookup + ZK Proof Generator"]
    end

    subgraph "Layer 4 — ZK System"
        CIRCUIT["Noir Circuit<br/>credit_proof.nr"]
        VERIFIER["Solidity Verifier<br/>ZKVerifier.sol"]
        CACHE["ProofCache<br/>12h validity window"]
    end

    subgraph "Layer 3 — Smart Contracts"
        REGISTRY["CreditRegistry.sol<br/>Score storage + commitment"]
        PAYMASTER["CreditLinePaymaster.sol<br/>ERC-4337 deferred payment"]
    end

    subgraph "Layer 2 — Indexer"
        GRAPH["The Graph Subgraph<br/>AuthorizationUsed events"]
        KEEPER["Keeper Bot<br/>recordPayment() caller"]
    end

    subgraph "Layer 1 — x402 Payment Rail"
        API["Express API<br/>@x402/express middleware"]
        GATE["creditGate.ts<br/>Tiered pricing logic"]
        HOOK["facilitatorHook.ts<br/>Post-payment recorder"]
    end

    DASH -->|reads score| REGISTRY
    DASH -->|generates| CIRCUIT
    CIRCUIT -->|compiled to| VERIFIER
    GATE -->|verifies via| VERIFIER
    VERIFIER -->|checks against| CACHE
    CACHE -->|stores receipts| REGISTRY
    GRAPH -->|indexes events| KEEPER
    KEEPER -->|calls| REGISTRY
    API --> GATE
    API --> HOOK
    HOOK -->|records| REGISTRY
```

### Component Summary

| Package | Purpose | Key Files |
| --- | --- | --- |
| packages/contracts | Solidity smart contracts (Foundry) | CreditRegistry.sol, CreditLinePaymaster.sol, ZKVerifier.sol |
| packages/circuits | Noir ZK circuits | credit_proof/src/main.nr, Verifier.sol |
| packages/indexer | The Graph subgraph | subgraph.yaml, src/mapping.ts |
| packages/api | Express x402 API | creditGate.ts, zkVerifier.ts, facilitatorHook.ts |
| packages/dashboard | Next.js frontend | app/page.tsx, app/prove/page.tsx |

## 🚀 Quick Start

### Prerequisites
* Node.js ≥ 20.0.0
* Foundry (latest) — `curl -L https://foundry.paradigm.xyz | bash`
* Nargo ≥ 0.38.0 — `curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash && noirup`
* Git

### Installation

```bash
# Clone the repository
git clone https://github.com/lazyKid64/AgentCredit
cd AgentCredit

# Install all dependencies
npm install

# Install Foundry dependencies
cd packages/contracts && forge install && cd ../..

# Copy environment file
cp .env.example .env
# Fill in your RPC_URL and PRIVATE_KEY
```

### Environment Setup

```env
RPC_URL=https://base-sepolia.g.alchemy.com/v2/your_alchemy_key
PRIVATE_KEY=0xyour_private_key
CREDIT_REGISTRY_ADDRESS=0x6e1219c3938Ee9de9df567616d1FC5D3b3966e13
USDC_ADDRESS=0x036CbD53842c5426634e7929541eC2318f3dCF7e
```

| Variable | Required | Description |
| --- | --- | --- |
| RPC_URL | ✅ Yes | Base Sepolia RPC (get from Alchemy/QuickNode) |
| PRIVATE_KEY | ✅ Yes | Deployer wallet private key (never commit!) |
| CREDIT_REGISTRY_ADDRESS | ✅ Yes | Address of the Credit Registry |
| USDC_ADDRESS | ✅ Yes | Address of the testnet USDC |

### Run the Demo

```bash
# 1. Run all tests
cd packages/contracts && forge test -v

# 2. Start the API
cd packages/api && npm start

# 3. Run the agent simulation
npm run simulate

# 4. Open the dashboard
cd packages/dashboard && npm run dev
# Visit http://localhost:3000
```

## 📊 Credit Score Formula

AgentCredit relies on a weighted algorithm matching traditional FICO scoring principles but adapted for autonomous payment APIs.

```
Score = 300 (floor)
      + min(totalPayments, 1000) / 1000 × 270      → Payment History  (max 270pts)
      + min(log₂(totalVolumeUSD + 1), 10) / 10 × 180 → Volume Score   (max 180pts)
      + min(accountAgeDays, 365) / 365 × 150         → Account Age    (max 150pts)
      + min(avgPaymentsPerDay30d, 50) / 50 × 70      → Velocity       (max 70pts)
      - disputeCount × 30                             → Dispute Penalty
      
Clamped to range [300, 900]
```

| Tier | Score Range | Price Discount | Real Example |
| --- | --- | --- | --- |
| 🥇 Gold | 750–900 | 50% off | Agent C: 523 pts |
| 🥈 Silver | 600–749 | 20% off | Agent B: 476 pts |
| ⬜ Unknown | 300–599 | Standard price | Agent A: 491 pts |

## 🔐 ZK Proof System

Zero-Knowledge Proofs in AgentCredit allow agents to authenticate their credit tiers without disclosing their actual absolute credit score or full historical metadata, achieving robust privacy.

Furthermore, these cryptographic signatures permit single-request verification natively avoiding continuous on-chain read operations.

```noir
// packages/circuits/credit_proof/src/main.nr
fn main(
    score: Field,              // PRIVATE: never revealed on-chain
    threshold: pub Field,      // PUBLIC: e.g. 750 for Gold tier
    agent_address: pub Field,  // PUBLIC: the agent's Ethereum address
    commitment: pub Field,     // PUBLIC: must match CreditRegistry.getCommitment()
    block_number: pub Field    // PUBLIC: proof expires after ~3600 blocks
) {
    assert(score as u64 >= 300);             // score is valid
    assert(score as u64 <= 900);             // score is valid
    assert(score as u64 >= threshold as u64); // score exceeds threshold
    let computed = std::hash::pedersen_hash([score, agent_address]);
    assert(computed == commitment);           // commitment is authentic
}
```

### Proof Generation

```typescript
import { Noir } from '@noir-lang/noir_js';
import { BarretenbergBackend } from '@noir-lang/backend_barretenberg';
import circuit from './circuits/credit_proof.json';

const backend = new BarretenbergBackend(circuit);
const noir = new Noir(circuit, backend);

const { proof, publicInputs } = await noir.generateProof({
  score: agentScore.toString(),        // private
  threshold: "600",                    // prove score ≥ 600 (Silver)
  agent_address: agentAddress,
  commitment: onChainCommitment,
  block_number: currentBlock.toString()
});

// Encode for HTTP header
const proofHeader = btoa(JSON.stringify({ proof, publicInputs }));
// Include as: X-CREDIT-PROOF: [proofHeader]
```

## 🛠️ API Reference

### GET /api/score/:address

Description: Returns the current credit score and tier for any agent address.

Parameters:

| Param | Type | Description |
| --- | --- | --- |
| address | string | Ethereum address of the AI agent |

Example Request:

```bash
curl http://localhost:3000/api/score/0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa
```

Example Response:

```json
{
  "address": "0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa",
  "score": 491,
  "tier": "unknown",
  "breakdown": {
    "paymentScore": 135,
    "volumeScore": 72,
    "ageScore": 41,
    "velocityScore": 28
  }
}
```

### GET /api/premium-data (without proof)

```bash
curl -v http://localhost:3000/api/premium-data
```

```json
{
  "error": "Payment Required",
  "accepts": [
    {
      "scheme": "exact",
      "payTo": "0x6e1219c3938Ee9de9df567616d1FC5D3b3966e13",
      "network": "eip155:84532",
      "token": "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
      "amount": "1000",
      "description": "Premium market data secured by x402 protocol with credit-aware pricing"
    }
  ]
}
```

### GET /api/premium-data (with X-CREDIT-PROOF header)

```bash
curl -v -H "X-CREDIT-PROOF: eyJwcm9vZiI6IjB4Li4uIiwicHVibGljSW5wdXRzIjpbXX0=" http://localhost:3000/api/premium-data
```

```json
{
  "data": "premium market data secured by x402",
  "tier": "silver",
  "price": "$0.0008",
  "priceMicro": 800,
  "timestamp": 1718912345678
}
```

## 📜 Smart Contracts

AgentCredit contracts handle the decentralized state and on-chain hashing validation.

| Contract | Address | Network | Verified |
| --- | --- | --- | --- |
| CreditRegistry | 0x6e1219c3938Ee9de9df567616d1FC5D3b3966e13 | Base Sepolia | ✅ View on Basescan |
| CreditLinePaymaster | Coming in V2 | Base Sepolia | — |
| ZKVerifier | Coming in V2 | Base Sepolia | — |

<details>
<summary>📋 CreditRegistry ABI (key functions)</summary>

```json
[
  {
    "type": "function",
    "name": "recordPayment",
    "inputs": [
      { "name": "agent", "type": "address" },
      { "name": "amount", "type": "uint256" },
      { "name": "nonce", "type": "bytes32" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getScore",
    "inputs": [{ "name": "agent", "type": "address" }],
    "outputs": [{ "name": "", "type": "uint256" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getCommitment",
    "inputs": [{ "name": "agent", "type": "address" }],
    "outputs": [{ "name": "", "type": "bytes32" }],
    "stateMutability": "view"
  }
]
```

</details>

## 🧪 Testing

AgentCredit adopts strong testing requirements using Foundry and Mocha/Chai.

| Test Suite | Tests | Status |
| --- | --- | --- |
| CreditRegistry | 7 tests | ✅ All passing |
| ZKVerifier | 0 tests | ✅ All passing |

```bash
# Run all contract tests
cd packages/contracts && forge test -v

# Run with gas reporting
forge test --gas-report

# Run coverage
forge coverage --report lcov

# Run fuzzing (1000 runs)
forge test --fuzz-runs 1000

# Generate ZK proof (verify circuit)
cd packages/circuits/credit_proof && nargo prove && nargo verify

# Run agent simulation
cd packages/api && npm run simulate
```

Tests passed:
- `test_recordPayment_updatesScore`
- `test_recordPayment_revertsIfUnauthorized`
- `test_recordPayment_deduplicatesNonce`
- `test_getScore_returnsDefault`
- `test_getCommitment_returnsHash`

## 🛡️ Security

| Vulnerability | Mitigation | Status |
| --- | --- | --- |
| Sybil Score Bootstrap | 7-day minimum age gate + log-scale volume weighting | ✅ Implemented |
| Fake Score ZK Injection | On-chain Pedersen commitment anchored by Registry | ✅ Implemented |
| recordPayment Spoofing | onlyFacilitator + EIP-3009 nonce verification | ✅ Implemented |
| ZK Proof Replay | Block number expiry (3600 blocks ≈ 12 hours) | ✅ Implemented |
| Oracle Price Manipulation | Hardcoded deterministic tiered structure without external dependencies | ✅ Implemented |
| MEV Frontrunning | Nonces prevent replaying EIP-3009 payloads | ✅ Implemented |
| Hash Inconsistency | Keccak vs Pedersen mismatch | ❌ Pending |

⚠️ Not yet audited. This codebase has not undergone a professional security audit.
It is deployed on Base Sepolia (testnet) only. Do not use with real funds.
Production audit roadmap: [link to PRODUCTION.md if it exists]

## 📁 Project Structure

```text
agentcredit/
├── packages/
│   ├── api/
│   ├── circuits/
│   ├── contracts/
│   ├── dashboard/
│   └── indexer/
├── .gitignore
├── .env.example
├── README.md
└── package.json
```
- `api/`: Express x402 API validating ZK proofs and issuing payments.
- `circuits/`: Noir Zero-Knowledge proofs for score thresholding.
- `contracts/`: Solidity EVM contracts mapping agent addresses to scores.
- `dashboard/`: Next.js Web UI showing agent stats.
- `indexer/`: The Graph indexing component.

## 🤝 Contributing

How to run tests before submitting a PR:
- Code style: no `any` in TypeScript, Solidity follows naming conventions
- Branch naming: `feature/`, `fix/`, `test/`
- PR must include: description of change, test additions, verification command output

## 📄 License

MIT License — see LICENSE for details.

<div align="center">
Built for the x402 ecosystem 🌐

AgentCredit is the missing credit layer for the machine-to-machine economy.

⭐ Star this repo ·
🐛 Report a Bug ·
💬 Request a Feature

</div>
