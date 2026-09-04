# Paid random items

Essence Packs are disabled (`PURCHASES_ENABLED = false`) before soft launch. Essence can purchase random eggs, so selling Essence is treated as an indirect paid-random-item path; blocking only Luck Potions and Server Boosts is insufficient.

When real purchases are enabled, `PolicyService` must confirm `ArePaidRandomItemsRestricted == false` before granting an Essence product. Failed policy lookup is restrictive. Re-enable Essence Packs only after the current Roblox policy and disclosure requirements have been reviewed against the live offer catalog.

`NotProcessedYet` means Roblox retries the receipt; it is not an automatic refund decision. Receipt grants remain idempotent and are acknowledged only after the profile ledger is durably saved.

## Secret disclosure rule

`SecretGate` can alter the final outcome after normal rarity weighting. This hidden path must remain inaccessible through a paid random-item route unless the current Roblox disclosure requirements are satisfied. Hidden lore and prerequisites may remain mysterious, but paid numerical outcomes cannot rely on hidden probability when disclosure is required.
