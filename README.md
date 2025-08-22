# KronosVault

**Bitcoin-Collateralized Credit Engine on Stacks**

KronosVault is a decentralized lending protocol that enables Bitcoin holders to unlock liquidity without sacrificing custody of their assets. Built on the Stacks blockchain, it provides a trust-minimized framework for Bitcoin-backed credit markets with autonomous smart contract governance.

## Overview

KronosVault bridges Bitcoin's store-of-value properties with DeFi lending mechanics, creating a programmable credit layer where Bitcoin serves as the foundational reserve asset. The protocol enables users to deposit BTC as collateral, request loans, and manage repayments through transparent, on-chain mechanisms.

### Key Features

- **Bitcoin-Backed Lending**: Use Bitcoin as collateral without giving up custody
- **Automated Collateral Management**: Dynamic collateral ratio enforcement with liquidation protection
- **Interest Rate Mechanics**: Block-based interest calculation with transparent accrual
- **Governance Controls**: Owner-managed parameters for collateral thresholds and price feeds
- **Liquidation System**: Autonomous liquidation of undercollateralized positions
- **Multi-Asset Support**: Extensible framework supporting BTC and STX assets

## Architecture

### System Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Borrowers     │    │   KronosVault   │    │   Governance    │
│                 │    │    Contract     │    │    (Owner)      │
│ - Deposit BTC   │◄──►│                 │◄──►│ - Set Ratios    │
│ - Request Loans │    │ - Loan Logic    │    │ - Update Prices │
│ - Repay Debt    │    │ - Liquidations  │    │ - Configure     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                               │
                               ▼
                    ┌─────────────────┐
                    │   Price Oracle  │
                    │   (External)    │
                    │ - BTC/USD Feed  │
                    │ - STX/USD Feed  │
                    └─────────────────┘
```

### Contract Architecture

#### Core Data Structures

**Loans Map**

```clarity
{
  borrower: principal,
  collateral-amount: uint,
  loan-amount: uint,
  interest-rate: uint,
  start-height: uint,
  last-interest-calc: uint,
  status: (string-ascii 20)
}
```

**User Loans Tracking**

```clarity
{
  active-loans: (list 10 uint)  // Max 10 concurrent loans per user
}
```

**Price Feeds**

```clarity
{
  asset: (string-ascii 3),  // "BTC" or "STX"
  price: uint               // Price in micro-units
}
```

#### Parameter Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| Minimum Collateral Ratio | 150% | Required overcollateralization |
| Liquidation Threshold | 120% | Triggers position liquidation |
| Platform Fee Rate | 1% | Protocol fee on operations |
| Interest Rate | 5% | Fixed rate per loan (configurable) |

### Data Flow

#### Loan Origination Process

```
1. User Deposits Collateral
   ├── Validate platform initialization
   ├── Check minimum amount requirements
   └── Update total BTC locked

2. Request Loan
   ├── Fetch current BTC price from oracle
   ├── Calculate collateral value
   ├── Verify collateral ratio >= 150%
   ├── Create loan record
   ├── Update user loan tracking
   └── Increment total loans issued

3. Ongoing Management
   ├── Interest accrual per block
   ├── Continuous liquidation monitoring
   └── Collateral ratio tracking
```

#### Liquidation Mechanism

```
Liquidation Trigger: Collateral Ratio ≤ 120%

Process:
├── Monitor all active loans
├── Calculate current collateral ratios
├── Identify undercollateralized positions
├── Execute liquidation
│   ├── Update loan status to "liquidated"
│   ├── Remove from user active loans
│   └── Transfer collateral ownership
```

## Smart Contract Interface

### Public Functions

#### Platform Management

- `initialize-platform()` - Initialize the lending platform (owner only)
- `deposit-collateral(amount)` - Deposit BTC collateral
- `update-price-feed(asset, price)` - Update asset price feeds (owner only)

#### Loan Operations

- `request-loan(collateral, loan-amount)` - Request a collateralized loan
- `repay-loan(loan-id, amount)` - Repay loan with interest

#### Governance

- `update-collateral-ratio(new-ratio)` - Modify minimum collateral requirements
- `update-liquidation-threshold(new-threshold)` - Adjust liquidation trigger

### Read-Only Functions

- `get-loan-details(loan-id)` - Retrieve loan information
- `get-user-loans(user)` - Get user's active loan IDs
- `get-platform-stats()` - Platform-wide statistics
- `get-valid-assets()` - Supported asset list

### Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR-NOT-AUTHORIZED | Unauthorized access |
| u101 | ERR-INSUFFICIENT-COLLATERAL | Below minimum collateral ratio |
| u102 | ERR-BELOW-MINIMUM | Amount below minimum threshold |
| u103 | ERR-INVALID-AMOUNT | Invalid amount provided |
| u104 | ERR-ALREADY-INITIALIZED | Platform already initialized |
| u105 | ERR-NOT-INITIALIZED | Platform not initialized |
| u106 | ERR-INVALID-LIQUIDATION | Invalid liquidation attempt |
| u107 | ERR-LOAN-NOT-FOUND | Loan ID not found |
| u108 | ERR-LOAN-NOT-ACTIVE | Loan not in active state |
| u109 | ERR-INVALID-LOAN-ID | Invalid loan ID format |
| u110 | ERR-INVALID-PRICE | Invalid price value |
| u111 | ERR-INVALID-ASSET | Asset not supported |

## Development

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks development environment
- Node.js and npm - For testing framework

### Setup

```bash
# Clone the repository
git clone <repository-url>
cd kronos-vault

# Install dependencies
npm install

# Run contract checks
clarinet check

# Run tests
npm test
```

### Testing

The contract includes comprehensive test coverage for:

- Loan origination and repayment flows
- Collateral ratio calculations
- Liquidation scenarios
- Governance parameter updates
- Edge cases and error conditions

```bash
# Run specific test suites
npm test -- --grep "loan creation"
npm test -- --grep "liquidation"
```

## Security Considerations

### Collateralization

- **Over-collateralization**: 150% minimum ratio provides buffer against price volatility
- **Liquidation Buffer**: 30% margin between minimum ratio and liquidation threshold
- **Price Feed Dependency**: Contract relies on trusted price oracle updates

### Access Control

- **Owner Privileges**: Limited to governance parameters and price feed updates
- **User Isolation**: Borrowers can only manage their own loans
- **Immutable Logic**: Core lending logic cannot be modified post-deployment

### Known Limitations

- **Fixed Interest Rates**: Currently uses static 5% rate (not market-driven)
- **Single Oracle**: Centralized price feed dependency
- **Limited Assets**: Currently supports BTC and STX only
- **Manual Liquidations**: Requires external trigger for liquidation checks

## Roadmap

- [ ] **Dynamic Interest Rates** - Market-driven rate calculation
- [ ] **Multi-Oracle Integration** - Decentralized price aggregation
- [ ] **Automated Liquidation Bots** - Keeper network integration
- [ ] **Additional Assets** - Expand supported collateral types
- [ ] **Governance Token** - Decentralized protocol governance
- [ ] **Insurance Pool** - Protocol-owned liquidity for bad debt coverage
