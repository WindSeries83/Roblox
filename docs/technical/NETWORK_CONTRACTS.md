# Network contracts

`src/shared/Net.luau` is the single source of remote names. The server creates/guarantees every `RemoteEvent` during bootstrap; clients only wait for existing remotes. `default.project.json` declares only the `Remotes` folder.

All client â†’ server payloads are untrusted. Handlers validate type, ownership, state, cooldown/rate and economy before mutation. Server â†’ client payloads are presentation snapshots/results.

| Remote | Direction / payload | Server validation and rate | Result / rejection |
|---|---|---|---|
| `BuyEgg` | Câ†’S: `tier: string` | known/unlocked tier, current price, Essence, profile, cooldown | adds one server-created egg; silent rejection + economy log |
| `PlaceEgg` | Câ†’S: `eggId: string` | profile ownership, egg exists, incubation capacity/state | starts incubation; invalid ownership/state rejected |
| `HatchResult` | Sâ†’C: rolled result payload | server-only `Gameplay` roll, active profile and inventory | cosmetic/result presentation; client cannot submit a result |
| `RiftRequest` | Câ†’S: no payload | player/profile and rift availability; request cooldown | sends current world state |
| `RiftAttack` | Câ†’S: no payload | active run, alive state, cooldown and server damage | updates run or ends it; invalid calls ignored |
| `EvolveCreature` | Câ†’S: `creatureId: string` | owned creature, evolution rule, level and cost | mutates owned creature or rejects |
| `BreedCreatures` | Câ†’S: `fatherId`, `motherId: string` | ownership, distinct compatible parents, cost/cooldown | server-created offspring via `BreedResult` |
| `MarketList` | Câ†’S: `creatureId: string`, `price: number` | ownership, price bounds, capacity, policy and rate limit | removes/listings transactionally or rejects |
| `MarketBuy` | Câ†’S: `listingId: string` | listing exists, buyer balance, seller/item state, policy | atomic purchase/listing removal or rejection |
| `MarketRemove` | Câ†’S: `listingId: string` | listing ownership and current state | returns listing or rejects |
| `QuestClaim` | Câ†’S: `questId: string` | known quest, completion, not already claimed | one-time server reward or rejection |
| `SkillBuy` | Câ†’S: `nodeId: string` | known node, prerequisites, points, not already maxed | spends points once or rejects |

| `SecretRitual` | C -> S: no payload | profile, four server-side boss discoveries, one-second cooldown, one-time claim | grants the free title/reward once or rejects |

No client-supplied price, drop, creature, reward or balance is trusted. Errors are silent rejection plus an economy log where relevant. Remote names not listed above follow the same authority rule and are documented by their owning service.
