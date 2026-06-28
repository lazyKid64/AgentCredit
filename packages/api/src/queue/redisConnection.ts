import IORedis from 'ioredis';

// CRITICAL: maxRetriesPerRequest must be null for BullMQ
// enableReadyCheck must be false to avoid startup race conditions
// We import ioredis from BullMQ's bundled version to avoid type conflicts
export const createRedisConnection = () => {
  const url = process.env.REDIS_URL ?? 'redis://localhost:6379';
  return new IORedis(url, {
    maxRetriesPerRequest: null,  // REQUIRED by BullMQ — do not change
    enableReadyCheck: false,      // REQUIRED by BullMQ — do not change
    tls: process.env.REDIS_TLS === 'true' ? {} : undefined,
    lazyConnect: true,
    retryStrategy: (times: number) => {
      // Reconnect with exponential backoff, max 30s
      return Math.min(times * 1000, 30000);
    }
  });
};
