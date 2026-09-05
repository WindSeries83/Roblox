# Analytics events

Schema version: `1`. Events use stable snake_case names and are emitted server-side.

| Event | Required properties |
|---|---|
| `first_interaction`, `first_egg`, `first_hatch`, `first_rift`, `first_win`, `first_optimization` | `user_id`, `session_id`, `at`, `schema_version` |
| `hatch`, `rare_drop`, `breed`, `rift_complete` | `user_id`, `rarity`, `mutation`, `world`, `duration` where applicable |
| `purchase`, `market_sale` | `user_id`, product/listing identifiers, server-authoritative amount |
| `session_start`, `session_end`, `return_visit` | `user_id`, `session_id`, `at`, `days_since_last` where applicable |

The local log retains the full session envelope. Published player events call Roblox LogCustomEvent with the Player, event name, count value 1, and supported custom fields: CustomField01 = Rarity, CustomField02 = Mutation, CustomField03 = Source (when supplied). Session IDs and transaction IDs are not chart dimensions. Studio and server-only events remain local; submission failures produce a warning. Successful API submission is not proof of dashboard ingestion. Published delivery, D1/D7 retention, conversion and ARPDAU still require verification before they can drive decisions.
