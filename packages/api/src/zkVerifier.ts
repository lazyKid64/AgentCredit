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

export async function verifyProof(proofHeader: string): Promise<VerifyResult> {
  try {
    const decoded = Buffer.from(proofHeader, 'base64').toString('utf-8');
    const payload: ProofPayload = JSON.parse(decoded);

    const { proof, publicInputs } = payload;
    const { threshold, agentAddress, commitment, blockNumber } = publicInputs;

    const zkVerifierAddress = process.env.ZK_VERIFIER_ADDRESS as Hex;
    if (!zkVerifierAddress) {
      console.warn('[zkVerifier] ZK_VERIFIER_ADDRESS not set, skipping on-chain verification');
      return { valid: false, tier: 'unknown', agentAddress: '' };
    }

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

    if (!isValid) {
      return { valid: false, tier: 'unknown', agentAddress };
    }

    const thresholdNum = parseInt(threshold, 10) || Number(BigInt(threshold));

    let tier: CreditTier = 'unknown';
    if (thresholdNum >= 750) {
      tier = 'gold';
    } else if (thresholdNum >= 600) {
      tier = 'silver';
    }

    return { valid: true, tier, agentAddress };
  } catch (error) {
    console.error('[zkVerifier] Verification failed:', error);
    return { valid: false, tier: 'unknown', agentAddress: '' };
  }
}
