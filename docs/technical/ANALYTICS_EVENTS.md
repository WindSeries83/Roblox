# Analytics events

Schema version: `1`. Events use stable snake_case names and are emitted server-side.

| Event | Required properties |
|---|---|
| `first_interaction`, `first_egg`, `first_hatch`, `first_rift`, `first_win`, `first_optimization` | `user_id`, `session_id`, `at`, `schema_version` |
| `hatch`, `rare_drop`, `breed`, `rift_complete` | `user_id`, `rarity`, `mutation`, `world`, `duration` where applicable |
| `purchase`, `market_sale` | `user_id`, product/listing identifiers, server-authoritative amount |
| `session_start`, `session_end`, `return_visit` | `user_id`, `session_id`, `at`, `days_since_last` where applicable |

The server emits the session envelope and the listed core funnel, hatch, Rift, breeding, purchase and market milestones. Cohort metrics such as D1/D7 retention, conversion and ARPDAU still require published telemetry before they can drive decisions.
