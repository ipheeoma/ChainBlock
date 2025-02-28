# ChainBlock Risk Coverage Smart Contract

## Overview

ChainBlock Risk Coverage is a decentralized insurance protocol built on the Stacks blockchain. This smart contract provides a mechanism for users to acquire blockchain risk coverage, submit claims, and receive payouts in case of covered events.

## Features

- **Decentralized Coverage**: Users can acquire protection by depositing STX into the coverage pool
- **Claim Processing**: Submit, approve, or decline claims with transparent tracking
- **Risk Management**: Automated checks for claim validity, coverage limits, and reserve requirements
- **Events Tracking**: All important actions emit events for easy monitoring

## Contract Functions

### User Functions

| Function | Description |
|----------|-------------|
| `register-coverage` | Acquire coverage by depositing STX |
| `submit-claim` | Submit a claim request for covered losses |
| `check-reserve` | View the current protection pool balance |

### Admin Functions

| Function | Description |
|----------|-------------|
| `process-claim` | Approve and process a claim payment |
| `decline-claim` | Reject an invalid claim |

## Error Codes

| Code | Description |
|------|-------------|
| u100 | ERR_AMOUNT_INVALID: Invalid amount provided |
| u101 | ERR_FUNDS_INSUFFICIENT: Insufficient funds available |
| u102 | ERR_NO_CLAIM_FOUND: No claim record found |
| u103 | ERR_ACCESS_DENIED: Unauthorized access attempt |
| u104 | ERR_DUPLICATE_COVERAGE: User already has coverage |
| u105 | ERR_INVALID_USER: User not recognized |
| u106 | ERR_NOT_COVERED: User doesn't have coverage |
| u107 | ERR_ZERO_VALUE: Amount must be greater than zero |
| u108 | ERR_CLAIM_PROCESSED: Claim already processed |
| u109 | ERR_EMPTY_RESERVE: Protection pool is empty |
| u110 | ERR_PREMATURE_CLAIM: Claim needs to wait for processing period |
| u111 | ERR_EXCESSIVE_CLAIM: Claim exceeds coverage amount |

## Usage Examples

### Registering for Coverage

```clarity
;; Register for 1000 STX of coverage
(contract-call? .chainblock-risk-coverage register-coverage u1000)
```

### Submitting a Claim

```clarity
;; Submit a claim for 500 STX
(contract-call? .chainblock-risk-coverage submit-claim u500)
```

### Processing a Claim (Admin Only)

```clarity
;; Process a valid claim for user ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM and amount 500
(contract-call? .chainblock-risk-coverage process-claim 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM u500)
```

## Technical Notes

- **Claim Expiration**: Claims must be processed within the expiration period (4320 blocks, approximately 30 days)
- **Partial Payments**: If the protection pool has insufficient funds, partial payments may be issued
- **Contract Ownership**: Only the contract owner can approve or decline claims

## Security Considerations

- Protection pool funds are held in the contract itself using the `as-contract` context
- Checks are in place to prevent double-claiming and excessive claims
- Claim timestamps are recorded using block heights for reliable timing

## Deployment

To deploy this contract on the Stacks blockchain:

1. Use the Clarinet command: `clarinet deploy --contract-name chainblock-risk-coverage`
2. Alternatively, deploy using the Stacks Explorer or Hiro Wallet
