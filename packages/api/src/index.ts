import dotenv from 'dotenv';
dotenv.config({ path: '../../.env' });

import express, { Request, Response, NextFunction } from 'express';
import { createPublicClient, http, parseAbi, type Hex, keccak256, encodePacked } from 'viem';
import { baseSepolia } from 'viem/chains';
import { creditGate, TIER_PRICES, type CreditRequest, type CreditTier } from './creditGate';
import { recordPayment } from './facilitatorHook';

const CREDIT_REGISTRY_ABI = parseAbi([
  'function getScore(address agent) external view returns (uint256)',
]);

const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http(process.env.RPC_URL),
});

const registryAddress = process.env.CREDIT_REGISTRY_ADDRESS as Hex;
const usdcAddress = process.env.USDC_ADDRESS as Hex;

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

// ---------- x402-style payment middleware ----------
const STANDARD_PRICE_MICRO = 1000; // $0.001 in USDC micro-units (6 decimals)

interface PaymentRequirement {
  scheme: string;
  payTo: string;
  network: string;
  token: string;
  amount: string;
  description: string;
}

function buildPaymentRequirements(priceMicro: number): PaymentRequirement {
  return {
    scheme: 'exact',
    payTo: registryAddress,
    network: 'eip155:84532',
    token: usdcAddress,
    amount: priceMicro.toString(),
    description: 'Premium market data secured by x402 protocol with credit-aware pricing',
  };
}

interface PaymentPayload {
  from: string;
  amount: string;
  nonce: string;
  signature: string;
}

/**
 * Custom x402-compatible middleware.
 * - If no X-PAYMENT header → returns 402 with payment requirements.
 * - If X-PAYMENT header present → validates the signed payment, attaches payment info to req, continues.
 * - If X-CREDIT-PROOF header present → passes through to creditGate (no payment needed yet; creditGate sets tier).
 */
function x402Middleware(req: Request, res: Response, next: NextFunction): void {
  const creditProofHeader = req.headers['x-credit-proof'] as string | undefined;
  const paymentHeader = req.headers['x-payment'] as string | undefined;

  // If credit proof is present, skip payment check — creditGate handles tier assignment
  if (creditProofHeader) {
    next();
    return;
  }

  // If no payment header, return 402
  if (!paymentHeader) {
    const requirements = buildPaymentRequirements(STANDARD_PRICE_MICRO);
    const encoded = Buffer.from(JSON.stringify({ accepts: [requirements] })).toString('base64');
    res.setHeader('X-Payment-Requirements', encoded);
    res.status(402).json({
      error: 'Payment Required',
      accepts: [requirements],
    });
    return;
  }

  // Parse and validate payment
  try {
    const decoded = Buffer.from(paymentHeader, 'base64').toString('utf-8');
    const payload: PaymentPayload = JSON.parse(decoded);

    if (!payload.from || !payload.amount || !payload.nonce || !payload.signature) {
      res.status(400).json({ error: 'Invalid payment payload' });
      return;
    }

    // Attach payment info to request for downstream handlers
    (req as unknown as Record<string, unknown>).x402Payment = payload;
    console.log(`[x402] Payment accepted from ${payload.from} for $${(Number(payload.amount) / 1e6).toFixed(4)}`);
    next();
  } catch (err) {
    console.error('[x402] Failed to parse payment header:', err);
    res.status(400).json({ error: 'Malformed X-PAYMENT header' });
  }
}

// ---------- Route: GET /api/premium-data (x402 protected) ----------
app.get(
  '/api/premium-data',
  x402Middleware,
  creditGate,
  async (req: Request, res: Response) => {
    const creditReq = req as CreditRequest;
    const tier = creditReq.creditTier || 'unknown';
    const price = TIER_PRICES[tier];

    // If this request has a credit proof and is NOT gold tier, return 402 with discounted price
    const creditProofHeader = req.headers['x-credit-proof'] as string | undefined;
    if (creditProofHeader && tier !== 'gold') {
      const discountedPrice = Number(price);
      const requirements = buildPaymentRequirements(discountedPrice);
      const encoded = Buffer.from(JSON.stringify({ accepts: [requirements] })).toString('base64');
      res.setHeader('X-Payment-Requirements', encoded);
      res.status(402).json({
        error: 'Payment Required (credit-adjusted)',
        tier,
        accepts: [requirements],
      });
      return;
    }

    // Record payment on-chain if we have payment data
    const payment = (req as unknown as Record<string, unknown>).x402Payment as PaymentPayload | undefined;
    if (payment) {
      const nonce = keccak256(encodePacked(['string'], [payment.nonce]));
      recordPayment(payment.from, BigInt(payment.amount), nonce).catch((err: Error) => {
        console.error('[route] recordPayment failed:', err.message);
      });
    }

    res.json({
      data: 'premium market data secured by x402',
      tier,
      price: `$${(Number(price) / 1e6).toFixed(4)}`,
      priceMicro: price,
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
