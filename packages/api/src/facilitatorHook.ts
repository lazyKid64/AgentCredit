import { enqueuePayment } from './queue/paymentQueue.js';
import { logger } from './logger.js';

// This is now fire-and-forget: enqueue the job and return immediately
// The worker processes it asynchronously with retries
export const recordPayment = async (
  agent: string,
  amount: bigint,
  nonce: string,
  txHash: string = ''
): Promise<void> => {
  const jobId = await enqueuePayment({
    agent,
    amount: amount.toString(),
    nonce,
    txHash,
    timestamp: Date.now(),
    attempts: 0,
  });
  logger.info({ agent, jobId }, 'Payment enqueued for async processing');
  // Returns immediately — API response is not delayed
};
