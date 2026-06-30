// Run this before starting the API in production: ts-node src/validateEnv.ts
import 'dotenv/config';
import { createPublicClient, http, isAddress } from 'viem';
import { baseSepolia } from 'viem/chains';

interface EnvCheck {
  name: string;
  value: string | undefined;
  validate: (val: string) => boolean;
  required: boolean;
  hint: string;
}

const checks: EnvCheck[] = [
  {
    name: 'RPC_URL',
    value: process.env.RPC_URL,
    validate: (v) => v.startsWith('https://'),
    required: true,
    hint: 'Must be an HTTPS URL (e.g. Alchemy or QuickNode Base endpoint)',
  },
  {
    name: 'CREDIT_REGISTRY_ADDRESS',
    value: process.env.CREDIT_REGISTRY_ADDRESS,
    validate: (v) => isAddress(v),
    required: true,
    hint: 'Must be a valid Ethereum address (0x...)',
  },
  {
    name: 'ZK_VERIFIER_ADDRESS',
    value: process.env.ZK_VERIFIER_ADDRESS,
    validate: (v) => isAddress(v),
    required: true,
    hint: 'Must be a valid Ethereum address (0x...)',
  },
  {
    name: 'PROOF_CACHE_ADDRESS',
    value: process.env.PROOF_CACHE_ADDRESS,
    validate: (v) => isAddress(v),
    required: true,
    hint: 'Must be a valid Ethereum address (0x...)',
  },
  {
    name: 'X402_FACILITATOR_PRIVATE_KEY',
    value: process.env.X402_FACILITATOR_PRIVATE_KEY,
    validate: (v) => v.startsWith('0x') && v.length === 66,
    required: true,
    hint: 'Must be 0x-prefixed 32-byte hex private key',
  },
  {
    name: 'REDIS_URL',
    value: process.env.REDIS_URL,
    validate: (v) => v.startsWith('redis://') || v.startsWith('rediss://'),
    required: true,
    hint: 'Must be redis:// or rediss:// (TLS) URL',
  },
  {
    name: 'USDC_ADDRESS',
    value: process.env.USDC_ADDRESS,
    validate: (v) => isAddress(v),
    required: true,
    hint: 'Must be a valid USDC contract address',
  },
];

async function validateEnv(): Promise<void> {
  console.log('\x1b[1m\x1b[36m=== AgentCredit Environment Validation ===\x1b[0m\n');
  const errors: string[] = [];
  const warnings: string[] = [];

  for (const check of checks) {
    if (!check.value) {
      if (check.required) {
        errors.push(`\x1b[31m  \u2717 ${check.name}: missing -- ${check.hint}\x1b[0m`);
      } else {
        warnings.push(`\x1b[33m  ! ${check.name}: not set (optional)\x1b[0m`);
      }
      continue;
    }

    if (!check.validate(check.value)) {
      errors.push(`\x1b[31m  \u2717 ${check.name}: invalid format -- ${check.hint}\x1b[0m`);
    } else {
      console.log(`\x1b[32m  \u2713 ${check.name}: valid\x1b[0m`);
    }
  }

  // Live RPC connectivity check
  if (process.env.RPC_URL) {
    try {
      const client = createPublicClient({
        chain: baseSepolia,
        transport: http(process.env.RPC_URL),
      });
      const blockNumber = await client.getBlockNumber();
      console.log(`\x1b[32m  \u2713 RPC_URL: connected (block ${blockNumber})\x1b[0m`);
    } catch {
      errors.push('\x1b[31m  \u2717 RPC_URL: cannot connect to RPC endpoint\x1b[0m');
    }
  }

  if (warnings.length > 0) {
    console.log('\n\x1b[33mWarnings:\x1b[0m');
    warnings.forEach((w) => console.log(w));
  }

  if (errors.length > 0) {
    console.error('\n\x1b[31mEnvironment validation FAILED:\x1b[0m');
    errors.forEach((e) => console.error(e));
    process.exit(1);
  }

  console.log(
    '\n\x1b[32m\u2713 All environment checks passed. Safe to start API server.\x1b[0m'
  );
}

validateEnv();
