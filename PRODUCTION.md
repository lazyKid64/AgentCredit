# AgentCredit Protocol — Production Runbook

> **IMPORTANT**: This document is for whoever operates the protocol in production.
> Keep it updated. If a contract address changes, update it here immediately.
> If an emergency procedure changes, update it here before the next incident.

---

## Contract Addresses

| Contract | Address | Network |
|---|---|---|
| CreditRegistry (Proxy) | `[fill after deploy]` | Base Mainnet |
| CreditRegistry (Implementation) | `[fill after deploy]` | Base Mainnet |
| ProofCache (Proxy) | `[fill after deploy]` | Base Mainnet |
| ProofCache (Implementation) | `[fill after deploy]` | Base Mainnet |
| AgentCreditTimelock | `[fill after deploy]` | Base Mainnet |
| ZKVerifier | `[fill after deploy]` | Base Mainnet |
| USDC | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | Base Mainnet |

---

## Role Registry

| Role | Holder | Multisig Type | Use Case |
|---|---|---|---|
| `DEFAULT_ADMIN_ROLE` | TimelockController | N/A (48h delay) | All sensitive operations: upgrades, role changes, weight updates |
| `GUARDIAN_ROLE` | 2-of-3 Hot Safe | Gnosis Safe (instant) | Emergency pause only — `emergencyPause()` |
| `SCORE_ADMIN_ROLE` | TimelockController | N/A (48h delay) | Score weight updates via `updateScoreWeights()` |
| `FACILITATOR_ROLE` | Facilitator Bot EOA | N/A | `recordPayment()` calls — processes x402 payments |

### Key Principle

- **Hot Safe (Guardian)**: Can only pause. Cannot unpause, upgrade, or change roles.
- **Timelock (Admin)**: Controls everything else, but with a mandatory 48-hour delay.
- **Deployer**: Has NO roles after deployment. Key should be stored offline.

---

## Emergency Procedures

### P0: Active Exploit — Funds At Risk

**Response SLA: 30 minutes, 24/7**

1. **Any guardian signer** calls `emergencyPause()` on CreditRegistry:
   ```bash
   cast send $REGISTRY "emergencyPause()" \
     --private-key $GUARDIAN_KEY \
     --rpc-url $RPC_URL
   ```
2. **Alert all 5 multisig signers immediately** — phone/Signal, NOT Telegram/Discord
3. **Within 30 minutes**: All signers confirm pause is active on Basescan:
   ```bash
   cast call $REGISTRY "paused()(bool)" --rpc-url $RPC_URL
   # Must return: true
   ```
4. **Post public notice** in Discord: _"Protocol paused for security review. All funds are safe. Updates to follow."_
5. **Do NOT discuss exploit details publicly** until patched
6. **Fix timeline**: patch → audit → Timelock-scheduled upgrade (48h) → unpause

### P1: Score Manipulation Detected

**Response SLA: 30 minutes, 24/7**

1. **Pause** `recordPayment` via Guardian role (same as P0 step 1)
2. **Review on-chain nonce logs** for suspicious patterns:
   ```bash
   cast logs --address $REGISTRY \
     --topic "PaymentRecorded(address,uint256,bytes32)" \
     --from-block $SUSPECT_BLOCK \
     --rpc-url $RPC_URL
   ```
3. **If attack ongoing**: revoke `FACILITATOR_ROLE` of compromised facilitator.
   > **NOTE**: `revokeRole` requires `DEFAULT_ADMIN_ROLE` → must go through Timelock (48h).
   > For instant response: **pause the contract** instead.
4. **After patch**: Schedule new facilitator key via Timelock, wait 48h, execute.

### P2: Facilitator Bot Down

**Response SLA: 4 hours, business hours**

1. **Check Redis connection**:
   ```bash
   redis-cli -u $REDIS_URL ping
   # Expected: PONG
   ```
2. **Check stuck jobs**:
   ```bash
   redis-cli -u $REDIS_URL llen bull:agentcredit:payments:wait
   ```
3. **Restart worker**:
   ```bash
   pm2 restart agentcredit-worker
   ```
4. Jobs in queue will process automatically when worker restarts (BullMQ persistent).
5. **SLA**: Payment score updates may be delayed up to 30 minutes during downtime.

### P3: RPC Provider Outage

