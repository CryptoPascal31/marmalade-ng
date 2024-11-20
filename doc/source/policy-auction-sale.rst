.. _POLICY-AUCTION-SALE:

policy-auction-sale
-------------------

Description
^^^^^^^^^^^

This policy manages an auction sale:
  - The seller of the token puts its token on sale and propose a starting price and a multiplier increment.
  - People proposes bids:
     - starting with at least the starting price
     - then by bidding a price that it is at least the last price multiplied by the increment.

Since the `(place-bid)` function is executed out of the defpact context, a second escrow account must be used during
the auctions. The funds from this second escrow account are then transferred to the main Marmalade escrow account before settlement.


This policy work in several steps:

1 - The seller calls the defpact ``sale``. The policy is triggered when ``sale_type`` = "auction".
The policy record the minimum price and the increment.

2 - Buyers call `(place-bid)` and transfers the amount of their bids to the escrow account.

2 - Once the timeout has elapsed, the seller, the buyer or anybody else complete the defpact. The dale amount is transferred to the main escrow account.

In the meantime, some policies with a higher priority (like marketplace or royalty) are allowed
to take a part of the funds from the escrow account.

3 - The ``(enforce-sale-settle)`` hook is called, and the seller is paid with the remaining funds.

The seller is able to withdraw from the sale after the ``timeout`` has elapsed if nobody has placed a bid.

This policy does not support the ``NO-TIMEOUT`` parameter.

Timeout extension
~~~~~~~~~~~~~~~~~
To keep auctions fair and avoid sniping and malicious activity: the timeout can be extended.

If a bid occurs less than 10 minutes before the end of the sale, the timeout is extended to 30 minutes after the bid time:

Examples:
  - The tiemout was previously set to: ``2023-01-03T06:00:00``, a bid arrives at ``2023-01-03T05:45:00`` => The tiemout is not changed.
  - The tiemout was previously set to: ``2023-01-03T06:00:00``, a bid arrives at ``2023-01-03T05:56:00`` => The tiemout is extended to ``2023-01-03T06:06:00``.

Shared fees
~~~~~~~~~~~
To be compatible with the shared fees feature of the ``MARKETPLACE`` policy, this policy includes some optional hints
to facilitate the integration of shared fees.

 - During a bid transaction, the data section may contain a `marmalade_shared_fee` object.
 - When the bid has been done with a `marmalade_shared_fee`, the sale ending (continue transaction), must contain exactly the same object.

The marmalade_shared_fee object can be retrieved using ``get-sale`` :ref:`POLICY-AUCTION-SALE-GET-SALE`


Implemented hooks
^^^^^^^^^^^^^^^^^

.. code:: lisp

  (defun enforce-sale-offer)

  (defun enforce-sale-withdraw)

  (defun enforce-sale-buy)

  (defun enforce-sale-settle)



Input data structures
^^^^^^^^^^^^^^^^^^^^^
marmalade_sale
~~~~~~~~~~~~~~
Handled by ``(enforce-sale-offer)``

.. code:: lisp

  (defschema sale-msg-sch
    sale_type:string ; Type of sale
    currency:module{fungible-v2} ; Currency of sale
  )

Mandatory to trigger the policy with ``sale_type`` = auction

auction
~~~~~~~
Handled by ``(enforce-sale-offer)``

.. code:: lisp

  (defschema auction-msg-sch
    start_price:decimal ; start price of the auction
    recipient:string ; recipient account
    increment_ratio:decimal ;increment ratio (multiplier) between each bid
  )

Mandatory

marmalade_shared_fee
~~~~~~~~~~~~~~~~~~~~
Handled by ``(enforce-sale-buy)`` and ``(place-bid)``

Optional object

.. code:: lisp

  (defschema shared-fee-msg
    recipient:string ; Recipient account for the shared-fee
  )



External functions
^^^^^^^^^^^^^^^^^^

.. _POLICY-AUCTION-SALE-PLACE-BID:

place-bid
~~~~~~~~~
*sale-id* ``string`` *buyer* ``string`` *buyer-guard* ``guard`` *new-price* ``decimal``  *→* ``string``

Place a new bid on the given sale-id.

The bidder should before call ``(get-sale)`` to check the current state of the sale:

