# AgentCredit Protocol — Demo Guide

## What This Demo Shows

A complete end-to-end demonstration of the AgentCredit Protocol:
an AI agent builds a credit score through x402 payments, generates a
zero-knowledge proof of its score, and receives a **20% price discount**
on subsequent API calls — without revealing its payment history.

---

## Quick Demo (3 minutes)

### Prerequisites

- **Node.js** ≥ 20
- A **Base Sepolia wallet** with test ETH ([get from faucet](https://faucet.coinbase.com/faucets/base-ethereum-sepolia-faucet))
- Clone this repo and run `npm install`
- Copy `.env.example` to `.env` and fill in `RPC_URL` and `AGENT_PRIVATE_KEY`

### Run It

```bash
# Start the API server
cd packages/api && npm start &

# Run the demo (Redis optional — will use lite mode without it)
npm run demo
```

> **Tip**: Redis is optional. Without it, the demo runs in LITE mode (synchronous payment processing). With Redis, you get the full BullMQ async queue experience.

---

## What You'll See

The demo prints numbered steps. Each step shows one part of the protocol:

| Step | What Happens | Time |
|------|-------------|------|
| **[1]** | Read agent's current score from CreditRegistry on Base Sepolia | ~1s |
| **[2]** | Hit `/api/premium-data` with no payment — receive 402 at full price | ~1s |
| **[3]** | Sign EIP-3009 USDC transfer — no gas needed from agent | ~1s |
| **[4]** | Pay via x402 — receive 200 with premium data | ~2s |
| **[5]** | Queue payment event for async score update (BullMQ) | instant |
| **[6]** | Read Poseidon commitment from CreditRegistry | ~1s |
| **[7]** | Generate ZK proof: "my score ≥ 500 → Silver" (Noir circuit) | ~8s |
| **[7b]** | Submit proof to ProofCache — cached for 12 hours | ~2s |
| **[8]** | Retry with proof in `X-CREDIT-PROOF` header — Silver pricing | ~1s |

### Example Output

```
╔══════════════════════════════════════════════╗
║   DEMO COMPLETE                               ║
╠══════════════════════════════════════════════╣
║   Agent:          0x3C44Cd...70997970         ║
║   Credit Score:   302                         ║
║   Hash Function:  Poseidon (BN254)            ║
║   Queue:          BullMQ (Redis-backed)       ║
║   Standard Price: $0.0010                     ║
║   Silver Price:   $0.0008                     ║
║   Discount:       20%                         ║
║   Proof Cache:    12h validity (3600 blocks)  ║
╚══════════════════════════════════════════════╝
```

---

## Dashboard Demo

```bash
cd packages/dashboard && npm run dev
```

Open **http://localhost:3000**

- Enter any agent address to see their score and tier
- Click **"Prove"** to generate a ZK proof in the browser (~8-12 seconds)
- Watch the proof generate in real-time with a live timer

---

## Seeded Test Agents

These agents were pre-seeded during deployment for demo purposes:

| Agent | Address | Payments | Approx Score | Tier |
|-------|---------|----------|------|------|
| Agent A | `0xaAaA...AaaAa` | 50 | ~520 | Unknown |
| Agent B | `0xbBbB...bBbBb` | 200 | ~680 | Silver |
| Agent C | `0xcCcC...cCcCc` | 800 | ~820 | Gold |

---

## Verifying On-Chain

Every part of this demo is verifiable on Basescan:

- **CreditRegistry**: [View on Basescan](https://sepolia.basescan.org/address/0x6e1219c3938Ee9de9df567616d1FC5D3b3966e13)

```bash
# Check any agent's score directly from the contract
cast call 0x6e1219c3938Ee9de9df567616d1FC5D3b3966e13 \
  "getScore(address)(uint256)" \
  0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa \
  --rpc-url https://sepolia.base.org

# Check any agent's ZK commitment (Poseidon hash)
cast call 0x6e1219c3938Ee9de9df567616d1FC5D3b3966e13 \
  "getCommitment(address)(bytes32)" \
  0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa \
  --rpc-url https://sepolia.base.org
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `RPC: cannot connect` | Set `RPC_URL` in `.env` to a valid Base Sepolia endpoint |
| `Redis: not running` | Demo still works in LITE mode. For FULL mode: install and start Redis |
| `402 but no discount` | Agent needs payments first. Run demo multiple times to build score |
| `ZK proof takes >30s` | First proof is slower (WASM compilation). Subsequent proofs are ~8s |
| `Dashboard won't start` | Run `npm install` in `packages/dashboard` first |
