;; ChainBlock Risk Coverage Smart Contract

;; Define error constants with specific messages
(define-constant ERR_AMOUNT_INVALID (err u100))
(define-constant ERR_FUNDS_INSUFFICIENT (err u101))
(define-constant ERR_NO_CLAIM_FOUND (err u102))
(define-constant ERR_ACCESS_DENIED (err u103))
(define-constant ERR_DUPLICATE_COVERAGE (err u104))
(define-constant ERR_INVALID_USER (err u105))
(define-constant ERR_NOT_COVERED (err u106))
(define-constant ERR_ZERO_VALUE (err u107))
(define-constant ERR_CLAIM_PROCESSED (err u108))
(define-constant ERR_EMPTY_RESERVE (err u109))
(define-constant ERR_PREMATURE_CLAIM (err u110))
(define-constant ERR_EXCESSIVE_CLAIM (err u111))

;; Core storage definitions
(define-data-var protection-pool uint u0)
(define-data-var contract-owner principal tx-sender)
(define-map protected-clients principal uint)
(define-map claim-history { claimant: principal, amount: uint } { status: (string-ascii 20), timestamp: uint, paid-amount: uint })

;; Claim expiration in blocks
(define-constant EXPIRATION_LIMIT u4320)

;; Register coverage
(define-public (register-coverage (coverage-amount uint))
  (let ((client tx-sender))
    (asserts! (> coverage-amount u0) ERR_ZERO_VALUE)
    (asserts! (is-none (map-get? protected-clients client)) ERR_DUPLICATE_COVERAGE)
    (match (stx-transfer? coverage-amount client (as-contract tx-sender))
      success (begin
        (var-set protection-pool (+ (var-get protection-pool) coverage-amount))
        (map-set protected-clients client coverage-amount)
        (print { event: "coverage-acquired", protected-value: coverage-amount, purchaser: client })
        (ok true))
      error (err error))))

;; Submit claim request
(define-public (submit-claim (claim-amount uint))
  (let (
    (client tx-sender)
    (protected-amount (default-to u0 (map-get? protected-clients client)))
  )
    (asserts! (> claim-amount u0) ERR_ZERO_VALUE)
    (asserts! (is-some (map-get? protected-clients client)) ERR_NOT_COVERED)
    (asserts! (>= protected-amount claim-amount) ERR_FUNDS_INSUFFICIENT)
    (asserts! (is-none (map-get? claim-history { claimant: client, amount: claim-amount })) ERR_CLAIM_PROCESSED)
    (map-set claim-history { claimant: client, amount: claim-amount } { status: "pending", timestamp: stacks-block-height, paid-amount: u0 })
    (print { event: "claim-requested", claimant: client, claim-amount: claim-amount, timestamp: stacks-block-height })
    (ok true)))

;; Calculate payout
(define-private (calculate-payout (claim-amount uint) (available-funds uint))
  (if (>= available-funds claim-amount)
      claim-amount
      available-funds))

;; Approve and process claim
(define-public (process-claim (claimant principal) (claim-amount uint))
  (let (
    (claim-key { claimant: claimant, amount: claim-amount })
    (claim-info (unwrap! (map-get? claim-history claim-key) ERR_NO_CLAIM_FOUND))
    (pool-balance (var-get protection-pool))
    (protected-amount (unwrap! (map-get? protected-clients claimant) ERR_NOT_COVERED))
  )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_ACCESS_DENIED)
    (asserts! (is-eq (get status claim-info) "pending") ERR_CLAIM_PROCESSED)
    (asserts! (> pool-balance u0) ERR_EMPTY_RESERVE)
    (asserts! (<= claim-amount protected-amount) ERR_EXCESSIVE_CLAIM)
    (asserts! (< (- stacks-block-height (get timestamp claim-info)) EXPIRATION_LIMIT) ERR_PREMATURE_CLAIM)
    (let ((payout-amount (calculate-payout claim-amount pool-balance)))
      (match (as-contract (stx-transfer? payout-amount tx-sender claimant))
        success (begin
          (var-set protection-pool (- pool-balance payout-amount))
          (if (< payout-amount claim-amount)
              (map-set claim-history claim-key { status: "partial", timestamp: stacks-block-height, paid-amount: payout-amount })
              (begin
                (map-delete claim-history claim-key)
                (map-delete protected-clients claimant)))
          (print { event: "claim-settled", claimant: claimant, claim-amount: claim-amount, payout: payout-amount })
          (ok payout-amount))
        error (err error)))))

;; Reject claim
(define-public (decline-claim (claimant principal) (claim-amount uint))
  (let (
    (claim-key { claimant: claimant, amount: claim-amount })
    (claim-info (unwrap! (map-get? claim-history claim-key) ERR_NO_CLAIM_FOUND))
  )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_ACCESS_DENIED)
    (asserts! (is-eq (get status claim-info) "pending") ERR_CLAIM_PROCESSED)
    (asserts! (< (- stacks-block-height (get timestamp claim-info)) EXPIRATION_LIMIT) ERR_PREMATURE_CLAIM)
    (map-set claim-history claim-key { status: "denied", timestamp: (get timestamp claim-info), paid-amount: u0 })
    (print { event: "claim-rejected", claimant: claimant, claim-amount: claim-amount })
    (ok true)))

;; Check current fund reserve
(define-read-only (check-reserve)
  (ok (var-get protection-pool)))
