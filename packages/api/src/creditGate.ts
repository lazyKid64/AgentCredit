import { Request, Response, NextFunction } from 'express';
import { createPublicClient, http, parseAbi, type Hex } from 'viem';
import { baseSepolia } from 'viem/chains';
import { verifyProof } from './zkVerifier';

export type CreditTier = 'gold' | 'silver' | 'unknown';

export interface CreditRequest extends Request {
  creditTier: CreditTier;
}

export const TIER_PRICES: Record<CreditTier, { priceUSDC: string; label: string }> = {
  gold:    { priceUSDC: '500',  label: '🥇 Gold   — $0.0005 (50% off)' },
  silver:  { priceUSDC: '800',  label: '🥈 Silver  — $0.0008 (20% off)' },
  unknown: { priceUSDC: '1000', label: '⬜ Unknown — $0.0010 (standard)' },
};

const PROOF_CACHE_ABI = parseAbi([
  'function checkReceipt(address agent) external view returns (bool valid, uint8 tier)',
]);

const client = createPublicClient({
  chain: baseSepolia,
  transport: http(process.env.RPC_URL),
});

/**
 * Credit gate middleware — determines the agent's credit tier.
 *
 * PATH A (cached): Check ProofCache.checkReceipt(agentAddress) on-chain.
 *   If valid and non-expired → use cached tier, skip re-verification.
 * PATH B (new proof): Agent submits X-CREDIT-PROOF header.
 *   Verify proof inline (original flow).
 * PATH C (no proof): Unknown tier, full price.
 */
export async function creditGate(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const creditReq = req as CreditRequest;
  const proofHeader = req.headers['x-credit-proof'] as string | undefined;
  const agentAddress = req.headers['x-agent-address'] as string | undefined;

  // PATH A: Check ProofCache for cached receipt
  const proofCacheAddress = process.env.PROOF_CACHE_ADDRESS as Hex | undefined;
  if (proofCacheAddress && agentAddress) {
    try {
      const [valid, tierNum] = await client.readContract({
        address: proofCacheAddress,
        abi: PROOF_CACHE_ABI,
        functionName: 'checkReceipt',
        args: [agentAddress as Hex],
      }) as [boolean, number];

      if (valid) {
        const tierMap: Record<number, CreditTier> = { 2: 'gold', 1: 'silver', 0: 'unknown' };
        creditReq.creditTier = tierMap[tierNum] || 'unknown';
        console.log(
          `[creditGate] [cache HIT] tier: ${creditReq.creditTier}`,
          `Agent: ${agentAddress}`
        );
        return next();
      }
    } catch (cacheErr) {
      console.warn('[creditGate] ProofCache check failed, falling back to proof header');
    }
  }

  // PATH B: Verify X-CREDIT-PROOF header inline
  if (proofHeader) {
    const result = await verifyProof(proofHeader);
    creditReq.creditTier = result.tier;
    console.log(
      '[creditGate] Proof verified. Tier:',
      result.tier,
      'Agent:',
      result.agentAddress,
      'Valid:',
      result.valid
    );
  } else {
    // PATH C: No proof, unknown tier
    creditReq.creditTier = 'unknown';
  }

  next();
}
