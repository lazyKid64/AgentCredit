# AgentCredit Integration Guide

This guide explains how to integrate the AgentCredit protocol into your applications. There are two primary perspectives for integration:
1. **Service Providers:** How to protect your APIs and offer tiered pricing using the x402 Credit Gate.
2. **AI Agents:** How to generate zero-knowledge proofs and attach them to HTTP requests to claim discounted pricing.

---

## 1. For Service Providers (API Servers)

If you are a service provider hosting a premium endpoint (like an LLM inference node or proprietary data feed), you can easily add AgentCredit's tiered pricing using our Express middleware.

### Installation

Ensure you have the core x402 packages and our credit gate middleware available in your Node.js project:

```bash
npm install @x402/express @agentcredit/api viem
```

### Server Integration

Wrap your premium endpoints with the `creditGate` middleware **before** the standard `x402` middleware. The `creditGate` will automatically intercept incoming ZK proofs, verify them against the `ZKVerifier` smart contract (or `ProofCache`), and set a discounted price requirement.

```typescript
import express from 'express';
import { x402 } from '@x402/express';
import { creditGate } from '@agentcredit/api/creditGate';

const app = express();

// 1. creditGate checks for X-CREDIT-PROOF, verifies the ZK math, and sets tiered pricing.
// 2. x402() enforces the 402 Payment Required handshake based on that price.
app.get('/api/llm-inference', creditGate, x402(), (req, res) => {
    
    // If execution reaches here, the agent has successfully paid!
    // The price they paid was dynamically determined by their ZK credit proof.
    
    res.json({
        data: "Here is your premium LLM inference result.",
        tier_applied: req.creditTier // E.g., 'gold', 'silver', or 'unknown'
    });
});

app.listen(3000, () => console.log('Premium API running on port 3000'));
```

### Recording Payments (Score Growth)

To ensure your agents' credit scores grow over time, you must report successful x402 payments back to the `CreditRegistry` smart contract.

We recommend enqueuing these on-chain transactions asynchronously (e.g., using BullMQ) to avoid slowing down the API response time.

```typescript
import { recordPayment } from '@agentcredit/api/facilitatorHook';

// Inside your x402 payment success webhook or facilitator hook
async function onPaymentSuccess(agentAddress, amountUSD) {
    // Submit the payment record to the Base Sepolia testnet
    await recordPayment(agentAddress, amountUSD);
}
```

---

## 2. For AI Agents (Clients)

If you are an AI agent, you want to prove your high credit score to receive discounts without revealing your entire transaction history. You achieve this by generating a Noir Zero-Knowledge proof locally.

### Installation

You need the Noir JS library and the Barretenberg backend to generate proofs.

```bash
npm install @noir-lang/noir_js @noir-lang/backend_barretenberg viem
```

### Client Integration

Before hitting a premium API, the agent must generate the proof and send it in the headers.

```typescript
import { Noir } from '@noir-lang/noir_js';
import { BarretenbergBackend } from '@noir-lang/backend_barretenberg';
import { createPublicClient, http } from 'viem';
import { baseSepolia } from 'viem/chains';
import circuit from '@agentcredit/circuits/target/credit_proof.json';

const publicClient = createPublicClient({ chain: baseSepolia, transport: http() });

async function fetchPremiumData(agentAddress, agentPrivateKey, actualScore) {
    // 1. Fetch your on-chain commitment from the CreditRegistry
    const registryAddress = "0x6e1219c3938Ee9de9df567616d1FC5D3b3966e13";
    const commitment = await publicClient.readContract({
        address: registryAddress,
        abi: CREDIT_REGISTRY_ABI,
        functionName: 'getCommitment',
        args: [agentAddress]
    });

    // 2. Generate the ZK Proof locally
    const backend = new BarretenbergBackend(circuit);
    const noir = new Noir(circuit, backend);
    
    // We are proving "My score is >= 750" (Gold Tier)
    const input = {
        score: actualScore,         // Private input
        threshold: 750,             // Public input
        agent_address: agentAddress,// Public input
        commitment: commitment      // Public input
    };

    console.log("Generating ZK Proof...");
    const { proof } = await noir.generateFinalProof(input);
    const base64Proof = Buffer.from(proof).toString('base64');

    // 3. Make the API request with the proof attached
    const response = await fetch('http://localhost:3000/api/llm-inference', {
        headers: {
            'X-CREDIT-PROOF': base64Proof
        }
    });

    // 4. The server will return a 402 with the DISCOUNTED price
    if (response.status === 402) {
        console.log("Discount secured! Proceeding with x402 payment flow...");
        // Handle standard x402 EIP-3009 payment signature here
    }
}
```

---

## 3. Credit Line Paymaster Integration (ERC-4337)

High-tier agents (Score ≥ 700) can utilize the `CreditLinePaymaster` to have their gas fees sponsored on Base. 

Instead of submitting standard Ethereum transactions that require holding native ETH, the agent wraps their transactions into **UserOperations** and submits them via a bundler (e.g., using the ZeroDev SDK or viem's account abstraction utilities).

Point your Paymaster configuration to the deployed contract:
* **Base Sepolia Paymaster:** `0x5b3E8dF2181866AdD15e10A31bFf12FBf05A8085`

If your agent's score is sufficiently high, the Paymaster will automatically validate and sponsor your transaction's gas costs.

---

## 4. What Happens After Integration?

Once the AgentCredit protocol is integrated into your workflow, the interactions between AI Agents and Service Providers fundamentally change. Here is what you will observe in production:

### For Service Providers (API Owners)
- **Automated Price Discrimination:** Your API will automatically return different pricing in the HTTP `402` response based on the agent's cryptographic proof. You no longer have to price defensively for the worst-case user.
- **Instant Cryptographic Trust:** You don't need to query an external database or make blocking RPC calls during the HTTP handshake. The ZK Proof is validated mathematically via the `ZKVerifier` or instantly via the `ProofCache`, adding practically zero latency to your request lifecycle.
- **Attracting High-Value Agents:** High-volume agents will explicitly seek out AgentCredit-compatible endpoints because they know their reputation earns them a 20% to 50% discount. This drives more reliable, high-quality traffic to your services.

### For AI Agents (Clients)
- **Compounding Reputation:** Every time your agent pays for an API successfully, the server enqueues a `recordPayment` transaction. Over time, your agent's on-chain score will mathematically grow based on payment volume and consistency.
- **Reduced Capital Requirements:** Reaching the Gold Tier (Score ≥ 750) means your agent pays 50% less for API calls. Furthermore, reaching a score of 700 unlocks the `CreditLinePaymaster`, allowing your agent to execute complex smart contract operations without needing to hold upfront ETH for gas.
- **Complete Privacy:** Because the proof is Zero-Knowledge (Noir UltraPlonk), the API provider only learns that your score is "greater than X". They **never** learn your exact score, your total transaction volume, or what other APIs you use.
