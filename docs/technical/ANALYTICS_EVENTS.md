# Analytics events

Schema version: `1`. Events use stable snake_case names and are emitted server-side.

| Event | Required properties |
|---|---|
| `first_interaction`, `first_egg`, `first_hatch`, `first_rift`, `first_win`, `first_optimization` | `user_id`, `session_id`, `at`, `schema_version` |
| `hatch`, `rare_drop`, `breed`, `rift_complete` | `user_id`, `rarity`, `mutation`, `world`, `duration` where applicable |
| `purchase`, `market_sale` | `user_id`, product/listing identifiers, server-authoritative amount |
| `session_start`, `session_end`, `return_visit` | `user_id`, `session_id`, `at`, `days_since_last` where applicable |

Current implementation is partial; emitted names must be audited against this contract before analytics are used for decisions.