- current-price
- escrow account
- increment

The bidder must have installed the TRANSFER capability of the payment currency.

The previous best buyer is automatically refunded.

.. code:: lisp

  (use marmalade-ng.policy-auction-sale)
  (place-bid "utRLLLbDcGyMnBcuPDjo-VaxR_65Wxv2v8EhoD9z4-E" "r:user.rich-buyer"
             (keyset-ref-guard "user.rich-buyer") 25.0)




View functions
^^^^^^^^^^^^^^

.. _POLICY-AUCTION-SALE-GET-SALE:

get-sale
~~~~~~~~
*sale-id* ``string`` *→* ``object{auction-sch}``

Return the sale details of a given sale-id.

.. code:: lisp

  (use marmalade-ng.policy-auction-sale)
  (get-sale "utRLLLbDcGyMnBcuPDjo-VaxR_65Wxv2v8EhoD9z4-E")

.. code-block::

  {"amount": 0.1,
   "currency": coin,
   "current-buyer": "",
   "current-price": 0.0,
   "enabled": true,
   "escrow-account": "c:09-juxzBu412pfsgBlM6Au7fOnwvSsX78Er66vnC6sI",
   "increment-ratio": 1.1,
   "recipient": "alice",
   "sale-id": "",
   "seller": "alice",
   "start-price": 10.0,
   "timeout": "2023-06-01T00:00:00Z",
   "token-id": "t:LWZdYIxjht_J_PCA4RrThTdjD9VDCvkWabnh8tKNST8"
  }

get-sales-for-token
~~~~~~~~~~~~~~~~~~~
*token-id* ``string`` *→* ``[object{auction-sch}]``

Return all the active sales details for a given token.

**Important**: Local only function. Do not use in transactions

.. code:: lisp

  (use marmalade-ng.policy-auction-sale)
  (get-sales-for-token "t:LWZdYIxjht_J_PCA4RrThTdjD9VDCvkWabnh8tKNST8")

.. code-block::

  [{"amount": 0.1,
     "currency": coin,
     "current-buyer": "",
     "current-price": 0.0,
     "enabled": true,
     "escrow-account": "c:09-juxzBu412pfsgBlM6Au7fOnwvSsX78Er66vnC6sI",
     "increment-ratio": 1.1,
     "recipient": "alice",
     "sale-id": "",
     "seller": "alice",
     "shared-fee": {"recipient":""},
     "start-price": 10.0,
     "timeout": "2023-06-01T00:00:00Z",
     "token-id": "t:LWZdYIxjht_J_PCA4RrThTdjD9VDCvkWabnh8tKNST8"
    }]


.. _POLICY-AUCTION-SALE-GET-SALES-FROM-ACCOUNT:

get-sales-from-account
~~~~~~~~~~~~~~~~~~~~~~~
*account* ``string`` *→* ``[object{auction-sch}]``

Return all the active sales details initiated by a given account.

**Important**: Local only function. Do not use in transactions


.. code:: lisp

  (use marmalade-ng.policy-auction-sale)
  (get-sales-from-account "alice")

.. code-block::

  [{"amount": 0.1,
     "currency": coin,
     "current-buyer": "",
     "current-price": 0.0,
     "enabled": true,
     "escrow-account": "c:09-juxzBu412pfsgBlM6Au7fOnwvSsX78Er66vnC6sI",
     "increment-ratio": 1.1,
     "recipient": "alice",
     "sale-id": "",
     "seller": "alice",
     "shared-fee": {"recipient":""},
     "start-price": 10.0,
     "timeout": "2023-06-01T00:00:00Z",
     "token-id": "t:LWZdYIxjht_J_PCA4RrThTdjD9VDCvkWabnh8tKNST8"
    },

   {"amount": 0.5,
    "currency": coin,
    "current-buyer": "",
    "current-price": 0.0,
    "enabled": true,
    "escrow-account": "c:_xRzg2I2WJu1hov-d8HmuKGq0Kxr5hndunDnkbFpu0Q",
    "increment-ratio": 1.1,
    "recipient": "alice",
    "sale-id": "DmxMgittQd4Duf0WQdeySZkx_I4yvQ3phecLpWMzmw8",
    "seller": "alice",
    "shared-fee": {"recipient":""},
    "start-price": 10.0,
    "timeout": "2023-06-01T00:00:00Z",
    "token-id": "t:sMd0A3s6ZoiHd0RCzZ3XqVcTmOcoNvi73hl1gWXUMSA"}
  ]



