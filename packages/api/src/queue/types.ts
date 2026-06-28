export interface PaymentJobData {
  agent: string;         // agent wallet address (checksummed)
  amount: string;        // USDC amount as string (bigint serialization)
  nonce: string;         // EIP-3009 nonce (bytes32 hex string)
  txHash: string;        // on-chain USDC transfer tx hash (for audit)
  timestamp: number;     // unix ms when payment was received
  attempts: number;      // track retry count for logging
}

export type PaymentJobResult = {
  success: boolean;
  registryTxHash: string;  // CreditRegistry.recordPayment() tx hash
  newScore: number;
  processingTimeMs: number;
};

export const PAYMENT_QUEUE_NAME = 'agentcredit:payments';
export const DLQ_QUEUE_NAME = 'agentcredit:payments:dlq';
