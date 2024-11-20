.. _POLICY-DUTCH-AUCTION-SALE:

policy-dutch-auction-sale
-------------------------

Description
^^^^^^^^^^^

This policy manages a Dutch Auction Sale:

The seller choose a starting price, an ending price and a duration.
The price automatically decreases until someone wants to buy it.

This policy is very similar to :ref:`POLICY-FIXED-SALE`.

The price is calculated using the following formula:

- **exp ( (Elapsed Time / Total time) * ( log(end-price) - log(start-price)))**

After all the allowed time has been elapsed, and the floor price has been reached, the price stay
constant until the sale timeout is reached.

Note: ``NO-TIMEOUT`` is supported.

.. image:: diagrams/dutch_auction.svg

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

Mandatory to trigger the policy with ``sale_type`` = dutch_auction

dutch_quote
~~~~~~~~~~~
Handled by ``(enforce-sale-offer)``

.. code:: lisp

  (defschema dutch-quote-msg-sch
    start_price:decimal ; Starting price
    end_price:decimal ; End price (reached at end time, and until timeout)
    end_time:time ; End time: end of the price decrease ramp
    recipient:string ; Recipient of the payment
  )

Mandatory


External functions
^^^^^^^^^^^^^^^^^^
Nope


View functions
^^^^^^^^^^^^^^
get-sale
~~~~~~~~
*sale-id* ``string`` *→* ``object{quote-sch}``

Return the sale details of a given sale-id.

.. code:: lisp

  (use marmalade-ng.policy-dutch-auction-sale)
  (get-sale "vGA9N7tLIhStJCwKPqWvlXJ5cCDkgLPh8pfhgilLPas")

.. code-block::

  {"amount": 0.1,
   "currency": coin,
   "enabled": true,
   "end-price": 1.0,
   "end-time": "2023-01-05T00:00:00Z",
   "escrow-account": "c:uZK0n0opPMtEMAOctKX2S-nNa3KCotC9TBQCnXPOYeY",
   "recipient": "alice",
   "sale-id": "vGA9N7tLIhStJCwKPqWvlXJ5cCDkgLPh8pfhgilLPas",
   "seller": "alice",
   "seller-guard": KeySet {keys: [alice-key],pred: keys-all},
   "start-price": 100.0,"start-time": "2023-01-01T00:00:00Z",
   "timeout": "2023-06-01T00:00:00Z",
   "token-id": "t:jH6cLnR-L_tehD874FGubaGQ0zx9BTxzlh8ENcXqWxc"
  }


get-sales-for-token
~~~~~~~~~~~~~~~~~~~
*token-id* ``string`` *→* ``[object{quote-sch}]``

Return all the active sales details for a given token.

**Important**: Local only function. Do not use in transactions

.. code:: lisp

  (use marmalade-ng.policy-dutch-auction-sale)
  (get-sales-for-token "t:jH6cLnR-L_tehD874FGubaGQ0zx9BTxzlh8ENcXqWxc")

.. code-block::

  [{"amount": 0.1,
   "currency": coin,
   "enabled": true,
   "end-price": 1.0,
   "end-time": "2023-01-05T00:00:00Z",
   "escrow-account": "c:uZK0n0opPMtEMAOctKX2S-nNa3KCotC9TBQCnXPOYeY",
   "recipient": "alice",
   "sale-id": "vGA9N7tLIhStJCwKPqWvlXJ5cCDkgLPh8pfhgilLPas",
   "seller": "alice",
   "seller-guard": KeySet {keys: [alice-key],pred: keys-all},
   "start-price": 100.0,"start-time": "2023-01-01T00:00:00Z",
   "timeout": "2023-06-01T00:00:00Z",
   "token-id": "t:jH6cLnR-L_tehD874FGubaGQ0zx9BTxzlh8ENcXqWxc"
  }]

.. _POLICY-DUTCH-AUCTION-SALE-GET-SALES-FROM-ACCOUNT:

get-sales-from-account
~~~~~~~~~~~~~~~~~~~~~~
*account* ``string`` *→* ``[object{quote-sch}]``

Return all the active sales details initiated by a given account.

**Important**: Local only function. Do not use in transactions


.. code:: lisp

  (use marmalade-ng.policy-dutch-auction-sale)
  (get-sales-from-account "alice")

