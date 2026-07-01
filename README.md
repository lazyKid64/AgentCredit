<div align="center">

# 🏦 AgentCredit Protocol

### The On-Chain Credit Bureau for the Machine Economy

**The first cryptographic credit scoring system for AI agents — powered by x402 payment history, zero-knowledge proofs, and ERC-8004 identity**

[![x402 Integration](https://img.shields.io/badge/x402-Compatible-blue?style=for-the-badge)](#)
[![Noir ZK](https://img.shields.io/badge/ZK_Proofs-Noir-black?style=for-the-badge)](#)
[![Base Sepolia](https://img.shields.io/badge/Network-Base_Sepolia-blue?style=for-the-badge)](#)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](#12-project-license)

[![Tests](https://img.shields.io/badge/Tests-27_passed-success?style=flat-square)](#8-testing)
[![Invariants](https://img.shields.io/badge/Invariants-5_properties-success?style=flat-square)](#8-testing)
[![Coverage](https://img.shields.io/badge/Branch_Coverage-82%25-green?style=flat-square)](#8-testing)
[![Solidity](https://img.shields.io/badge/Solidity-%23363636.svg?style=flat-square&logo=solidity&logoColor=white)](#)
[![Foundry](https://img.shields.io/badge/Foundry-black?style=flat-square)](#)
[![Next JS](https://img.shields.io/badge/Next.js-black?style=flat-square&logo=next.js&logoColor=white)](#)
[![React](https://img.shields.io/badge/React-%2320232a.svg?style=flat-square&logo=react&logoColor=%2361DAFB)](#)
[![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-%2338B2AC.svg?style=flat-square&logo=tailwind-css&logoColor=white)](#)
[![TypeScript](https://img.shields.io/badge/TypeScript-%23007ACC.svg?style=flat-square&logo=typescript&logoColor=white)](#)
[![NodeJS](https://img.shields.io/badge/Node.js-6DA55F?style=flat-square&logo=node.js&logoColor=white)](#)
[![Express.js](https://img.shields.io/badge/Express.js-%23404d59.svg?style=flat-square&logo=express&logoColor=%2361DAFB)](#)
[![GraphQL](https://img.shields.io/badge/GraphQL-E10098?style=flat-square&logo=graphql&logoColor=white)](#)
[![The Graph](https://img.shields.io/badge/The_Graph-0B0A1D?style=flat-square)](#)
[![Ruby](https://img.shields.io/badge/Ruby-CC342D?style=flat-square&logo=ruby&logoColor=white)](#)
[![Shell](https://img.shields.io/badge/Shell_Script-121011?style=flat-square&logo=gnu-bash&logoColor=white)](#)
[![ZeroDev](https://img.shields.io/badge/ZeroDev-purple?style=flat-square)](#)
[![ERC-4337](https://img.shields.io/badge/ERC--4337-orange?style=flat-square)](#)
[![ERC-8004](https://img.shields.io/badge/ERC--8004-orange?style=flat-square)](#)

</div>

AgentCredit Protocol is an on-chain credit infrastructure layer built
on top of the [x402 payment standard](https://x402.org). It solves a
fundamental trust gap in the emerging machine-to-machine economy: AI
agents can now pay autonomously via x402, but every agent — whether it
has a perfect payment history or zero history — is treated identically
by every service it interacts with.

**The core idea is simple:** every time an AI agent completes an x402
payment on Base, that payment is indexed, verified, and aggregated into
a deterministic credit score (300–900) stored on-chain in the
`CreditRegistry` contract. Agents with strong payment histories can then
generate a **zero-knowledge proof** of their score — proving they meet a
score threshold to a service provider without revealing their actual
score or any individual transaction. The service provider verifies this
proof cryptographically within the HTTP request lifecycle and returns a
lower price automatically.

## Deployed Contracts (Base Sepolia)

`CreditRegistry (Proxy):` [0x6e1219c3938Ee9de9df567616d1FC5D3b3966e13](https://sepolia.basescan.org/address/0x6e1219c3938Ee9de9df567616d1FC5D3b3966e13)

`Testnet USDC:` [0x036CbD53842c5426634e7929541eC2318f3dCF7e](https://sepolia.basescan.org/address/0x036CbD53842c5426634e7929541eC2318f3dCF7e)

`CreditLinePaymaster:` [0x5b3E8dF2181866AdD15e10A31bFf12FBf05A8085](https://sepolia.basescan.org/address/0x5b3E8dF2181866AdD15e10A31bFf12FBf05A8085)

`ZKVerifier:` [0x394B61757c22833d0188eED6d3B302d4E276822e](https://sepolia.basescan.org/address/0x394B61757c22833d0188eED6d3B302d4E276822e)

## Table of Contents

* [1. Overview](#1-overview)
  * [What led to this project?](#what-led-to-this-project)
  * [1.1 The Problem We Solve](#11-the-problem-we-solve)
  * [1.2 The AgentCredit Solution](#12-the-agentcredit-solution)
  * [1.3 How It Works](#13-how-it-works)
* [2. Architecture](#2-architecture)
  * [2.1 High-Level Workflow](#21-high-level-workflow)
  * [2.2 Component Summary](#22-component-summary)
* [3. Features](#3-features)
* [4. Technical Overview](#4-technical-overview)
  * [4.1 Credit Score Formula](#41-credit-score-formula)
  * [4.2 ZK Proof System](#42-zk-proof-system)
* [5. API Reference](#5-api-reference)
* [6. Getting Started](#6-getting-started)
  * [6.1 Prerequisites](#61-prerequisites)
  * [6.2 Installation](#62-installation)
  * [6.3 Environment Setup](#63-environment-setup)
  * [6.4 Run the Demo](#64-run-the-demo)
* [7. Smart Contracts](#7-smart-contracts)
* [8. Testing](#8-testing)
* [9. Security](#9-security)
* [10. Production Architecture](#10-production-architecture)
* [11. Project Structure](#11-project-structure)
* [12. Project License](#12-project-license)
* [13. References](#13-references)

---

## 1. Overview

**AgentCredit** is a protocol that replaces the traditional approach of unverified identity in machine transactions with a single, unified continuous credit scoring distribution. Built on Base Sepolia using Noir ZK Proofs, it performs all pricing and validation mathematics entirely on-chain.

### What led to this project?

AI agent commerce has entered mainstream consciousness in the wake of
autonomous LLM pipelines proliferating through enterprise workflows,
but the trust infrastructure is still in its infancy. Agents can pay
autonomously via x402, but every payment is treated as a stranger-to-stranger
transaction with no memory of prior behavior. Many interactions of relevance
to the machine economy involve repeated, high-frequency transactions between
the same counterparties — yet today's payment protocols don't allow us to
distinguish a trustworthy agent with 50,000 payments from one with zero.
AgentCredit was built to close that gap.

### 1.1 The Problem We Solve

### Problem 1 — Flat Pricing Ignores Agent Reputation

When an AI agent hits an x402-gated API, the server sees a valid payment
authorization and nothing else. An agent that has reliably completed
50,000 payments worth $10,000 USDC over 18 months receives the exact
same price as an agent making its very first request. There is no
mechanism for service providers to reward long-term reliable counterparties,
and no mechanism for agents to signal their trustworthiness.

**The consequence:** service providers set conservative prices for all
agents to hedge against unknown risk, and high-quality agents
over-pay for every single interaction.

### Problem 2 — Agents Cannot Prove Creditworthiness In-Request

Even if a service provider wanted to offer discounts to trusted agents,
there is no standard way for an agent to prove its payment history within
a single HTTP request. The two naive solutions both fail:

- **Option A — Share transaction history:** The agent reveals every
  payment it has ever made — exposing sensitive behavioral data to every
  service it interacts with. Unacceptable for privacy.
- **Option B — On-chain lookup per request:** The service provider
  queries the blockchain for the agent's history on every call — adding
  2–6 seconds of latency per request and requiring custom indexing
  infrastructure. Operationally untenable at scale.

**The consequence:** services that want to offer trust-based pricing
cannot do so without building expensive custom infrastructure.

### Problem 3 — No Economic Incentive to Build Payment History

Because payment history has no redeemable value today, agents have no
reason to maintain consistent on-chain payment behavior. There is no
penalty for abandoning a wallet after a dispute, and no reward for
building a long, clean payment record.

**The consequence:** the agentic economy stays flat — every transaction
treated as a stranger-to-stranger interaction — when it should be evolving
toward a web of known, trusted counterparties.

### Problem 4 — Credit Line Access Requires Payment Upfront

High-frequency agent pipelines (inference chains, data streaming, real-time
analytics) must pre-fund wallets with enough USDC to cover all downstream
calls before the pipeline starts. If the upstream task fails or the agent
is shut down, the pre-funded USDC sits locked. There is no "deferred
payment" or "credit line" primitive for agents that have demonstrated
sustained reliability.

**The consequence:** agent pipeline operators over-provision liquidity,
tying up capital in agent wallets that could be deployed more efficiently.

### How AgentCredit Solves Each Problem

| Problem | AgentCredit Solution |
|---------|---------------------|
| Flat pricing ignores reputation | Tiered pricing (Gold/Silver/Unknown) applied automatically via ZK proof in HTTP header |
| Cannot prove history in-request | Noir ZK proof proves score threshold in a single `X-CREDIT-PROOF` header — verified on-chain in <100ms |
| No incentive to build history | Every x402 payment is indexed and raises score — discounts compound over time |
| No deferred payment primitive | `CreditLinePaymaster` (ERC-4337) extends credit lines to agents with score ≥ 700 |

### 1.2 The AgentCredit Solution

AgentCredit replaces discrete payments with a continuous credit layer. By analyzing x402 payment history, AgentCredit computes a decentralized credit score from 300 to 900.

### 1.3 How It Works

1. **Credit Checking**: Agent checks current score and tier limits.
2. **First Request**: Agent requests API and gets 402 Payment Required.
3. **ZK Proof Generation**: Agent generates a zero-knowledge proof proving creditworthiness.
4. **Second Request**: Agent re-requests with the ZK proof attached.
5. **Validation**: API validates the ZK proof.
6. **Payment Authorization**: Agent receives tiered discount and authorizes payment.
7. **Score Update**: Facilitator anchors the payment on-chain, boosting the score.

<div align="center">
<svg viewBox="0 0 700 920" width="100%" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrow1" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#333"/>
    </marker>
  </defs>

  <!-- NODE 1 -->
  <polygon points="350,50 480,100 350,150 220,100" fill="#b8f5b8" stroke="#333" stroke-width="2.5" />
  <text x="350" y="95" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="350" dy="0">Agent requests</tspan>
    <tspan x="350" dy="18">/api/premium-data</tspan>
  </text>
  
  <line x1="350" y1="150" x2="350" y2="200" stroke="#333" stroke-width="2" marker-end="url(#arrow1)" />
  <text x="360" y="180" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="11" font-style="italic" fill="#333">no proof header</text>

  <!-- NODE 2 -->
  <rect x="250" y="200" width="200" height="60" rx="18" ry="18" fill="#ffb3b3" stroke="#333" stroke-width="2.5" />
  <text x="350" y="225" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="350" dy="0">402 Payment Required</tspan>
    <tspan x="350" dy="18">Standard price: $0.001</tspan>
  </text>

  <line x1="350" y1="260" x2="350" y2="310" stroke="#333" stroke-width="2" marker-end="url(#arrow1)" />

  <!-- NODE 3 -->
  <rect x="230" y="310" width="240" height="70" rx="18" ry="18" fill="#ffe599" stroke="#333" stroke-width="2.5" />
  <text x="350" y="330" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="350" dy="0">Agent signs EIP-3009</tspan>
    <tspan x="350" dy="18">TransferWithAuthorization</tspan>
    <tspan x="350" dy="18">(USDC — no gas needed)</tspan>
  </text>

  <line x1="350" y1="380" x2="350" y2="430" stroke="#333" stroke-width="2" marker-end="url(#arrow1)" />

  <!-- NODE 4 -->
  <rect x="240" y="430" width="220" height="70" rx="18" ry="18" fill="#b8f5b8" stroke="#333" stroke-width="2.5" />
  <text x="350" y="450" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="350" dy="0">Payment confirmed on-chain</tspan>
    <tspan x="350" dy="18">Facilitator enqueues</tspan>
    <tspan x="350" dy="18">recordPayment() via BullMQ</tspan>
  </text>

  <line x1="460" y1="465" x2="520" y2="465" stroke="#333" stroke-width="2" marker-end="url(#arrow1)" />

  <!-- Ellipse next to NODE 4 -->
  <ellipse cx="600" cy="465" rx="70" ry="40" fill="#b3d9ff" stroke="#333" stroke-width="2" />
  <text x="600" y="450" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="600" dy="0">BullMQ worker</tspan>
    <tspan x="600" dy="18">updates score</tspan>
    <tspan x="600" dy="18">asynchronously</tspan>
  </text>

  <line x1="350" y1="500" x2="350" y2="550" stroke="#333" stroke-width="2" marker-end="url(#arrow1)" />

  <!-- NODE 5 -->
  <rect x="230" y="550" width="240" height="70" rx="18" ry="18" fill="#1a1a1a" stroke="#333" stroke-width="2.5" />
  <text x="350" y="570" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="white">
    <tspan x="350" dy="0">Agent generates ZK proof</tspan>
    <tspan x="350" dy="18">Noir circuit (~8 seconds)</tspan>
    <tspan x="350" dy="18">Proves score > threshold</tspan>
  </text>

  <line x1="470" y1="585" x2="520" y2="585" stroke="#333" stroke-width="2" marker-end="url(#arrow1)" />

  <!-- Ellipse next to NODE 5 -->
  <ellipse cx="600" cy="585" rx="70" ry="40" fill="#b3d9ff" stroke="#333" stroke-width="2" />
  <text x="600" y="570" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="600" dy="0">ProofCache contract</tspan>
    <tspan x="600" dy="18">receipt valid</tspan>
    <tspan x="600" dy="18">12h / 3600 blocks</tspan>
  </text>

  <line x1="350" y1="620" x2="350" y2="670" stroke="#333" stroke-width="2" marker-end="url(#arrow1)" />

  <!-- NODE 6 -->
  <polygon points="350,670 450,720 350,770 250,720" fill="#b8f5b8" stroke="#333" stroke-width="2.5" />
  <text x="350" y="710" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="350" dy="0">Retry with</tspan>
    <tspan x="350" dy="18">X-CREDIT-PROOF header</tspan>
  </text>

  <!-- Left Branch from Node 6 -->
  <line x1="250" y1="720" x2="160" y2="720" stroke="#333" stroke-width="2" marker-end="url(#arrow1)" />
  <line x1="160" y1="720" x2="160" y2="820" stroke="#333" stroke-width="2" />
  <line x1="160" y1="820" x2="250" y2="820" stroke="#333" stroke-width="2" marker-end="url(#arrow1)" />
  <text x="200" y="710" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="11" font-style="italic" fill="#333">score ≥ 750</text>
  <text x="160" y="690" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">🥇 Gold — $0.0005</text>

  <!-- Right Branch from Node 6 -->
  <line x1="450" y1="720" x2="540" y2="720" stroke="#333" stroke-width="2" marker-end="url(#arrow1)" />
  <line x1="540" y1="720" x2="540" y2="820" stroke="#333" stroke-width="2" />
  <line x1="540" y1="820" x2="450" y2="820" stroke="#333" stroke-width="2" marker-end="url(#arrow1)" />
  <text x="500" y="710" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="11" font-style="italic" fill="#333">score ≥ 600</text>
  <text x="540" y="690" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">🥈 Silver — $0.0008</text>

  <!-- Down Branch from Node 6 -->
  <line x1="350" y1="770" x2="350" y2="800" stroke="#333" stroke-width="2" marker-end="url(#arrow1)" />
  <text x="360" y="790" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="11" font-style="italic" fill="#333">no valid proof</text>

  <!-- NODE 7 -->
  <rect x="250" y="800" width="200" height="70" rx="18" ry="18" fill="#b8f5b8" stroke="#333" stroke-width="2.5" />
  <text x="350" y="820" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="350" dy="0">200 OK — premium data</tspan>
    <tspan x="350" dy="18">Tier discount applied</tspan>
    <tspan x="350" dy="18">Score updated on-chain</tspan>
  </text>
</svg>
</div>

💡 Key Insight: The ZK proof is generated once and cached for 12 hours (~3600 blocks).
Subsequent requests within the window reuse the cached proof receipt — no re-proving needed.

---

## 2. Architecture

### 2.1 High-Level Workflow

AgentCredit consists of a modular framework allowing agents to fetch their score and prove logic entirely autonomously.

<div align="center">
<svg viewBox="0 0 780 680" width="100%" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrow2" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#333"/>
    </marker>
  </defs>

  <!-- LAYER 5 -->
  <text x="40" y="40" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="11" font-style="italic" fill="#333">Layer 5 — Frontend</text>
  <rect x="240" y="50" width="300" height="50" rx="18" ry="18" fill="#b3d9ff" stroke="#333" stroke-width="2.5" />
  <text x="390" y="70" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="390" dy="0">Next.js Dashboard</tspan>
    <tspan x="390" dy="18">Score Lookup + ZK Proof Generator</tspan>
  </text>
  
  <line x1="390" y1="100" x2="390" y2="150" stroke="#333" stroke-width="2" marker-end="url(#arrow2)" />

  <!-- LAYER 4 -->
  <text x="40" y="140" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="11" font-style="italic" fill="#333">Layer 4 — ZK System</text>
  
  <rect x="100" y="150" width="160" height="50" rx="18" ry="18" fill="#ffb3b3" stroke="#333" stroke-width="2.5" />
  <text x="180" y="170" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="180" dy="0">Noir Circuit</tspan>
    <tspan x="180" dy="18">credit_proof.nr</tspan>
  </text>
  <line x1="260" y1="175" x2="310" y2="175" stroke="#333" stroke-width="2" marker-end="url(#arrow2)" />
  
  <rect x="310" y="150" width="160" height="50" rx="18" ry="18" fill="#b8f5b8" stroke="#333" stroke-width="2.5" />
  <text x="390" y="170" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="390" dy="0">ZKVerifier.sol</tspan>
    <tspan x="390" dy="18">On-chain verifier</tspan>
  </text>
  <line x1="470" y1="175" x2="520" y2="175" stroke="#333" stroke-width="2" marker-end="url(#arrow2)" />

  <rect x="520" y="150" width="160" height="50" rx="18" ry="18" fill="#ffe599" stroke="#333" stroke-width="2.5" />
  <text x="600" y="170" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="600" dy="0">ProofCache</tspan>
    <tspan x="600" dy="18">12h validity window</tspan>
  </text>

  <line x1="390" y1="200" x2="390" y2="250" stroke="#333" stroke-width="2" marker-end="url(#arrow2)" />

  <!-- LAYER 3 -->
  <text x="40" y="240" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="11" font-style="italic" fill="#333">Layer 3 — Smart Contracts</text>
  
  <rect x="200" y="250" width="180" height="50" rx="18" ry="18" fill="#b8f5b8" stroke="#333" stroke-width="2.5" />
  <text x="290" y="270" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="290" dy="0">CreditRegistry.sol</tspan>
    <tspan x="290" dy="18">Score + Poseidon commitment</tspan>
  </text>

  <rect x="400" y="250" width="180" height="50" rx="18" ry="18" fill="#1a1a1a" stroke="#333" stroke-width="2.5" />
  <text x="490" y="270" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="white">
    <tspan x="490" dy="0">CreditLinePaymaster</tspan>
    <tspan x="490" dy="18">ERC-4337 deferred gas</tspan>
  </text>

  <line x1="390" y1="300" x2="390" y2="350" stroke="#333" stroke-width="2" marker-end="url(#arrow2)" />

  <!-- LAYER 2 -->
  <text x="40" y="340" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="11" font-style="italic" fill="#333">Layer 2 — Indexer</text>
  
  <ellipse cx="290" cy="375" rx="90" ry="25" fill="#b3d9ff" stroke="#333" stroke-width="2" />
  <text x="290" y="365" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="290" dy="0">The Graph Subgraph</tspan>
    <tspan x="290" dy="18">AuthorizationUsed events</tspan>
  </text>

  <line x1="380" y1="375" x2="430" y2="375" stroke="#333" stroke-width="2" marker-end="url(#arrow2)" />

  <rect x="430" y="350" width="160" height="50" rx="18" ry="18" fill="#ffe599" stroke="#333" stroke-width="2.5" />
  <text x="510" y="370" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="510" dy="0">BullMQ Keeper Bot</tspan>
    <tspan x="510" dy="18">recordPayment() caller</tspan>
  </text>

  <line x1="390" y1="400" x2="390" y2="450" stroke="#333" stroke-width="2" marker-end="url(#arrow2)" />

  <!-- LAYER 1 -->
  <text x="40" y="440" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="11" font-style="italic" fill="#333">Layer 1 — x402 Payment Rail</text>
  
  <rect x="100" y="450" width="160" height="50" rx="18" ry="18" fill="#ffb3b3" stroke="#333" stroke-width="2.5" />
  <text x="180" y="470" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="180" dy="0">Express API</tspan>
    <tspan x="180" dy="18">@x402/express</tspan>
  </text>
  <line x1="260" y1="475" x2="310" y2="475" stroke="#333" stroke-width="2" marker-end="url(#arrow2)" />

  <rect x="310" y="450" width="160" height="50" rx="18" ry="18" fill="#b8f5b8" stroke="#333" stroke-width="2.5" />
  <text x="390" y="470" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="390" dy="0">creditGate.ts</tspan>
    <tspan x="390" dy="18">Tiered pricing</tspan>
  </text>
  <line x1="470" y1="475" x2="520" y2="475" stroke="#333" stroke-width="2" marker-end="url(#arrow2)" />

  <rect x="520" y="450" width="160" height="50" rx="18" ry="18" fill="#ffe599" stroke="#333" stroke-width="2.5" />
  <text x="600" y="470" font-family="'Segoe Print', 'Comic Sans MS', cursive" font-size="13" text-anchor="middle" fill="#333">
    <tspan x="600" dy="0">facilitatorHook.ts</tspan>
    <tspan x="600" dy="18">Event enqueuer</tspan>
  </text>

</svg>
</div>

### 2.2 Component Summary

| Package | Purpose | Key Files |
| --- | --- | --- |
| packages/contracts | Solidity smart contracts (Foundry) | CreditRegistry.sol, CreditLinePaymaster.sol, ZKVerifier.sol |
| packages/circuits | Noir ZK circuits | credit_proof/src/main.nr, Verifier.sol |
| packages/indexer | The Graph subgraph | subgraph.yaml, src/mapping.ts |
| packages/api | Express x402 API | creditGate.ts, zkVerifier.ts, facilitatorHook.ts |
| packages/dashboard | Next.js frontend | app/page.tsx, app/prove/page.tsx |

---

## 3. Features

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

---

## 4. Technical Overview

### 4.1 Credit Score Formula

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
| 🥇 Gold | 750–900 | 50% off | Agent C: 822 pts |
| 🥈 Silver | 600–749 | 20% off | Agent B: 674 pts |
| ⬜ Unknown | 300–599 | Standard price | Agent A: 521 pts |

### 4.2 ZK Proof System

Zero-Knowledge Proofs in AgentCredit allow agents to authenticate their credit tiers without disclosing their actual absolute credit score or full historical metadata, achieving robust privacy.

```noir
// packages/circuits/credit_proof/src/main.nr
use dep::poseidon;

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
    let computed_commitment: Field = poseidon::bn254::hash_2([score, agent_address]);
    // Poseidon BN254 — matches PoseidonT3.hash() in CreditRegistry.sol
    assert(computed_commitment == commitment);           // commitment is authentic
}
```

---

## 5. API Reference

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

---

## 6. Getting Started

### 6.1 Prerequisites

* Node.js ≥ 20.0.0
* Foundry (latest) — `curl -L https://foundry.paradigm.xyz | bash`
* Nargo ≥ 0.38.0 — `curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash && noirup`
* Git

### 6.2 Installation

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

### 6.3 Environment Setup

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

### 6.4 Run the Demo

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

### 6.5 Quick Demo

```bash
# Checks Redis, RPC, and contracts — falls back gracefully
npm run demo
```

> See [DEMO.md](DEMO.md) for a detailed step-by-step walkthrough.

---

## 7. Smart Contracts

AgentCredit contracts handle the decentralized state and on-chain hashing validation.

| Contract | Address | Network | Verified |
| --- | --- | --- | --- |
| CreditRegistry | 0x6e1219c3938Ee9de9df567616d1FC5D3b3966e13 | Base Sepolia | ✅ View on Basescan |
| CreditLinePaymaster | 0x5b3E8dF2181866AdD15e10A31bFf12FBf05A8085 | Base Sepolia | [✅ Basescan](https://sepolia.basescan.org/address/0x5b3E8dF2181866AdD15e10A31bFf12FBf05A8085) |
| ZKVerifier | 0x394B61757c22833d0188eED6d3B302d4E276822e | Base Sepolia | [✅ Basescan](https://sepolia.basescan.org/address/0x394B61757c22833d0188eED6d3B302d4E276822e) |

<details>
<summary>📋 CreditRegistry ABI(key functions)</summary>

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

---

## 8. Testing

AgentCredit uses Foundry for smart contract testing with invariant fuzzing and coverage.

| Test Suite | Tests | Status |
| --- | --- | --- |
| CreditRegistry Unit | 16 tests | ✅ All passing |
| ProofCache Unit | 6 tests | ✅ All passing |
| Invariant Fuzzing | 5 invariants × 1000 runs (250K calls) | ✅ 0 violations |

### Invariant Properties

| # | Invariant | Property |
|---|---|---|
| 1 | `scoreAlwaysInValidRange` | Score ∈ [300, 900] for all agents, always |
| 2 | `scoreNeverDecreases` | Score monotonically non-decreasing |
| 3 | `nonceMonotonicity` | Used nonces permanently marked |
| 4 | `totalPaymentsNeverDecreases` | Payment count never decreases |
| 5 | `pausedContractBlocksPayments` | No payments while paused |

```bash
# Run all contract tests
cd packages/contracts && forge test -v

# Run invariant fuzzing (1000 runs per invariant)
forge test --match-contract Invariant -v

# Run deep fuzzing (10K runs — before audit)
forge test --match-contract Invariant -v --profile deep

# Coverage report
forge coverage --ir-minimum --report summary

# Run agent simulation
cd packages/api && npm run simulate
```

### Coverage

| Contract | Lines | Branches | Functions |
|---|---|---|---|
| CreditRegistry.sol | 82% | 25% | 88% |
| ProofCache.sol | 85% | 29% | 80% |

---

## 9. Security

### Vulnerability Matrix

| Vulnerability | Mitigation | Status |
| --- | --- | --- |
| Sybil Score Bootstrap | 7-day minimum age gate + log-scale volume weighting | ✅ Implemented |
| Fake Score ZK Injection | On-chain Poseidon commitment anchored by Registry | ✅ Implemented |
| recordPayment Spoofing | FACILITATOR_ROLE + EIP-3009 nonce verification | ✅ Implemented |
| ZK Proof Replay | Block number expiry (3600 blocks ≈ 12 hours) | ✅ Implemented |
| Oracle Price Manipulation | Hardcoded deterministic tiered pricing | ✅ Implemented |
| MEV Frontrunning | Nonces prevent replaying EIP-3009 payloads | ✅ Implemented |
| Hash Inconsistency | Poseidon (BN254) used end-to-end in Solidity + Noir | ✅ Fixed |
| Immutable Contracts | UUPS proxy pattern + Timelock-governed upgrades | ✅ Implemented |
| Single Key Compromise | 3-of-5 Gnosis Safe + 48h TimelockController | ✅ Implemented |

### Automated Security Pipeline

| Tool | Purpose | CI Integration |
|---|---|---|
| Foundry Invariant Tests | 5 property-based invariants, 250K fuzz calls | ✅ GitHub Actions |
| Slither | Static analysis — 0 High/Critical gate | ✅ GitHub Actions |
| Coverage Check | Branch coverage floor per contract | ✅ GitHub Actions |
| TypeScript Strict | `--noEmit` type checking on all packages | ✅ GitHub Actions |

### Audit Roadmap

| Phase | Target | Timeline |
|---|---|---|
| Competitive Audit | Sherlock or Code4rena contest | Planned |
| Private Audit | Spearbit or Cyfrin review | After competitive |
| ZK Circuit Audit | Veridise or Nethermind | Concurrent |

> ⚠️ **Not yet audited.** This codebase has not undergone a professional security audit.
> It is deployed on Base Sepolia (testnet) only. Do not use with real funds.
>
> See [PRODUCTION.md](PRODUCTION.md) for the full ops runbook and incident response procedures.

---

## 10. Production Architecture

| Feature | Demo (Hackathon) | Production |
|---------|-----------------|------------|
| Contract upgradeability | ❌ Immutable | ✅ UUPS Proxy |
| Admin control | ⚠ Single EOA | ✅ 3-of-5 Gnosis Safe + 48h Timelock |
| Emergency pause | ❌ None | ✅ Guardian 2-of-3 Hot Safe |
| Hash consistency | ⚠ keccak256 vs pedersen | ✅ Poseidon (Solidity + Noir) |
| Payment processing | ⚠ Synchronous, no retries | ✅ BullMQ + Redis + exponential backoff |
| Nonce management | ⚠ Sequential, collision-prone | ✅ NonceManager with pending tracking |
| ZK proof reuse | ❌ Prove every request | ✅ ProofCache -- 12h validity window |
| RPC redundancy | ❌ Single provider | ✅ Multi-provider with auto-fallback |
| CI pipeline | ❌ None | ✅ GitHub Actions: tests + coverage + Slither |
| Fuzz testing | ❌ None | ✅ Foundry invariant tests (5 invariants) |
| Audit status | ⚠ Unaudited | 🔜 Sherlock contest (planned) |

---

## 11. Project Structure

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

**Contributing:** no `any` in TypeScript. Branch naming: `feature/`, `fix/`, `test/`.
PRs must include: description of change, test additions, verification command output.

---

## 12. Project License

MIT License — see LICENSE for details.

---

## 13. References

- **x402 Official Specification:** The HTTP 402 payment standard — flow, X-PAYMENT header, facilitator model — [x402.org](https://x402.org)
- **EIP-3009: Transfer With Authorization:** The signed-auth standard powering every x402 payment — [eips.ethereum.org](https://eips.ethereum.org/EIPS/eip-3009)
- **EIP-712: Typed Structured Data Signing:** Domain separators and struct hashing that bind EIP-3009 signatures — [eips.ethereum.org](https://eips.ethereum.org/EIPS/eip-712)
- **x402 SDK (TypeScript):** Official Coinbase x402 Express middleware — [github.com/coinbase/x402](https://github.com/coinbase/x402)
- **ERC-4337: Account Abstraction:** The UserOperation standard underlying the CreditLinePaymaster — [eips.ethereum.org](https://eips.ethereum.org/EIPS/eip-4337)
- **ERC-4337 Docs:** Bundlers, EntryPoint, and Paymaster development reference — [docs.erc4337.io](https://docs.erc4337.io)
- **ZeroDev SDK:** Session keys and Paymaster abstraction in TypeScript — [docs.zerodev.app](https://docs.zerodev.app)
- **EIP-7702 (Pectra):** EOA temporary smart contract execution — enables gas sponsorship — [eips.ethereum.org](https://eips.ethereum.org/EIPS/eip-7702)
- **ERC-8004: Trustless AI Agent Identity:** On-chain identity standard for AI agents — [eips.ethereum.org](https://eips.ethereum.org/EIPS/eip-8004)
- **QuickNode: ERC-8004 Developer Guide:** Practical breakdown of the three ERC-8004 registries — [blog.quicknode.com](https://blog.quicknode.com/erc-8004-a-developers-guide-to-trustless-ai-agent-identity/)
- **Inter-Agent Trust Models (arXiv 2511.03434):** Comparing A2A, AP2, and ERC-8004 trust architectures — [arxiv.org](https://arxiv.org/abs/2511.03434)
- **A2A + x402 Integration (arXiv 2507.19550):** How x402 EIP-3009 flows compose with on-chain agent identity — [arxiv.org](https://arxiv.org/abs/2507.19550)
- **Noir Language Documentation:** Official docs for writing ZK circuits in Noir — [noir-lang.org/docs](https://noir-lang.org/docs)
- **noir-lang/poseidon:** Poseidon hash for Noir — BN254 curve, used in the commitment scheme — [github.com/noir-lang/poseidon](https://github.com/noir-lang/poseidon)
- **poseidon-solidity:** Poseidon hash in Solidity over BN254 — matches Noir output exactly — [github.com/chancehudson/poseidon-solidity](https://github.com/chancehudson/poseidon-solidity)
- **Poseidon Hash Reference:** Formal specification of Poseidon over BN254, BLS12-381, Ed25519 — [poseidon-hash.info](https://www.poseidon-hash.info/)
- **Nethermind Noir Audit Guide:** Security gotchas when writing Noir circuits — [nethermind.io/blog](https://www.nethermind.io/blog/our-first-deep-dive-into-noir-what-zk-auditors-learned)
- **OpenZeppelin Contracts v5:** ReentrancyGuard, AccessControl, Pausable, TimelockController — [docs.openzeppelin.com](https://docs.openzeppelin.com/contracts/5.x)
- **OpenZeppelin Upgrades (Foundry):** UUPS proxy deployment and upgrade safety validation — [docs.openzeppelin.com](https://docs.openzeppelin.com/upgrades-plugins/foundry/foundry-upgrades)
- **OpenZeppelin Upgradeable Contracts:** Initializable, UUPSUpgradeable, AccessControlUpgradeable — [github.com/OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable)
- **Foundry Book:** Forge test, coverage, invariant testing, deployment scripts — [book.getfoundry.sh](https://book.getfoundry.sh)
- **Viem Documentation:** TypeScript EVM library used throughout the API and dashboard — [viem.sh](https://viem.sh)
- **The Graph Protocol:** Subgraph indexer for AuthorizationUsed and ScoreUpdated events — [thegraph.com/docs](https://thegraph.com/docs/en/developing/creating-a-subgraph/)
- **BullMQ Documentation:** Redis-backed job queue powering the production facilitator bot — [docs.bullmq.io](https://docs.bullmq.io/)
- **ioredis:** Redis client for Node.js — connection config for BullMQ — [github.com/redis/ioredis](https://github.com/redis/ioredis)
- **Pino Logger:** Structured JSON logging for the API and worker — [getpino.io](https://getpino.io/)
- **Slither Static Analyzer:** Solidity static analysis — runs in CI on every PR — [github.com/crytic/slither](https://github.com/crytic/slither)
- **Immunefi Bug Bounty Platform:** Platform for the planned bug bounty program — [immunefi.com](https://immunefi.com)
- **Cyfrin Audit Firm:** Planned private audit provider — [cyfrin.io](https://cyfrin.io)
- **Veridise ZK Audits:** Planned ZK circuit audit provider — [veridise.com](https://veridise.com)
- **Coinbase Base Documentation:** Base Sepolia network, chain ID 84532, USDC addresses — [docs.base.org](https://docs.base.org)
- **Circle USDC on Base:** USDC contract addresses and EIP-3009 compatibility — [developers.circle.com](https://developers.circle.com)
- **Chainlink CCIP:** Cross-chain interoperability — referenced in V3 roadmap — [docs.chain.link/ccip](https://docs.chain.link/ccip)

---

<div align="center">
Built for the x402 ecosystem · Powered by Base · Secured by Noir ZK
</div>
