.. _POLICY-FIXED-SALE:

policy-fixed-sale
-----------------

Description
^^^^^^^^^^^

This policy manages a fixed quote sale:
  - The seller of the token puts its token on sale and proposes a price.
  - The first person that is willing to pay the requested price buys the token.

This policy work in several steps:

1 - The seller call the defpact ``sale``. The policy is triggered when ``sale_type`` = "fixed".
The policy record the requested price.

2 - The buyer chose to buy and complete the defpact. In the `(enforce-sale-buy)` hook, the price
is transferred to the escrow account.

In the meantime, some policies with a higher priority (like marketplace or royalty) are allowed
to take a part of the funds from the escrow account.

3 - The ``(enforce-sale-setlle)`` hook is called, and the seller is paid with the remaining funds.

The buyer must complete the Pact before the ``timeout``.

The seller is able to withdraw from the sale after the ``timeout`` has elapsed.


Although, this policy supports the ``NO-TIMEOUT`` parameter.

When used, there is no time-limit to buy. But the seller can withdraw at any time, by signing with its Marmalade account guard
(can be scoped with ``(FORCE-WITHDRAW sale-id)``).

Seller and Recipient
^^^^^^^^^^^^^^^^^^^^
This policy manages two differents concepts:

* seller: The account that was previously owning the Token. This information comes from the ledger itself.
* recipient: The account that will receive the payment. The information is set-up through the `fixed_quote` structure.

These two pieces of information may be the same, but it's not mandatory. Indeed, theoretically, correlation is not required between fungible accounts and Marmalade's accounts.


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

Mandatory to trigger the policy with ``sale_type`` = fixed

fixed_quote
~~~~~~~~~~~
Handled by ``(enforce-sale-offer)``

.. code:: lisp

  (defschema fixed-quote-msg-sch
    price:decimal ; Proposed price
    recipient:string ; Recipient account
  )

Mandatory


External functions
^^^^^^^^^^^^^^^^^^
Nope


View functions
^^^^^^^^^^^^^^

.. _POLICY-FIXED-SALE-GET-SALE:

get-sale
~~~~~~~~
*sale-id* ``string`` *→* ``object{quote-sch}``

Return the sale details of a given sale-id.

.. code:: lisp

  (use marmalade-ng.policy-fixed-sale)
  (get-sale "vGA9N7tLIhStJCwKPqWvlXJ5cCDkgLPh8pfhgilLPas")

.. code-block::

  {"amount": 0.1,
   "enabled": true,
   "escrow-account": "c:uZK0n0opPMtEMAOctKX2S-nNa3KCotC9TBQCnXPOYeY",
   "fungible": coin,
   "price": 5.0,
   "recipient": "k:91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336",
   "sale-id": "vGA9N7tLIhStJCwKPqWvlXJ5cCDkgLPh8pfhgilLPas",
   "seller": "k:91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336",
   "seller-guard": KeySet {keys: ["91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336"],pred: keys-all},
   "timeout": "2023-06-01T00:00:00Z",
   "token-id": "t:r-4jQUrZWpYfEqq_iGvBn1ofgCLPoh2ZfG5kfAVX2KM"
   }

.. _POLICY-FIXED-SALE-GET-SALES-FROM-ACCOUNT:

get-sales-from-account
~~~~~~~~~~~~~~~~~~~~~~
*account* ``string`` *→* ``[object{quote-sch}]``

Return all the active sales details initiated by a given account.

**Important**: Local only function. Do not use in transactions

.. code:: lisp

  (use marmalade-ng.policy-fixed-sale)
  (get-sales-from-account "k:91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336")

.. code-block::

  [{"amount": 0.1,
   "enabled": true,
   "escrow-account": "c:uZK0n0opPMtEMAOctKX2S-nNa3KCotC9TBQCnXPOYeY",
   "fungible": coin,
   "price": 5.0,
   "recipient": "k:91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336",
   "sale-id": "vGA9N7tLIhStJCwKPqWvlXJ5cCDkgLPh8pfhgilLPas",
   "seller": "k:91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336",
   "seller-guard": KeySet {keys: ["91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336"],pred: keys-all},
   "timeout": "2023-06-01T00:00:00Z",
   "token-id": "t:r-4jQUrZWpYfEqq_iGvBn1ofgCLPoh2ZfG5kfAVX2KM"
   }]


