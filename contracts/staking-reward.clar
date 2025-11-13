;; stx-staking-rewards-v2.clar
;; Advanced DeFi staking contract on Stacks blockchain
;; Stake STX, earn rewards, compound, and manage staking pools.

(define-constant ERR_NOT_OWNER u100)
(define-constant ERR_INVALID_AMOUNT u101)
(define-constant ERR_NO_STAKE u102)
(define-constant ERR_STAKE_LOCKED u103)
(define-constant ERR_PAUSED u104)
(define-constant ERR_NO_REWARDS u105)

;; --------------------------------------
;; State and data
;; --------------------------------------
(define-data-var owner principal tx-sender)
(define-data-var paused bool false)

(define-data-var total-staked uint u0)
(define-data-var total-rewards-distributed uint u0)
(define-data-var reward-pool uint u0)
(define-data-var reward-rate-per-block uint u1000)
(define-data-var lock-period uint u100)

;; Each user's stake info
(define-map stakes principal
  (tuple
    (amount uint)
    (start-height uint)
    (pending-rewards uint)
    (last-claimed uint)
  )
)

;; Leaderboard: simple sum of user stakes
(define-map leaderboard principal uint)

;; --------------------------------------
;; Internal helper functions
;; --------------------------------------

(define-private (only-owner)
  (if (is-eq tx-sender (var-get owner))
      (ok true)
      (err ERR_NOT_OWNER))
)

(define-private (when-not-paused)
  (if (var-get paused)
      (err ERR_PAUSED)
      (ok true))
)

;; Calculate rewards for a user
(define-private (calculate-rewards (user principal))
  (let ((stake (map-get? stakes user)))
    (match stake
      s
        (let (
              (amount (get amount s))
              (last-claimed (get last-claimed s))
              (blocks u0)
             )
          (if (> blocks u0)
            (/ (* amount (* blocks (var-get reward-rate-per-block))) u1000000)
            u0))
      u0)
  )
)

;; --------------------------------------
;; Admin functions
;; --------------------------------------

(define-public (pause)
  (begin
    (try! (only-owner))
    (var-set paused true)
    (ok "Contract paused"))
)

(define-public (unpause)
  (begin
    (try! (only-owner))
    (var-set paused false)
    (ok "Contract resumed"))
)




;; Owner can add more rewards (fund the pool)
(define-public (add-rewards (amount uint))
  (if (> amount u0)
      (begin
        (var-set reward-pool (+ (var-get reward-pool) amount))
        (ok amount))
      (err ERR_INVALID_AMOUNT))
)

;; --------------------------------------
;; User functions
;; --------------------------------------

;; Stake STX
(define-public (stake (amount uint))
  (if (<= amount u0)
    (err ERR_INVALID_AMOUNT)
    (begin
      (try! (when-not-paused))
      (let ((current (map-get? stakes tx-sender)))
        (if (is-some current)
          (let ((s (unwrap-panic current))
                (new-amount (+ (get amount s) amount)))
            (begin
              (map-set stakes tx-sender
                (tuple
                  (amount new-amount)
                  (start-height u0)
                  (pending-rewards (+ (get pending-rewards s) (calculate-rewards tx-sender u0)))
                  (last-claimed u0)))
              (map-set leaderboard tx-sender new-amount)
              (var-set total-staked (+ (var-get total-staked) amount))
              (ok amount)))
          (begin
            (map-set stakes tx-sender
              (tuple
                (amount amount)
                (start-height u0)
                (pending-rewards u0)
                (last-claimed u0)))
            (map-set leaderboard tx-sender amount)
            (var-set total-staked (+ (var-get total-staked) amount))
            (ok amount))))))
)

(define-public (claim-rewards)
  (begin
    (try! (when-not-paused))
    (let ((reward (calculate-rewards tx-sender)))
      (if (and (> reward u0) (>= (var-get reward-pool) reward))
        (begin
          (try! (stx-transfer? reward (as-contract tx-sender) tx-sender))
          (match (map-get? stakes tx-sender)
            s (begin
                (map-set stakes tx-sender
                  (tuple
                    (amount (get amount s))
                    (start-height (get start-height s))
                    (pending-rewards u0)
                    (last-claimed u0)))
                (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) reward))
                (var-set reward-pool (- (var-get reward-pool) reward))
                (ok reward))
            (begin
              (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) reward))
              (var-set reward-pool (- (var-get reward-pool) reward))
              (ok reward))))
        (err ERR_NO_REWARDS))))
)

(define-public (compound-rewards)
  (begin
    (try! (when-not-paused))
    (let ((reward (calculate-rewards tx-sender)))
      (if (and (> reward u0) (>= (var-get reward-pool) reward))
        (match (map-get? stakes tx-sender)
          s (let ((new-amount (+ (get amount s) reward)))
              (begin
                (map-set stakes tx-sender
                  (tuple
                    (amount new-amount)
                    (start-height (get start-height s))
                    (pending-rewards u0)
                    (last-claimed u0)))
                (map-set leaderboard tx-sender new-amount)
                (var-set total-staked (+ (var-get total-staked) reward))
                (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) reward))
                (var-set reward-pool (- (var-get reward-pool) reward))
                (ok new-amount)))
          (err ERR_NO_STAKE))
        (err ERR_NO_REWARDS))))
)

;; Unstake STX (after lock period)
(define-public (unstake)
  (match (map-get? stakes tx-sender)
    s (let (
          (amount (get amount s))
          (start (get start-height s))
          (blocks u0)
         )
      (if (>= blocks (var-get lock-period))
          (begin
            (try! (stx-transfer? amount (as-contract tx-sender) tx-sender))
            (var-set total-staked (- (var-get total-staked) amount))
            (map-delete stakes tx-sender)
            (map-delete leaderboard tx-sender)
            (ok amount))
          (err ERR_STAKE_LOCKED)))
    (err ERR_NO_STAKE))
)
;; Emergency unstake (for emergencies - forfeits rewards)
(define-public (emergency-unstake)
  (match (map-get? stakes tx-sender)
    s (let ((amount (get amount s)))
        (begin
          (try! (stx-transfer? amount (as-contract tx-sender) tx-sender))
          (var-set total-staked (- (var-get total-staked) amount))
          (map-delete stakes tx-sender)
          (map-delete leaderboard tx-sender)
          (ok amount)))
    (err ERR_NO_STAKE))
)

;; --------------------------------------
;; Read-only views
;; --------------------------------------

(define-read-only (get-owner) (var-get owner))
(define-read-only (is-paused) (var-get paused))
(define-read-only (get-total-staked) (var-get total-staked))
(define-read-only (get-reward-pool) (var-get reward-pool))
(define-read-only (get-total-rewards) (var-get total-rewards-distributed))
(define-read-only (get-lock-period) (var-get lock-period))
(define-read-only (get-reward-rate) (var-get reward-rate-per-block))

(define-read-only (get-stake-info (user principal))
  (map-get? stakes user)
)

(define-read-only (get-leaderboard-entry (user principal))
  (default-to u0 (map-get? leaderboard user))
)