**Response SLA: 4 hours, business hours**

1. API automatically falls back to secondary RPC (viem `fallback` transport).
2. Check primary status: https://status.alchemy.com
3. If fallback also failing: manually update `RPC_URL` in `.env` and restart:
   ```bash
   pm2 restart agentcredit-api
   ```
4. Monitor: Defender Sentinel alerts on score update frequency drop.

---

## Upgrade Process (UUPS + Timelock)

> **Never upgrade without completing ALL steps.**

### Pre-Upgrade Checks

| # | Step | Command | Required Result |
|---|---|---|---|
| 1 | Unit tests | `forge test -v` | 0 failures |
| 2 | Invariant tests | `forge test --match-contract Invariant -v --profile deep` | 0 violations (10K runs) |
| 3 | Coverage | `forge coverage --ir-minimum --report summary` | Branch ≥ 95% |
| 4 | Slither | `slither src/` | 0 High/Critical |
| 5 | External audit | — | All H/C findings fixed |
| 6 | Storage layout diff | See below | No removals or reorders |

### Storage Layout Verification

```bash
# Save current layout
forge inspect CreditRegistry storage-layout > storage-layout-current.json

# Compare against snapshot (committed to repo)
diff storage-layout-snapshot.json storage-layout-current.json

# Rules:
# ✅ New variables BEFORE __gap are OK (reduce __gap size by same count)
# ❌ Removed variables are NEVER OK
# ❌ Reordered variables are NEVER OK
# ❌ Changed variable types are NEVER OK
```

### Upgrade Steps

1. **Test on Base Sepolia first** — full deploy + upgrade cycle
2. **Schedule upgrade via Timelock** (48h delay):
   ```bash
   # The Gnosis Safe proposes the upgrade through the Timelock
   cast send $TIMELOCK "schedule(address,uint256,bytes,bytes32,bytes32,uint256)" \
     $REGISTRY 0 $UPGRADE_CALLDATA 0x0 $SALT 172800
   ```
3. **All signers review** during the 48h window
4. **After 48h**: Execute upgrade via Safe
5. **Verify**:
   ```bash
   cast call $REGISTRY "version()(string)" --rpc-url $RPC_URL
   ```

---

## Monitoring Dashboard

| Service | URL | Access |
|---|---|---|
| Contract activity | `https://basescan.org/address/$REGISTRY_ADDRESS` | Public |
| Defender Sentinels | `https://defender.openzeppelin.com` | Team account |
| Facilitator queue | `http://localhost:3001/admin/queues` | Internal only |
| Redis monitoring | `redis-cli -u $REDIS_URL info stats` | Internal only |

### Key Metrics to Watch

- **Score update frequency**: Should match payment volume. Drop = facilitator issue.
- **Queue depth**: `bull:agentcredit:payments:wait` should stay < 100 normally.
- **Failed jobs**: `bull:agentcredit:payments:failed` — any non-zero = investigate.
- **Gas price**: Base L1 data fee spikes can delay transactions.

---

## On-Call Rotation

| Contact | Role | Reach |
|---|---|---|
| `[Add name]` | Protocol Lead | Phone / Signal |
| `[Add name]` | Smart Contract Dev | Phone / Signal |
| `[Add name]` | Infrastructure | Phone / Signal |

**P0/P1 response SLA**: 30 minutes, 24/7
**P2/P3 response SLA**: 4 hours, business hours

---

## Environment Variables (Production)

```bash
# Network
RPC_URL=https://mainnet.base.org            # Primary — use Alchemy/QuickNode in prod
REDIS_URL=rediss://...                       # Redis with TLS
REDIS_TLS=true

# Contract addresses (fill after deployment)
CREDIT_REGISTRY_ADDRESS=0x...
PROOF_CACHE_ADDRESS=0x...
ZK_VERIFIER_ADDRESS=0x...
USDC_ADDRESS=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913

# Keys (NEVER commit to git)
X402_FACILITATOR_PRIVATE_KEY=0x...           # Facilitator bot key
# PRIVATE_KEY — deployer key — store OFFLINE after deployment

# Logging
LOG_LEVEL=info                                # info in prod, debug for troubleshooting
```

---

## Version History

| Version | Date | Changes | Deployed By |
|---|---|---|---|
| 2.0.0 | `[date]` | Initial production deployment | `[name]` |
