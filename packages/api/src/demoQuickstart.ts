#!/usr/bin/env ts-node
import 'dotenv/config';
import { execSync } from 'child_process';

async function checkPrerequisites(): Promise<{
  redis: boolean;
  rpc: boolean;
  contracts: boolean;
}> {
  const results = { redis: false, rpc: false, contracts: false };

  // Check Redis
  try {
    execSync('redis-cli ping', { timeout: 2000, stdio: 'pipe' });
    results.redis = true;
    console.log('\x1b[32m  \u2713 Redis: connected\x1b[0m');
  } catch {
    console.log('\x1b[33m  ! Redis: not running (queue features will be skipped)\x1b[0m');
  }

  // Check RPC
  try {
    const { createPublicClient, http } = await import('viem');
    const { baseSepolia } = await import('viem/chains');
    const client = createPublicClient({ chain: baseSepolia, transport: http(process.env.RPC_URL) });
    const block = await client.getBlockNumber();
    results.rpc = true;
    console.log(`\x1b[32m  \u2713 RPC: connected (Base Sepolia block ${block})\x1b[0m`);
  } catch {
    console.log('\x1b[31m  \u2717 RPC: cannot connect -- check RPC_URL in .env\x1b[0m');
  }

  // Check contracts
  if (results.rpc && process.env.CREDIT_REGISTRY_ADDRESS) {
    try {
      const { createPublicClient, http, parseAbi } = await import('viem');
      const { baseSepolia } = await import('viem/chains');
      const client = createPublicClient({ chain: baseSepolia, transport: http(process.env.RPC_URL) });
      const version = await client.readContract({
        address: process.env.CREDIT_REGISTRY_ADDRESS as `0x${string}`,
        abi: parseAbi(['function version() external pure returns (string)']),
        functionName: 'version',
      });
      results.contracts = true;
      console.log(`\x1b[32m  \u2713 Contracts: reachable on Base Sepolia (v${version})\x1b[0m`);
    } catch {
      console.log('\x1b[33m  ! Contracts: not reachable -- may need to deploy\x1b[0m');
    }
  }

  return results;
}

async function runDemo(): Promise<void> {
  console.log('\n\x1b[1m\x1b[35m\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557\x1b[0m');
  console.log('\x1b[1m\x1b[35m\u2551   AgentCredit Protocol -- Live Demo     \u2551\x1b[0m');
  console.log('\x1b[1m\x1b[35m\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d\x1b[0m\n');

  console.log('\x1b[1mChecking prerequisites...\x1b[0m\n');
  const prereqs = await checkPrerequisites();

  const mode = prereqs.redis ? 'FULL (with async queue)' : 'LITE (synchronous)';
  console.log(`\n\x1b[1mStarting demo mode: ${mode}\x1b[0m`);
  console.log('\x1b[90m' + '\u2500'.repeat(50) + '\x1b[0m');

  if (!prereqs.redis) {
    console.log('\n\x1b[33m[LITE MODE] Running demo without Redis queue...\x1b[0m');
    console.log('\x1b[33m[LITE MODE] For full production demo: start Redis and retry\x1b[0m\n');
  }

  if (!prereqs.rpc) {
    console.error('\n\x1b[31m[ERROR] Cannot run demo without RPC connection.\x1b[0m');
    console.error('\x1b[31m        Set RPC_URL in .env and try again.\x1b[0m');
    process.exit(1);
  }

  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const { runSimulation } = require('./simulateAgent');
  await runSimulation();
}

runDemo().catch((err) => {
  console.error('\n\x1b[31m[FATAL] Demo failed:\x1b[0m', err.message);
  process.exit(1);
});
