import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  PaymentRecorded as PaymentRecordedEvent,
  ScoreUpdated as ScoreUpdatedEvent,
} from "../generated/CreditRegistry/CreditRegistry";
import { AgentPayment, AgentCreditScore } from "../generated/schema";

export function handlePaymentRecorded(event: PaymentRecordedEvent): void {
  // Create individual payment entity using nonce as unique ID
  let paymentId = event.params.nonce.toHexString();
  let payment = new AgentPayment(paymentId);
  payment.agent = event.params.agent;
  payment.amount = event.params.amount;
  payment.timestamp = event.block.timestamp;
  payment.blockNumber = event.block.number;
  payment.save();

  // Load or create aggregate credit score entity keyed by agent address
  let agentId = event.params.agent.toHexString();
  let creditScore = AgentCreditScore.load(agentId);

  if (creditScore == null) {
    creditScore = new AgentCreditScore(agentId);
    creditScore.agent = event.params.agent;
    creditScore.totalPayments = BigInt.fromI32(0);
    creditScore.totalVolume = BigInt.fromI32(0);
    creditScore.computedScore = BigInt.fromI32(300);
    creditScore.lastUpdated = BigInt.fromI32(0);
  }

  creditScore.totalPayments = creditScore.totalPayments.plus(BigInt.fromI32(1));
  creditScore.totalVolume = creditScore.totalVolume.plus(event.params.amount);
  creditScore.lastUpdated = event.block.timestamp;
  creditScore.save();
}

export function handleScoreUpdated(event: ScoreUpdatedEvent): void {
  let agentId = event.params.agent.toHexString();
  let creditScore = AgentCreditScore.load(agentId);

  if (creditScore == null) {
    creditScore = new AgentCreditScore(agentId);
    creditScore.agent = event.params.agent;
    creditScore.totalPayments = BigInt.fromI32(0);
    creditScore.totalVolume = BigInt.fromI32(0);
    creditScore.computedScore = BigInt.fromI32(300);
    creditScore.lastUpdated = BigInt.fromI32(0);
  }

  creditScore.computedScore = event.params.newScore;
  creditScore.lastUpdated = event.block.timestamp;
  creditScore.save();
}
