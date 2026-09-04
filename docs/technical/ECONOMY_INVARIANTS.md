# Economy invariants

- The client never decides a gain, price, drop, receipt, ownership or balance.
- All remote inputs are typed, range-checked, state-checked and rate-limited.
- Receipt grants are idempotent by purchase ID; acknowledgement follows a successful grant/persistence path.
- Market mutations validate ownership and capacity; cross-server atomic claim remains unvalidated until a published test.
- Relics intended as Faille drops are not sold as direct purchases.
- A failed transaction must not silently create currency or destroy a creature; rollback/compensation is explicit.
- Displayed odds must be generated from the same final probability calculation as the server roll.
- Profile-dependent work starts after `ProfileLoaded`.

Policy basis: [PolicyService](https://create.roblox.com/docs/reference/engine/classes/PolicyService/GetPolicyInfoForPlayerAsync) and [paid random items guidelines](https://create.roblox.com/docs/production/monetization/paid-random-items). `ArePaidRandomItemsRestricted` gates paid luck products; `IsPaidItemTradingAllowed` gates the market. Direct paid-random UI fallback/disclosure still requires Studio validation before purchases are enabled.
