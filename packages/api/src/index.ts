import dotenv from 'dotenv';
dotenv.config({ path: '../../.env' });

import express, { Request, Response } from 'express';
import { createPublicClient, http, parseAbi, type Hex } from 'viem';
import { baseSepolia } from 'viem/chains';
import { paymentMiddlewareFromConfig } from '@x402/express';
import { ExactEvmScheme } from '@x402/evm/exact/server';
import { creditGate, TIER_PRICES, type CreditRequest, type CreditTier } from './creditGate';

const CREDIT_REGISTRY_ABI = parseAbi([
  'function getScore(address agent) external view returns (uint256)',
]);

const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http(process.env.RPC_URL),
});

const registryAddress = process.env.CREDIT_REGISTRY_ADDRESS as Hex;
const payToAddress = process.env.USDC_ADDRESS as Hex;

function getTierFromScore(score: number): CreditTier {
  if (score >= 750) return 'gold';
  if (score >= 600) return 'silver';
  return 'unknown';
}

const app = express();
app.use(express.json());

// ---------- Route: GET /api/score/:address ----------
app.get('/api/score/:address', async (req: Request, res: Response) => {
  try {
    const agentAddress = req.params.address as Hex;

    const score = await publicClient.readContract({
      address: registryAddress,
      abi: CREDIT_REGISTRY_ABI,
      functionName: 'getScore',
      args: [agentAddress],
    });

    const scoreNum = Number(score);
    const tier = getTierFromScore(scoreNum);

    res.json({
      address: agentAddress,
      score: scoreNum,
      tier,
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    console.error('[score] Error:', message);
    res.status(500).json({ error: message });
  }
});

// ---------- Route: GET /api/premium-data (x402 protected) ----------
const premiumRoutes = {
  'GET /api/premium-data': {
    accepts: {
      scheme: 'exact' as const,
      payTo: payToAddress || '0x0000000000000000000000000000000000000000',
      price: '$0.001',
      network: 'eip155:84532' as const,
    },
    description: 'Premium market data secured by x402 protocol with credit-aware pricing',
  },
};

const evmScheme = new ExactEvmScheme();

app.use(
  paymentMiddlewareFromConfig(
    premiumRoutes,
    undefined,
    [{ network: 'eip155:84532' as const, server: evmScheme }],
  )
);

app.get(
  '/api/premium-data',
  creditGate,
  (req: Request, res: Response) => {
    const creditReq = req as CreditRequest;
    const tier = creditReq.creditTier || 'unknown';
    const price = TIER_PRICES[tier];

    res.json({
      data: 'premium market data secured by x402',
      tier,
      price,
      timestamp: Date.now(),
    });
  }
);

// ---------- Health check ----------
app.get('/api/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    registry: registryAddress,
    network: 'base-sepolia',
    tiers: TIER_PRICES,
  });
});

// ---------- Start Server ----------
const PORT = parseInt(process.env.PORT || '3000', 10);
app.listen(PORT, () => {
  console.log(`[AgentCredit API] Running on http://localhost:${PORT}`);
  console.log(`[AgentCredit API] CreditRegistry: ${registryAddress}`);
  console.log(`[AgentCredit API] Tier pricing: Gold=$${TIER_PRICES.gold} Silver=$${TIER_PRICES.silver} Unknown=$${TIER_PRICES.unknown}`);
});
