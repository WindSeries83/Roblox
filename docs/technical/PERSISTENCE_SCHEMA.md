# Persistence schema

ProfileStore key: `RiftBeastsData_v1/Player_<UserId>`. Current schema version: **20** (`SaveService`). `Reconcile` applies defaults; migrations run sequentially from the stored `Version`.

Persistent sections: `Essence`, `Creatures`, `Eggs`, `Incubators`, `SanctuaryLevel`, `Stats`, `Index`, `Items`, `Stars`, `Rebirths`, login/return fields, `Quests`, `Season`, `Titles`, `SelectedTitle`, `RenameTickets`, `MarketHistory`, `Entitlements`, `PurchaseReceipts`, `PurchaseReceiptOrder`, `EconomyLedger`, `MarketLedger`, `DuelDefense`, `DuelLedger`, `DuelSeason`, `SkillPoints`, `SkillRanks`, `Offers`, `VipGiftDate`, `SecretDiscoveries`, `SecretRewardClaimed`, `PaidPurchases`, `TutorialDone`, `WorldProgress`, `Rush`, `SanctuaryAssignments`, `VipExpiresAt`. `Stats.Funnel` persists `FirstInteractionAt`, `FirstEggAt`, `FirstHatchAt`, `FirstRiftAt`, `FirstWinAt`, `FirstOptimizationAt`, `FirstRarePlusAt`, `FirstEpicPlusAt` and `FirstPurchaseAt`.

Invariants: creature IDs are unique; balances and counters are server-owned; Index, creatures, items and permanent skills survive rebirth according to the bible; session timers, cooldowns and active boosts are runtime state unless explicitly persisted; every schema change increments the version and adds a migration plus invalid-data coverage.

Profile access is valid only after `SaveService.ProfileLoaded` and before `OnSessionEnd`. Release is performed on `PlayerRemoving`.
