import { Worker, Job } from 'bullmq';
import { createWalletClient, createPublicClient, http, fallback, parseAbi } from 'viem';
import { baseSepolia } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';
import { PaymentJobData, PaymentJobResult, PAYMENT_QUEUE_NAME } from './types.js';
import { createRedisConnection } from './redisConnection.js';
import { nonceManager } from './nonceManager.js';
import { logger } from '../logger.js';

const CREDIT_REGISTRY_ABI = parseAbi([
  'function recordPayment(address agent, uint256 amount, bytes32 nonce) external',
  'function getScore(address agent) external view returns (uint256)',
]);

// Multi-provider transport for redundancy — falls back automatically
const transport = fallback([
  http(process.env.RPC_URL ?? 'https://sepolia.base.org'),
  http('https://sepolia.base.org'), // public fallback — always last
], { rank: true }); // rank: true auto-selects fastest provider

const account = privateKeyToAccount(
  process.env.X402_FACILITATOR_PRIVATE_KEY as `0x${string}`
);

const walletClient = createWalletClient({ account, chain: baseSepolia, transport });
const publicClient = createPublicClient({ chain: baseSepolia, transport });

const processPayment = async (job: Job<PaymentJobData>): Promise<PaymentJobResult> => {
  const start = Date.now();
  const { agent, amount, nonce } = job.data;
  logger.info({ jobId: job.id, agent, attempt: job.attemptsMade + 1 },
    'Processing payment job');

  const txNonce = await nonceManager.getNextNonce();

  try {
    const hash = await walletClient.writeContract({
      address: process.env.CREDIT_REGISTRY_ADDRESS as `0x${string}`,
      abi: CREDIT_REGISTRY_ABI,
      functionName: 'recordPayment',
      args: [agent as `0x${string}`, BigInt(amount), nonce as `0x${string}`],
      nonce: Number(txNonce),
    });

    // Wait for confirmation — 3 blocks for safety on Base
    const receipt = await publicClient.waitForTransactionReceipt({
      hash,
      confirmations: 3,
    });

    if (receipt.status === 'reverted') {
      throw new Error(`Transaction reverted: ${hash}`);
    }

    const newScore = await publicClient.readContract({
      address: process.env.CREDIT_REGISTRY_ADDRESS as `0x${string}`,
      abi: CREDIT_REGISTRY_ABI,
      functionName: 'getScore',
      args: [agent as `0x${string}`],
    });

    logger.info({ jobId: job.id, agent, registryTxHash: hash, newScore: Number(newScore) },
      'Payment recorded successfully');

    return {
      success: true,
      registryTxHash: hash,
      newScore: Number(newScore),
      processingTimeMs: Date.now() - start,
    };
  } catch (error) {
    // Reset nonce manager on failure — next attempt will re-fetch from chain
    nonceManager.resetPendingNonce();
    throw error; // BullMQ will retry with exponential backoff
  }
};

export const startPaymentWorker = (): Worker<PaymentJobData, PaymentJobResult> => {
  const worker = new Worker(PAYMENT_QUEUE_NAME, processPayment, {
    connection: createRedisConnection(),
    concurrency: 1, // process one payment at a time to avoid nonce collisions
    limiter: {
      max: 10,        // max 10 recordPayment calls per second
      duration: 1000,
    },
  });

  worker.on('completed', (job, result) => {
    logger.info({ jobId: job.id, ...result }, 'Payment job completed');
  });

  worker.on('failed', (job, err) => {
    logger.error({ jobId: job?.id, error: err.message, stack: err.stack },
      'Payment job failed');
  });

  // Graceful shutdown
  process.on('SIGTERM', async () => {
    logger.info('SIGTERM received — closing payment worker');
    await worker.close();
    process.exit(0);
  });

  logger.info('Payment worker started');
  return worker;
};
