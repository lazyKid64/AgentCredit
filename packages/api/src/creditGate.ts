import { Request, Response, NextFunction } from 'express';
import { verifyProof } from './zkVerifier';

export type CreditTier = 'gold' | 'silver' | 'unknown';

export interface CreditRequest extends Request {
  creditTier: CreditTier;
}

export const TIER_PRICES: Record<CreditTier, string> = {
  gold: '500',
  silver: '800',
  unknown: '1000',
};

export async function creditGate(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const creditReq = req as CreditRequest;
  const proofHeader = req.headers['x-credit-proof'] as string | undefined;

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
    creditReq.creditTier = 'unknown';
  }

  next();
}
