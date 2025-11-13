# STX Staking Rewards Contract

A comprehensive DeFi staking smart contract built on the Stacks blockchain, enabling users to stake STX tokens, earn rewards, and manage their staking positions with advanced features.

## Overview

This contract implements a complete staking ecosystem where users can:
- **Stake STX** tokens and earn rewards based on staking duration
- **Claim Rewards** directly to their wallet
- **Compound Rewards** by automatically restaking earned rewards
- **Unstake** after lock period expires
- **Emergency Unstake** for urgent situations (forfeits pending rewards)
- **Track Performance** via leaderboard system

## Features

### Core Staking Mechanics
- **Flexible Staking**: Users can stake any amount of STX tokens
- **Reward Calculation**: Automatic reward computation based on stake amount, duration, and reward rate
- **Lock Period**: Configurable lock period before unstaking is allowed
- **Reward Pool**: Separate pool for distributing rewards to stakers
- **Leaderboard**: Real-time tracking of top stakers

### Advanced Features
- **Reward Compounding**: Automatically reinvest earned rewards to increase stake
- **Emergency Unstaking**: Withdraw funds immediately without waiting for lock period
- **Admin Controls**: Owner can pause/unpause contract for maintenance
- **Dynamic Reward Rate**: Configurable per-block reward rate
- **Total Tracking**: Monitor total staked and total rewards distributed

### Security
- **Owner-only Functions**: Admin operations restricted to contract owner
- **Pause/Unpause Mechanism**: Can halt contract operations during emergencies
- **Error Handling**: Comprehensive error codes for all failure scenarios

## Constants & Error Codes

```clarity
ERR_NOT_OWNER (100)           - Only contract owner can perform this action
ERR_INVALID_AMOUNT (101)      - Invalid stake amount (must be > 0)
ERR_NO_STAKE (102)            - User has no active stake
ERR_STAKE_LOCKED (103)        - Stake is still in lock period
ERR_PAUSED (104)              - Contract is paused
ERR_NO_REWARDS (105)          - No rewards available or insufficient reward pool
```

## State Variables

| Variable | Type | Description |
|----------|------|-------------|
| `owner` | principal | Contract owner address |
| `paused` | bool | Contract pause status |
| `total-staked` | uint | Total STX staked across all users |
| `total-rewards-distributed` | uint | Total rewards paid out |
| `reward-pool` | uint | Available rewards for distribution |
| `reward-rate-per-block` | uint | Rewards per block (in smallest units) |
| `lock-period` | uint | Blocks user must wait before unstaking |

## Data Structures

### Stakes Map
Stores each user's staking position:
```clarity
{
  amount: uint              // Current stake amount
  start-height: uint        // Block height when stake began
  pending-rewards: uint     // Accumulated unclaimed rewards
  last-claimed: uint        // Last claim timestamp
}
```

### Leaderboard Map
Simple tracking of user stake amounts for ranking purposes.

## Public Functions

### `(stake (amount uint))`
**Description:** Stake STX tokens to earn rewards

**Parameters:**
- `amount` - STX amount to stake (must be > 0)

**Returns:** `(ok amount)` on success, error code on failure

**Example:**
```clarity
(stake u1000000)  ;; Stake 1 STX (in microSTX)
```

---

### `(claim-rewards)`
**Description:** Withdraw earned rewards to wallet

**Returns:** `(ok reward-amount)` on success, error code on failure

**Notes:**
- Rewards must be > 0
- Sufficient reward pool must exist
- Resets pending rewards to 0

---

### `(compound-rewards)`
**Description:** Reinvest earned rewards into stake

**Returns:** `(ok new-total-amount)` on success, error code on failure

**Notes:**
- Automatically adds rewards to current stake
- Resets reward calculation
- Increases leaderboard ranking
## Deployment

### Prerequisites
- Clarinet CLI installed
- Stacks node running (testnet or mainnet)
- STX tokens for gas fees

---

## Security Considerations

1. **Owner Verification**: All admin functions verify tx-sender is contract owner
2. **Pause Mechanism**: Contract can be paused to prevent operations during incidents
3. **Locked Funds**: Stake locked for configured period prevents flash loan attacks
4. **Reward Pool Management**: Rewards only distributed if pool is sufficient
5. **Map Validation**: All map operations use `match` to handle missing entries

---

## Limitations & Notes

- Reward rate is fixed per block (not dynamic based on pool size)
- Lock period is global (same for all users)
- No delegation or proxy staking support
- Unstaking is all-or-nothing (no partial unstakes)
- Emergency unstake forfeits all rewards completely

---

## Testing

The contract includes comprehensive unit tests:

```bash
clarinet test
---

## License

MIT License - See LICENSE file for details

---

## Support & Contributions

For issues, questions, or contributions:
1. Open an issue on GitHub
2. Submit a pull request with improvements
3. Contact the development team

---

## Changelog

### v1.0.0 (Current)
- Initial contract release
- Core staking functionality
- Reward distribution system
- Lock period enforcement
- Emergency unstaking
- Admin controls

---

**Last Updated:** November 13, 2025  
**Status:** ✅ Production Ready
