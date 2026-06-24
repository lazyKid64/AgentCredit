import { createPublicClient, http, parseAbi, type Hex } from 'viem';
import { baseSepolia } from 'viem/chains';

export const CREDIT_REGISTRY_ABI = parseAbi([
  'function getScore(address agent) external view returns (uint256)',
  'function getCommitment(address agent) external view returns (bytes32)',
]);

const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http(process.env.NEXT_PUBLIC_RPC_URL || 'https://sepolia.base.org'),
});

const registryAddress = (process.env.NEXT_PUBLIC_REGISTRY_ADDRESS || process.env.CREDIT_REGISTRY_ADDRESS) as Hex;

export async function getAgentScore(address: string): Promise<{score: number, tier: 'gold'|'silver'|'unknown'}> {
  try {
    const scoreRaw = await publicClient.readContract({
      address: registryAddress,
      abi: CREDIT_REGISTRY_ABI,
      functionName: 'getScore',
      args: [address as Hex],
    });

    const score = Number(scoreRaw);
    let tier: 'gold' | 'silver' | 'unknown' = 'unknown';
    if (score >= 750) tier = 'gold';
    else if (score >= 600) tier = 'silver';

    return { score, tier };
  } catch (error) {
    console.error('Error fetching score:', error);
    return { score: 300, tier: 'unknown' }; // Default fallback
  }
}
