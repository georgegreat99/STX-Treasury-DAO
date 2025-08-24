;; Treasury DAO Smart Contract
;; A DAO that manages community funds with weighted voting

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-MEMBER (err u101))
(define-constant ERR-NOT-MEMBER (err u102))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u103))
(define-constant ERR-VOTING-CLOSED (err u104))
(define-constant ERR-ALREADY-VOTED (err u105))
(define-constant ERR-INSUFFICIENT-FUNDS (err u106))
(define-constant ERR-PROPOSAL-NOT-PASSED (err u107))

(define-constant CONTRACT-OWNER tx-sender)

;; Data Variables
(define-data-var proposal-counter uint u0)
(define-data-var total-voting-power uint u0)

;; Data Maps
(define-map members principal {voting-power: uint, joined-at: uint})
(define-map proposals uint {
    title: (string-utf8 100),
    description: (string-utf8 500),
    amount: uint,
    recipient: principal,
    creator: principal,
    created-at: uint,
    voting-deadline: uint,
    yes-votes: uint,
    no-votes: uint,
    executed: bool
})
(define-map votes {proposal-id: uint, voter: principal} {vote: bool, voting-power: uint})

;; Member Management Functions
(define-public (add-member (member principal) (voting-power uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (is-none (map-get? members member)) ERR-ALREADY-MEMBER)
        (map-set members member {
            voting-power: voting-power,
            joined-at: block-height
        })
        (var-set total-voting-power (+ (var-get total-voting-power) voting-power))
        (ok true)
    )
)

(define-public (update-member-voting-power (member principal) (new-power uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (match (map-get? members member)
            member-data (begin
                (var-set total-voting-power 
                    (+ (- (var-get total-voting-power) (get voting-power member-data)) new-power))
                (map-set members member (merge member-data {voting-power: new-power}))
                (ok true)
            )
            ERR-NOT-MEMBER
        )
    )
)

;; Proposal Functions
(define-public (create-proposal (title (string-utf8 100)) (description (string-utf8 500)) (amount uint) (recipient principal))
    (let ((proposal-id (+ (var-get proposal-counter) u1)))
        (asserts! (is-some (map-get? members tx-sender)) ERR-NOT-MEMBER)
        (map-set proposals proposal-id {
            title: title,
            description: description,
            amount: amount,
            recipient: recipient,
            creator: tx-sender,
            created-at: block-height,
            voting-deadline: (+ block-height u144), ;; ~24 hours (assuming 10 min blocks)
            yes-votes: u0,
            no-votes: u0,
            executed: false
        })
        (var-set proposal-counter proposal-id)
        (ok proposal-id)
    )
)

(define-public (vote (proposal-id uint) (vote-yes bool))
    (let ((member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
          (proposal-data (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
          (voting-power (get voting-power member-data)))
        (asserts! (<= block-height (get voting-deadline proposal-data)) ERR-VOTING-CLOSED)
        (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR-ALREADY-VOTED)

        (map-set votes {proposal-id: proposal-id, voter: tx-sender} {
            vote: vote-yes,
            voting-power: voting-power
        })

        (if vote-yes
            (map-set proposals proposal-id 
                (merge proposal-data {yes-votes: (+ (get yes-votes proposal-data) voting-power)}))
            (map-set proposals proposal-id 
                (merge proposal-data {no-votes: (+ (get no-votes proposal-data) voting-power)}))
        )
        (ok true)
    )
)

(define-public (execute-proposal (proposal-id uint))
    (let ((proposal-data (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND)))
        (asserts! (> block-height (get voting-deadline proposal-data)) ERR-VOTING-CLOSED)
        (asserts! (not (get executed proposal-data)) ERR-PROPOSAL-NOT-PASSED)
        (asserts! (> (get yes-votes proposal-data) (get no-votes proposal-data)) ERR-PROPOSAL-NOT-PASSED)
        (asserts! (>= (stx-get-balance (as-contract tx-sender)) (get amount proposal-data)) ERR-INSUFFICIENT-FUNDS)

        (try! (as-contract (stx-transfer? (get amount proposal-data) tx-sender (get recipient proposal-data))))
        (map-set proposals proposal-id (merge proposal-data {executed: true}))
        (ok true)
    )
)

;; Treasury Management
(define-public (deposit-funds)
    (stx-transfer? (stx-get-balance tx-sender) tx-sender (as-contract tx-sender))
)

;; Read-only Functions
(define-read-only (get-member (member principal))
    (map-get? members member)
)

(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes {proposal-id: proposal-id, voter: voter})
)

(define-read-only (get-treasury-balance)
    (stx-get-balance (as-contract tx-sender))
)

(define-read-only (get-total-voting-power)
    (var-get total-voting-power)
)

(define-read-only (get-proposal-count)
    (var-get proposal-counter)
)

(define-read-only (is-proposal-passed (proposal-id uint))
    (match (map-get? proposals proposal-id)
        proposal-data (and 
            (> block-height (get voting-deadline proposal-data))
            (> (get yes-votes proposal-data) (get no-votes proposal-data))
        )
        false
    )
)