;; Title: KronosVault - Bitcoin-Collateralized Credit Engine
;;
;; Summary:
;; KronosVault is a decentralized lending framework designed for Bitcoin-backed
;; credit markets. It enables borrowers to unlock liquidity without giving up 
;; custody of Bitcoin while enforcing robust collateralization standards and 
;; transparent liquidation mechanisms.
;;
;; Description:
;; KronosVault introduces a programmable credit layer where Bitcoin acts as 
;; the foundational reserve asset. Through autonomous smart contracts, users 
;; can deposit BTC, request loans, and repay obligations on-chain, while the 
;; protocol continuously ensures solvency and fairness.
;;
;; Key Capabilities:
;;   - Collateralized loan issuance with automated collateral ratio enforcement
;;   - Dynamic interest calculation across loan lifecycles
;;   - Seamless liquidation of undercollateralized positions
;;   - Governance-driven controls for collateral thresholds and price feeds
;;   - Transparent reporting of platform statistics and loan states
;;
;; By anchoring to Bitcoin's stability and combining it with programmable 
;; governance, KronosVault lays the foundation for trust-minimized, 
;; censorship-resistant credit markets that scale with user demand.

;; Core Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u101))
(define-constant ERR-BELOW-MINIMUM (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-ALREADY-INITIALIZED (err u104))
(define-constant ERR-NOT-INITIALIZED (err u105))
(define-constant ERR-INVALID-LIQUIDATION (err u106))
(define-constant ERR-LOAN-NOT-FOUND (err u107))
(define-constant ERR-LOAN-NOT-ACTIVE (err u108))
(define-constant ERR-INVALID-LOAN-ID (err u109))
(define-constant ERR-INVALID-PRICE (err u110))
(define-constant ERR-INVALID-ASSET (err u111))
(define-constant VALID-ASSETS (list "BTC" "STX"))

;; Data Variables
(define-data-var platform-initialized bool false)
(define-data-var minimum-collateral-ratio uint u150) ;; 150% collateral ratio
(define-data-var liquidation-threshold uint u120) ;; 120% triggers liquidation
(define-data-var platform-fee-rate uint u1) ;; 1% platform fee
(define-data-var total-btc-locked uint u0)
(define-data-var total-loans-issued uint u0)

;; Data Maps
(define-map loans
  { loan-id: uint }
  {
    borrower: principal,
    collateral-amount: uint,
    loan-amount: uint,
    interest-rate: uint,
    start-height: uint,
    last-interest-calc: uint,
    status: (string-ascii 20),
  }
)

(define-map user-loans
  { user: principal }
  { active-loans: (list 10 uint) }
)

(define-map collateral-prices
  { asset: (string-ascii 3) }
  { price: uint }
)

;; Private Functions
(define-private (calculate-collateral-ratio
    (collateral uint)
    (loan uint)
    (btc-price uint)
  )
  (let (
      (collateral-value (* collateral btc-price))
      (ratio (* (/ collateral-value loan) u100))
    )
    ratio
  )
)

(define-private (calculate-interest
    (principal uint)
    (rate uint)
    (blocks uint)
  )
  (let (
      (interest-per-block (/ (* principal rate) (* u100 u144))) ;; Daily interest
      (total-interest (* interest-per-block blocks))
    )
    total-interest
  )
)

(define-private (check-liquidation (loan-id uint))
  (let (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
      (btc-price (unwrap! (get price (map-get? collateral-prices { asset: "BTC" }))
        ERR-NOT-INITIALIZED
      ))
      (current-ratio (calculate-collateral-ratio (get collateral-amount loan)
        (get loan-amount loan) btc-price
      ))
    )
    (if (<= current-ratio (var-get liquidation-threshold))
      (liquidate-position loan-id)
      (ok true)
    )
  )
)

(define-private (liquidate-position (loan-id uint))
  (let (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
      (borrower (get borrower loan))
    )
    (begin
      (map-set loans { loan-id: loan-id } (merge loan { status: "liquidated" }))
      (map-delete user-loans { user: borrower })
      (ok true)
    )
  )
)

(define-private (validate-loan-id (loan-id uint))
  (and
    (> loan-id u0)
    (<= loan-id (var-get total-loans-issued))
  )
)

(define-private (is-valid-asset (asset (string-ascii 3)))
  (is-some (index-of VALID-ASSETS asset))
)

(define-private (is-valid-price (price uint))
  (and
    (> price u0)
    (<= price u1000000000000)
  )
)