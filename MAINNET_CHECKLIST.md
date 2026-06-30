# AgentCredit Protocol — Mainnet Pre-Flight Checklist

> **Complete every item. Do not deploy to mainnet until all are checked.**
> Add your name and date next to each completed item.

---

## Contracts

- [ ] UUPS proxy deployed and verified on Base Sepolia
- [ ] Timelock deployed with 48h delay — verified via `getMinDelay()` returns `172800`
- [ ] Gnosis Safe 3-of-5 configured — all signers on hardware wallets
- [ ] `DEFAULT_ADMIN_ROLE` held by Timelock only — deployer key renounced
- [ ] Guardian 2-of-3 Safe holds `GUARDIAN_ROLE`
- [ ] `emergencyPause()` tested on testnet — confirms pause works
- [ ] `version()` function returns correct string (`"2.0.0"`)
- [ ] Storage layout snapshot committed to repo (`storage-layout-snapshot.json`)
- [ ] No constructor in implementation contract (checked by OZ plugin)
- [ ] Contract sizes < 24,576 bytes (`forge build --sizes` passes)

## ZK System

- [ ] Poseidon hash consistent between Solidity (`PoseidonT3`) and Noir (`poseidon::bn254::hash_2`)
- [ ] `nargo verify` passes on fresh proof
- [ ] ProofCache deployed and verified on Basescan
- [ ] Proof replay tested — same proof rejected on second submission (nullifier check)
- [ ] Expired proof tested — receipt invalid after 3600 blocks
- [ ] Browser proof generation tested in Next.js dashboard
- [ ] Commitment computed correctly: `PoseidonT3.hash([score, agentAddress % BN254_MODULUS])`

## Testing

- [ ] `forge test`: 0 failures (all tests including invariants)
- [ ] Branch coverage ≥ 95% for `CreditRegistry.sol`
- [ ] Branch coverage ≥ 95% for `ProofCache.sol`
- [ ] Invariant tests: 10,000 runs each (`--profile deep`), 0 violations
- [ ] Slither: 0 High, 0 Critical findings
- [ ] `npx tsc --noEmit` passes for `packages/api`
- [ ] `npx tsc --noEmit` passes for `packages/dashboard`

## Audits

- [ ] Competitive audit (Sherlock / Code4rena) complete — all H/C findings fixed
- [ ] Private audit (Spearbit / Cyfrin) complete — all H/C findings fixed
- [ ] ZK circuit audit (Veridise / Nethermind) complete
- [ ] Audit reports published publicly
- [ ] All audit finding fixes verified by auditors

## Infrastructure

- [ ] Multi-RPC fallback configured and tested (viem `fallback` transport)
- [ ] Redis persistence enabled (`appendonly yes` in redis.conf)
- [ ] BullMQ worker starts and processes jobs correctly on production Redis
- [ ] `validateEnv.ts` passes with production `.env`
- [ ] Defender Sentinels active on: `PaymentRecorded`, `ProtocolPaused`, `Upgraded`
- [ ] Incident response contacts documented in `PRODUCTION.md`
- [ ] PM2 / systemd process manager configured for API + Worker
- [ ] Log aggregation configured (Datadog / CloudWatch / Grafana)
- [ ] Uptime monitoring on `/api/health` endpoint (Pingdom / UptimeRobot)

## Bug Bounty

- [ ] Immunefi program created with reward tiers:
  - Critical: $10,000 – $25,000
  - High: $5,000 – $10,000
  - Medium: $1,000 – $5,000
- [ ] Bounty pool funded (minimum $25,000 USDC)
- [ ] Scope documented:
  - In-scope: `CreditRegistry.sol`, `ProofCache.sol`, `AgentCreditTimelock.sol`, ZK circuits
  - Out-of-scope: Frontend, off-chain API, deployment scripts

## Public Communications

- [ ] `README.md` updated with mainnet addresses
- [ ] `PRODUCTION.md` complete with all contract addresses filled
- [ ] Discord announcement draft ready
- [ ] `SECURITY.md` published with:
  - Known risks and mitigations
  - Responsible disclosure process
  - Bug bounty link
- [ ] Twitter / X announcement coordinated with deployment

---

## Sign-Off

| Role | Name | Date | Signature |
|---|---|---|---|
| Protocol Lead | | | |
| Smart Contract Dev | | | |
| Security Reviewer | | | |
| Infrastructure Lead | | | |

> **All four sign-offs required before mainnet deployment.**