.. _POLICY-AUCTION-SALE-GET-ALL-ACTIVE-SALES:

get-all-active-sales
~~~~~~~~~~~~~~~~~~~~
*→* ``[object{auction-sch}]``

Return all the active sales details.

**Important**: Local only function. Do not use in transactions


.. code:: lisp

  (use marmalade-ng.policy-auction-sale)
  (get-all-active-sales)

.. code-block::

  [{"amount": 0.1,
     "currency": coin,
     "current-buyer": "",
     "current-price": 0.0,
     "enabled": true,
     "escrow-account": "c:09-juxzBu412pfsgBlM6Au7fOnwvSsX78Er66vnC6sI",
     "increment-ratio": 1.1,
     "recipient": "alice",
     "sale-id": "",
     "seller": "alice",
     "shared-fee": {"recipient":""},
     "start-price": 10.0,
     "timeout": "2023-06-01T00:00:00Z",
     "token-id": "t:LWZdYIxjht_J_PCA4RrThTdjD9VDCvkWabnh8tKNST8"
    },

   {"amount": 0.5,
    "currency": coin,
    "current-buyer": "",
    "current-price": 0.0,
    "enabled": true,
    "escrow-account": "c:_xRzg2I2WJu1hov-d8HmuKGq0Kxr5hndunDnkbFpu0Q",
    "increment-ratio": 1.1,
    "recipient": "alice",
    "sale-id": "DmxMgittQd4Duf0WQdeySZkx_I4yvQ3phecLpWMzmw8",
    "seller": "alice",
    "shared-fee": {"recipient":""},
    "start-price": 10.0,
    "timeout": "2023-06-01T00:00:00Z",
    "token-id": "t:sMd0A3s6ZoiHd0RCzZ3XqVcTmOcoNvi73hl1gWXUMSA"}
  ]


get-ended-sales
~~~~~~~~~~~~~~~
*→* ``[object{auction-sch}]``

Return all ended sales:
  - The timeout has expired.
  - The sale's defpact is required to be closed (with a standard or a rollback continuation)

**Important**: Local only function. Do not use in transactions


.. code:: lisp

  (use marmalade-ng.policy-auction-sale)
  (get-ended-sales)

.. code-block::

  [{"amount": 0.1,
     "currency": coin,
     "current-buyer": "",
     "current-price": 0.0,
     "enabled": true,
     "escrow-account": "c:09-juxzBu412pfsgBlM6Au7fOnwvSsX78Er66vnC6sI",
     "increment-ratio": 1.1,
     "recipient": "alice",
     "sale-id": "DmxMgittQd4Duf0WQdeySZkx_I4yvQ3phecLpWMzmw8",
     "seller": "alice",
     "shared-fee": {"recipient":""},
     "start-price": 10.0,
     "timeout": "2023-06-01T00:00:00Z",
     "token-id": "t:LWZdYIxjht_J_PCA4RrThTdjD9VDCvkWabnh8tKNST8"
    }
  ]

Events
^^^^^^
AUCTION-SALE-OFFER
~~~~~~~~~~~~~~~~~~
sale-id* ``string`` *token-id* ``string`` *start-price* ``decimal`` *currency* ``string``

Event sent when an auction is started


PLACE-BID
~~~~~~~~~~~~~~~~
*sale-id* ``string`` *token-id* ``string`` *buyer* ``string`` *price* ``decimal`` *currency* ``string``

Event emitted when a bid is placed for the sale.


AUCTION-SALE-BOUGHT
~~~~~~~~~~~~~~~~~~~
sale-id* ``string`` *token-id* ``string`` *buy-price* ``decimal`` *currency* ``string``

Event sent when an auction has ended


AUCTION-SALE-WITHDRAWN
~~~~~~~~~~~~~~~~~~~~~~
sale-id* ``string`` *token-id* ``string``

Event sent when an auction has been withdrawn because there is no bid
