import {
  createWalletClient,
  http,
  parseAbi,
  type Hex,
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { baseSepolia } from 'viem/chains';

const CREDIT_REGISTRY_ABI = parseAbi([
  'function recordPayment(address agent, uint256 amount, bytes32 nonce) external',
]);

export async function recordPayment(
  agent: string,
  amount: bigint,
  nonce: string
): Promise<void> {
  const privateKey = process.env.PRIVATE_KEY as Hex;
  if (!privateKey) {
    throw new Error('PRIVATE_KEY not set in environment');
  }

  const registryAddress = process.env.CREDIT_REGISTRY_ADDRESS as Hex;
  if (!registryAddress) {
    throw new Error('CREDIT_REGISTRY_ADDRESS not set in environment');
  }

  const account = privateKeyToAccount(privateKey);
  const walletClient = createWalletClient({
    account,
    chain: baseSepolia,
    transport: http(process.env.RPC_URL),
  });

  const txHash = await walletClient.writeContract({
    address: registryAddress,
    abi: CREDIT_REGISTRY_ABI,
    functionName: 'recordPayment',
    args: [agent as Hex, amount, nonce as Hex],
  });

  console.log('[facilitator] Tx submitted:', txHash);

  const { createPublicClient } = await import('viem');
  const publicClient = createPublicClient({
    chain: baseSepolia,
    transport: http(process.env.RPC_URL),
  });

  const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });
  console.log(
    '[facilitator] Payment recorded. Agent:',
    agent,
    'Amount:',
    amount.toString(),
    'Block:',
    receipt.blockNumber.toString()
  );
}
