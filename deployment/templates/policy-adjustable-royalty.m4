(namespace "__NAMESPACE__")

include(policies/policy-adjustable-royalty.pact)dnl
"Module loaded"

ifdef(`__INIT__',dnl
(create-table royalty-sales)
(create-table royalty-tokens)
)
