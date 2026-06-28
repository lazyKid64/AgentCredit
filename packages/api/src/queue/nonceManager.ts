import { createPublicClient, http } from 'viem';
import { baseSepolia } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';
import { logger } from '../logger.js';

// Nonce manager prevents concurrent transactions from colliding
// Tracks pending nonces so rapid sequential calls don't reuse the same nonce
class NonceManager {
  private pendingNonce: bigint | null = null;
  private account;
  private client;

  constructor() {
    this.account = privateKeyToAccount(
      process.env.X402_FACILITATOR_PRIVATE_KEY as `0x${string}`
    );
    this.client = createPublicClient({
      chain: baseSepolia,
      transport: http(process.env.RPC_URL),
    });
  }

  async getNextNonce(): Promise<bigint> {
    const onChainNonce = await this.client.getTransactionCount({
      address: this.account.address,
      blockTag: 'pending',
    });
    const nextNonce = BigInt(onChainNonce);

    // If we have a pending nonce higher than on-chain, use that
    if (this.pendingNonce !== null && this.pendingNonce >= nextNonce) {
      this.pendingNonce++;
      return this.pendingNonce;
    }

    this.pendingNonce = nextNonce;
    return nextNonce;
  }

  resetPendingNonce(): void {
    this.pendingNonce = null;
    logger.warn('Nonce manager reset — likely after a failed transaction');
  }
}

export const nonceManager = new NonceManager();
