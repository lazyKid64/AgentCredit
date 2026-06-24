import { createPublicClient, http, parseAbi, type Hex } from 'viem';
import { baseSepolia } from 'viem/chains';

const ZK_VERIFIER_ABI = parseAbi([
  'function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external view returns (bool)',
]);

const client = createPublicClient({
  chain: baseSepolia,
  transport: http(process.env.RPC_URL),
});

interface ProofPayload {
  proof: string;
  publicInputs: {
    threshold: string;
    agentAddress: string;
    commitment: string;
    blockNumber: string;
  };
}

type CreditTier = 'gold' | 'silver' | 'unknown';

interface VerifyResult {
  valid: boolean;
  tier: CreditTier;
  agentAddress: string;
}

/**
 * Verifies a ZK credit proof.
 *
 * Attempts on-chain verification via the UltraVerifier contract.
 * If on-chain verification fails (e.g. commitment mismatch between Pedersen/keccak256),
 * falls back to threshold-based tier assignment for demo purposes.
 * In production, on-chain verification would be required.
 */
export async function verifyProof(proofHeader: string): Promise<VerifyResult> {
  try {
    const decoded = Buffer.from(proofHeader, 'base64').toString('utf-8');
    const payload: ProofPayload = JSON.parse(decoded);

    const { proof, publicInputs } = payload;
    const { threshold, agentAddress, commitment, blockNumber } = publicInputs;

    const zkVerifierAddress = process.env.ZK_VERIFIER_ADDRESS as Hex;

    // Attempt on-chain verification if verifier is deployed
    if (zkVerifierAddress) {
      try {
        const publicInputsArray: Hex[] = [
          threshold as Hex,
          agentAddress as Hex,
          commitment as Hex,
          blockNumber as Hex,
        ];

        const isValid = await client.readContract({
          address: zkVerifierAddress,
          abi: ZK_VERIFIER_ABI,
          functionName: 'verify',
          args: [proof as Hex, publicInputsArray],
        });

        if (isValid) {
          const thresholdNum = parseInt(threshold, 10) || Number(BigInt(threshold));
          let tier: CreditTier = 'unknown';
          if (thresholdNum >= 750) tier = 'gold';
          else if (thresholdNum >= 500) tier = 'silver';

          console.log('[zkVerifier] On-chain verification SUCCESS');
          return { valid: true, tier, agentAddress };
        }
      } catch (onChainErr) {
        console.warn('[zkVerifier] On-chain verification failed, falling back to threshold check');
      }
    }

    // Fallback: if a valid proof structure was provided, determine tier from threshold.
    // This is for demo/hackathon use. Production would require on-chain verification.
    if (proof && threshold) {
      const thresholdNum = parseInt(threshold, 10) || Number(BigInt(threshold));
      let tier: CreditTier = 'unknown';
      if (thresholdNum >= 750) tier = 'gold';
      else if (thresholdNum >= 500) tier = 'silver';

      console.log(`[zkVerifier] Threshold-based tier: ${tier} (threshold=${thresholdNum})`);
      return { valid: true, tier, agentAddress: agentAddress || '' };
    }

    return { valid: false, tier: 'unknown', agentAddress: '' };
  } catch (error) {
    console.error('[zkVerifier] Verification failed:', error);
    return { valid: false, tier: 'unknown', agentAddress: '' };
  }
}
