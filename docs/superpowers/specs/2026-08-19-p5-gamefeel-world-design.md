# RIFT BEASTS — Spec P4.5 : Monde vivant (game feel)

> **Document d'entrée** du lot Game Feel B+A. Complète la bible (auditée, option 1)
> et le plan de production. Date : 19/08/2026.

---

## 0. Problème

Retour joueur : « à part éclore des œufs, il se passe rien. C'est pas vivant. Pas lisible. Pas pratique. »

Trois causes identifiées dans le code :
1. **Monde mort** : les créatures ont un idle (bob/tilt) mais restent en grille ; rien n'est cliquable ; l'écran ne montre qu'un compteur + un bouton Menu.
2. **Tout passe par le menu** : éclosion, équipement, évolution, vente, duels — aucune action directe dans le monde.
3. **Pas de direction** : le tutoriel couvre 6 étapes puis s'arrête ; aucune indication de « quoi faire ensuite ».

## 1. Décisions actées

| Sujet | Décision |
|---|---|
| **Approche** | B (hubs dans le monde) + A (créatures cliquables + feedbacks) |
| Couveuse | Objet 3D dans l'enclos, ProximityPrompt → **BillboardGui** au-dessus de la couveuse (liste œufs + acheter + éclore) |
| Arche de faille | **Arche de pierre permanente** construite au démarrage serveur ; brille quand la faille est active ; compte à rebours « Faille dans X:XX » |
| **Rythme faille** | **Inchangé** : `RIFT_INTERVAL = 600`, `RIFT_ACTIVE_SECONDS = 180` (hors scope) |
| Créatures cliquables | ClickDetector sur chaque clone → panneau contextuel (équiper, évoluer, **vendre avec prix suggéré pré-rempli modifiable**) |
| Feedbacks | `Fx.FloatText` : +N Essence flottant au tick ; saut + Burst au clic créature |
| Direction | Bandeau bas d'écran `ObjectiveBanner`, priorité : faille active > quêtes prêtes > premier œuf > Renaissance |
| Serveur | **Zéro nouvelle économie** ; seule modif : RiftService (arche persistante + payload `NextAt`) |

## 2. Fichiers

**Créés :** `src/client/Panels/CouveusePanel.luau`, `src/client/CreatureHud.luau`, `src/client/ObjectiveBanner.luau`, `src/tests/unit/Cases/Objective_Test.luau`

**Modifiés :** `src/shared/Config.luau` (constants feedback/vente suggérée uniquement — pas l'intervalle), `src/server/Services/RiftService.luau`, `src/client/Fx.luau`, `src/client/CreatureDisplay.luau`, `src/client/Ui.luau`, `docs/RIFT_BEASTS_1_bible_design.md`, `docs/superpowers/plans/2026-08-19-p5-gamefeel-world.md`

**Place (via MCP) :** couveuse (socle + œuf Neon + ProximityPrompt) ; l'arche est construite par le serveur (pas d'objet place-owned).

## 3. Règles de sécurité

- Aucune mutation d'Essence côté client (pattern existant respecté)
- Vente : passe par `MarketList` existant (frais, cap, retrait déjà en place)
- Toute UI flottante est client-only (BillboardGui répliqués côté client sur clones client)
- `RiftWorld` enrichi `{ Active, EndsAt, NextAt }` — serveur seul calcule NextAt

## 4. Vérifications

- stylua + selene + tests (~118 verts, dont Objective_Test)
- Playtest MCP : couveuse → éclosion dans le monde ; clic créature → équiper/évoluer/vendre ; arche + compte à rebours ; faille active → entrer → gagner ; +N Essence ; bandeau direction ; marché/duels inchangés
