# Network contracts

`src/shared/Net.luau` is the single source of remote names. The server creates/guarantees every `RemoteEvent` during bootstrap; clients only wait for existing remotes. `default.project.json` declares only the `Remotes` folder.

All client → server payloads are untrusted. Handlers validate type, ownership, state, cooldown/rate and economy before mutation. Server → client payloads are presentation snapshots/results.

| Remote | Direction / payload | Server validation and rate | Result / rejection |
|---|---|---|---|
| `BuyEgg` | C→S: `tier: string` | known/unlocked tier, current price, Essence, profile, cooldown | adds one server-created egg; silent rejection + economy log |
| `PlaceEgg` | C→S: `eggId: string` | profile ownership, egg exists, incubation capacity/state | starts incubation; invalid ownership/state rejected |
| `HatchResult` | S→C: rolled result payload | server-only `Gameplay` roll, active profile and inventory | cosmetic/result presentation; client cannot submit a result |
| `RiftRequest` | C→S: no payload | player/profile and rift availability; request cooldown | sends current world state |
| `RiftAttack` | C→S: no payload | active run, alive state, cooldown and server damage | updates run or ends it; invalid calls ignored |
| `EvolveCreature` | C→S: `creatureId: string` | owned creature, evolution rule, level and cost | mutates owned creature or rejects |
| `BreedCreatures` | C→S: `fatherId`, `motherId: string` | ownership, distinct compatible parents, cost/cooldown | server-created offspring via `BreedResult` |
| `MarketList` | C→S: `creatureId: string`, `price: number` | ownership, price bounds, capacity, policy and rate limit | removes/listings transactionally or rejects |
| `MarketBuy` | C→S: `listingId: string` | listing exists, buyer balance, seller/item state, policy | atomic purchase/listing removal or rejection |
| `MarketRemove` | C→S: `listingId: string` | listing ownership and current state | returns listing or rejects |
| `QuestClaim` | C→S: `questId: string` | known quest, completion, not already claimed | one-time server reward or rejection |
| `SkillBuy` | C→S: `nodeId: string` | known node, prerequisites, points, not already maxed | spends points once or rejects |
| `PolicyState` | S→C: policy booleans | produced by server `PolicyService` after profile load | presentation/gating only; server gates paid actions too |

No client-supplied price, drop, creature, reward or balance is trusted. Errors are silent rejection plus an economy log where relevant. Remote names not listed above follow the same authority rule and are documented by their owning service.

Policy is delivered in the normal `Sync` snapshot; there is no `PolicyState` remote.