.. code-block::

  [{"amount": 0.1,
   "currency": coin,
   "enabled": true,
   "end-price": 1.0,
   "end-time": "2023-01-05T00:00:00Z",
   "escrow-account": "c:uZK0n0opPMtEMAOctKX2S-nNa3KCotC9TBQCnXPOYeY",
   "recipient": "alice",
   "sale-id": "vGA9N7tLIhStJCwKPqWvlXJ5cCDkgLPh8pfhgilLPas",
   "seller": "alice",
   "seller-guard": KeySet {keys: [alice-key],pred: keys-all},
   "start-price": 100.0,"start-time": "2023-01-01T00:00:00Z",
   "timeout": "2023-06-01T00:00:00Z",
   "token-id": "t:jH6cLnR-L_tehD874FGubaGQ0zx9BTxzlh8ENcXqWxc"
   },

   {"amount": 0.1,
    "currency": coin,
    "enabled": true,
    "end-price": 1.0,
    "end-time": "2023-01-05T00:00:00Z",
    "escrow-account": "c:RofYomFLW13xvivg2XjN3MykJG_1hNRfDvV4W2DjdNU",
    "recipient": "alice",
    "sale-id": "MdXO502ljyF-O6YJV-ODmTuhqFF2Zn6Wa0ONQZu1P8o",
    "seller": "alice",
    "seller-guard": KeySet {keys: [alice-key],pred: keys-all},
    "start-price": 100.0,"start-time": "2023-01-01T00:00:00Z",
    "timeout": "2023-06-01T00:00:00Z",
    "token-id": "t:r-4jQUrZWpYfEqq_iGvBn1ofgCLPoh2ZfG5kfAVX2KM"
   }]


get-all-active-sales
~~~~~~~~~~~~~~~~~~~~
*→* ``[object{quote-sch}]``

Return all the active sales details.

**Important**: Local only function. Do not use in transactions


.. code:: lisp

  (use marmalade-ng.policy-dutch-auction-sale)
  (get-all-active-sales)

.. code-block::

  [{"amount": 0.1,
   "currency": coin,
   "enabled": true,
   "end-price": 1.0,
   "end-time": "2023-01-05T00:00:00Z",
   "escrow-account": "c:uZK0n0opPMtEMAOctKX2S-nNa3KCotC9TBQCnXPOYeY",
   "recipient": "alice",
   "sale-id": "vGA9N7tLIhStJCwKPqWvlXJ5cCDkgLPh8pfhgilLPas",
   "seller": "alice",
   "seller-guard": KeySet {keys: [alice-key],pred: keys-all},
   "start-price": 100.0,"start-time": "2023-01-01T00:00:00Z",
   "timeout": "2023-06-01T00:00:00Z",
   "token-id": "t:jH6cLnR-L_tehD874FGubaGQ0zx9BTxzlh8ENcXqWxc"
   },

   {"amount": 0.1,
    "currency": coin,
    "enabled": true,
    "end-price": 1.0,
    "end-time": "2023-01-05T00:00:00Z",
    "escrow-account": "c:RofYomFLW13xvivg2XjN3MykJG_1hNRfDvV4W2DjdNU",
    "recipient": "alice",
    "sale-id": "MdXO502ljyF-O6YJV-ODmTuhqFF2Zn6Wa0ONQZu1P8o",
    "seller": "alice",
    "seller-guard": KeySet {keys: [alice-key],pred: keys-all},
    "start-price": 100.0,"start-time": "2023-01-01T00:00:00Z",
    "timeout": "2023-06-01T00:00:00Z",
    "token-id": "t:r-4jQUrZWpYfEqq_iGvBn1ofgCLPoh2ZfG5kfAVX2KM"
   }]


Events
^^^^^^
DUTCH-AUCTION-SALE-OFFER
~~~~~~~~~~~~~~~~~~~~~~~~
sale-id* ``string`` *token-id* ``string`` *start-price* ``decimal`` *currency* ``string``

Event sent when an auction is started


DUTCH-AUCTION-SALE-BOUGHT
~~~~~~~~~~~~~~~~~~~~~~~~~
sale-id* ``string`` *token-id* ``string`` *buy-price* ``decimal`` *currency* ``string``

Event sent when a dutch auction sale is bought


DUTCH-AUCTION-SALE-WITHDRAWN
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sale-id* ``string`` *token-id* ``string``

Event sent when a dutch auction sale is withdrawn
