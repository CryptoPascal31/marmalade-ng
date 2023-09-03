(module policy-dutch-auction-sale GOVERNANCE
  (implements token-policy-ng-v1)
  (use token-policy-ng-v1 [token-info])
  (use util-policies)
  (use ledger [NO-TIMEOUT account-guard])
  (use free.util-time [is-past is-future now])
  (use free.util-math)

  ;-----------------------------------------------------------------------------
  ; Governance
  ;-----------------------------------------------------------------------------
  (defconst ADMIN-KEYSET:string (read-string "admin_keyset"))
  (defcap GOVERNANCE ()
    (enforce-keyset ADMIN-KEYSET))

  ;-----------------------------------------------------------------------------
  ; Capabilities and events
  ;-----------------------------------------------------------------------------
  (defcap FORCE-WITHDRAW (sale-id:string)
    @doc "Capability to scope a signature when withdrawing an infinite timeout sale"
    true)

  ;-----------------------------------------------------------------------------
  ; Schemas and Tables
  ;-----------------------------------------------------------------------------
  (defschema quote-sch
    sale-id:string
    token-id:string
    seller-guard:guard
    amount:decimal
    escrow-account:string
    currency:module{fungible-v2}
    start-price:decimal
    end-price:decimal
    start-time:time
    end-time:time
    recipient:string
    timeout:time
    enabled:bool
  )

  (deftable quotes:{quote-sch})

  ;-----------------------------------------------------------------------------
  ; Input data
  ;-----------------------------------------------------------------------------
  (defschema dutch-quote-msg-sch
    start_price:decimal
    end_price:decimal
    end_time:time
    recipient:string

  )

  ;-----------------------------------------------------------------------------
  ; Util functions
  ;-----------------------------------------------------------------------------
  (defun sale-not-ended:bool ()
    (with-read quotes (pact-id) {'timeout:=timeout}
      (or? (= NO-TIMEOUT) (is-future) timeout)))

  (defun sale-ended:bool ()
    (with-read quotes (pact-id)  {'timeout:=timeout}
      (or? (= NO-TIMEOUT) (is-past) timeout)))

  (defun enforce-sale-ended:bool ()
    @doc "Enforce that the sale is ended"
    (let ((ended (sale-ended)))
      (enforce ended "Sale not ended")))

  (defun enforce-sale-not-ended:bool ()
    @doc "Enforce that the sale is not ended"
    (let ((not-ended (sale-not-ended)))
      (enforce not-ended "Sale ended")))

  (defun enforce-seller-guard:bool ()
    @doc "Enforce the seller in case of a no-timeout sale"
    (with-read quotes (pact-id) {'seller-guard:=seller-g, 'timeout:=tmout}
      (with-capability (FORCE-WITHDRAW (pact-id))
        (enforce-one "Seller must sign forced-withdrawal"
                     [(enforce (!= NO-TIMEOUT tmout) "") (enforce-guard seller-g)])))
  )

  (defun compute-price:decimal (sale-id:string)
    @doc "Compute the price with a geometric scale"
    (with-read quotes sale-id {'currency:=currency:module{fungible-v2},
                              'start-price:=start-price,
                              'end-price:=end-price,
                              'start-time:=start-time,
                              'end-time:=end-time}
      (let* ((price-ratio (exp  (/ (* (diff-time (now) start-time) (- (ln end-price) (ln start-price)))
                                   (diff-time end-time start-time))))
             (price:decimal (max end-price (* price-ratio start-price))))
        (floor price (currency::precision))))
  )

  (defun disable:bool ()
    @doc "Mark the sale as being disabled"
    (update quotes (pact-id) {'enabled: false})
    true)

  (defun read-dutch-quote-msg:object{dutch-quote-msg-sch} (token:object{token-info})
    (enforce-get-msg-data "dutch_quote" token))

  ;-----------------------------------------------------------------------------
  ; Policy hooks
  ;-----------------------------------------------------------------------------
  (defun rank:integer () 30)

  (defun enforce-init:bool (token:object{token-info})
    false)

  (defun enforce-mint:bool (token:object{token-info} account:string amount:decimal)
    false)

  (defun enforce-burn:bool (token:object{token-info} account:string amount:decimal)
    false)

  (defun enforce-transfer:bool (token:object{token-info} sender:string receiver:string amount:decimal)
    false)

  (defun enforce-sale-offer:bool (token:object{token-info} seller:string amount:decimal timeout:time)
    (require-capability (ledger.POLICY-ENFORCE-OFFER token (pact-id) policy-dutch-auction-sale))
      (bind (read-sale-msg token) {'sale_type:=sale-type,
                                   'currency:=currency:module{fungible-v2}}
        (if (= sale-type "dutch_auction")
          (bind (read-dutch-quote-msg token) {'start_price:=start-price,
                                              'end_price:=end-price,
                                              'end_time:=end-time,
                                              'recipient:=recipient}
            ; Do some basic checks
            (map  (check-price currency) [start-price end-price])
            (enforce (is-future end-time) "End time must be in the future")
            (enforce (or? (= NO-TIMEOUT) (< end-time) timeout) "Timeout must be later tha end-time")

            (enforce (< end-price start-price) "end-price must be less than start-price")

            ; Check that the recipient account already exist in the currency
            (check-fungible-account currency recipient)

            ; Insert teh quote intor the DB.
            (insert quotes (pact-id) {'sale-id: (pact-id),
                                      'token-id: (at 'id token),
                                      'seller-guard: (account-guard (at 'id token) seller),
                                      'amount:amount,
                                      'escrow-account: (ledger.escrow),
                                      'currency: currency,
                                      'start-price:start-price,
                                      'end-price:end-price,
                                      'start-time:(now),
                                      'end-time:end-time,
                                      'recipient: recipient,
                                      'timeout: timeout,
                                      'enabled: true})
              true)
            false))
  )

  (defun enforce-sale-withdraw:bool (token:object{token-info})
    (require-capability (ledger.POLICY-ENFORCE-WITHDRAW token (pact-id) policy-dutch-auction-sale))
    (enforce-sale-ended)
    (enforce-seller-guard)
    (disable)
  )

  (defun enforce-sale-buy:bool (token:object{token-info} buyer:string)
    (require-capability (ledger.POLICY-ENFORCE-BUY token (pact-id) policy-dutch-auction-sale))
    (enforce-sale-not-ended)
    ; First step to handle the buying part => Transfer the amount to the escrow account
    (with-read quotes (pact-id) {'currency:=currency:module{fungible-v2}}
      (currency::transfer-create buyer (ledger.escrow) (ledger.escrow-guard) (compute-price (pact-id))))
    true
    )

  (defun enforce-sale-settle:bool (token:object{token-info})
    (require-capability (ledger.POLICY-ENFORCE-SETTLE token (pact-id) policy-dutch-auction-sale))
    (with-read quotes (pact-id) {'amount:=amount,
                                 'currency:=currency:module{fungible-v2},
                                 'recipient:=recipient}
      ; The settle handler is called in the same transaction as the handler buy
      ; => Checking the timeout is not necessary
      ; Transfer the remaining from the escrow account to the recipient
      (let* ((escrow (ledger.escrow))
             (amount (currency::get-balance escrow)))
        (install-capability (currency::TRANSFER escrow recipient amount))
        (currency::transfer escrow recipient amount)))
    (disable)
  )

  ;-----------------------------------------------------------------------------
  ; Lcoal functions
  ;-----------------------------------------------------------------------------
  (defun get-all-active-sales:[object{quote-sch}] ()
    @doc "Returns all currently active sales"
    (select quotes (where 'enabled (=  true))))

  (defun get-sales-for-token:[object{quote-sch}] (token-id:string)
    @doc "Returns all currently actives sales related to a token"
    (select quotes (and? (where 'enabled (=  true))
                         (where 'token-id (= token-id)))))

  (defun get-sale:object{quote-sch} (sale-id:string)
    @doc "Returns the sale data of a prticular sale-id"
    (read quotes sale-id))

)