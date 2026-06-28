import { Queue } from 'bullmq';
import { createRedisConnection } from './redisConnection.js';
import { PaymentJobData, PAYMENT_QUEUE_NAME } from './types.js';
import { logger } from '../logger.js';

const connection = createRedisConnection();

export const paymentQueue = new Queue(PAYMENT_QUEUE_NAME, {
  connection,
  defaultJobOptions: {
    attempts: 5,                // retry up to 5 times total
    backoff: {
      type: 'exponential',
      delay: 2000,              // 2s, 4s, 8s, 16s, 32s
    },
    removeOnComplete: { count: 1000 },  // keep last 1000 completed jobs
    removeOnFail: { count: 500 },       // keep last 500 failed jobs for audit
  },
});

export const enqueuePayment = async (data: PaymentJobData): Promise<string> => {
  const job = await paymentQueue.add('record-payment', data, {
    jobId: `payment:${data.nonce}`, // idempotent: same nonce = same job ID
    // If job already exists (duplicate event), BullMQ silently skips it
  });
  logger.info({ jobId: job.id, agent: data.agent, amount: data.amount },
    'Payment enqueued');
  return job.id ?? '';
};