get-sales-for-token
~~~~~~~~~~~~~~~~~~~
*token-id* ``string`` *→* ``[object{quote-sch}]``

Return all the active sales details for a given token.

**Important**: Local only function. Do not use in transactions

.. code:: lisp

  (use marmalade-ng.policy-fixed-sale)
  (get-sales-for-token "t:r-4jQUrZWpYfEqq_iGvBn1ofgCLPoh2ZfG5kfAVX2KM")

.. code-block::

  [{"amount": 0.1,
   "enabled": true,
   "escrow-account": "c:uZK0n0opPMtEMAOctKX2S-nNa3KCotC9TBQCnXPOYeY",
   "fungible": coin,
   "price": 5.0,
   "recipient": "k:91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336",
   "sale-id": "vGA9N7tLIhStJCwKPqWvlXJ5cCDkgLPh8pfhgilLPas",
   "seller": "k:91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336",
   "seller-guard": KeySet {keys: ["91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336"],pred: keys-all},
   "timeout": "2023-06-01T00:00:00Z",
   "token-id": "t:r-4jQUrZWpYfEqq_iGvBn1ofgCLPoh2ZfG5kfAVX2KM"
   }]


.. _POLICY-FIXED-SALE-GET-ALL-ACTIVE-SALES:

get-all-active-sales
~~~~~~~~~~~~~~~~~~~~
*→* ``[object{quote-sch}]``

Return all the active sales details.

**Important**: Local only function. Do not use in transactions


.. code:: lisp

  (use marmalade-ng.policy-fixed-sale)
  (get-all-active-sales)

.. code-block::

  [{"amount": 0.1,
   "enabled": true,
   "escrow-account": "c:uZK0n0opPMtEMAOctKX2S-nNa3KCotC9TBQCnXPOYeY",
   "fungible": coin,
   "price": 5.0,
   "recipient": "k:91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336",
   "sale-id": "vGA9N7tLIhStJCwKPqWvlXJ5cCDkgLPh8pfhgilLPas",
   "seller": "k:91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336",
   "seller-guard": KeySet {keys: ["91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336"],pred: keys-all},
   "timeout": "2023-06-01T00:00:00Z",
   "token-id": "t:r-4jQUrZWpYfEqq_iGvBn1ofgCLPoh2ZfG5kfAVX2KM"
   },

   {"amount": 1.6,
    "enabled": true,
    "escrow-account": "c:RofYomFLW13xvivg2XjN3MykJG_1hNRfDvV4W2DjdNU",
    "fungible": coin,
    "price": 8.0,
    "recipient": "k:91c9fc1e6943613eb7017e895a15b5147d273a2e1b1450d27ea67139b8a1b336",
    "sale-id": "MdXO502ljyF-O6YJV-ODmTuhqFF2Zn6Wa0ONQZu1P8o",
    "seller": "k:5389405a22b8376211f2c98bc79e72a9b9b0533da5c3c28f0c2f0b3882a95e78",
    "seller-guard": KeySet {keys: ["5389405a22b8376211f2c98bc79e72a9b9b0533da5c3c28f0c2f0b3882a95e78"],pred: keys-all},
    "timeout": "2023-06-01T00:00:00Z",
    "token-id": "t:2Q74RY998p-_uKdehMLFKeLN6erO5GRTkTS3vAWdzhg"
    }]


Events
^^^^^^
FIXED-SALE-OFFER
~~~~~~~~~~~~~~~~
sale-id* ``string`` *token-id* ``string`` *price* ``decimal`` *currency* ``string``

Event sent when an auction is started


FIXED-SALE-BOUGHT
~~~~~~~~~~~~~~~~~
sale-id* ``string`` *token-id* ``string`` *price* ``decimal`` *currency* ``string``

Event sent when a fixed sale is bought


FIXED-SALE-WITHDRAWN
~~~~~~~~~~~~~~~~~~~~
sale-id* ``string`` *token-id* ``string``

Event sent when a fixed sale is withdrawn
