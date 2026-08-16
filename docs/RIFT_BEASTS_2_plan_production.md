# RIFT BEASTS — Plan de production (IA-first)

> **Document 2/2.** Le *comment*. Voir `RIFT_BEASTS_1_bible_design.md` pour le concept et les systèmes.
> Production solo, assistée par IA via MCP Roblox Studio.

---

## 0. Décisions actées

| Sujet | Décision |
|---|---|
| Framework | **Vanilla Luau maison** — modules de services + Bootstrap minimal, pas de framework tiers |
| Sauvegarde | **ProfileStore** (`lm-loleris/profilestore@1.0.3`) via Wally, realm `server` → `ServerPackages/` |
| MCP | **MCP intégré de Studio** seul (pas de MCP communautaire pour l'instant) |
| Scope | **P0 enchaîné sur P1** (vertical slice) |
| Outillage | Rojo 7.7 + rokit (StyLua, selene avec `std = "roblox"`, wally) |

---

## 1. Stack de production IA

### 1.1 Options disponibles

| Outil | Rôle |
|---|---|
| **MCP intégré à Roblox Studio** | Voie recommandée par Roblox. `Assistant → ⋯ → Manage MCP Servers → Enable Studio as MCP server`, puis quick connect vers le client (Claude, Cursor…). Serveur local, transport stdio. |
| **Assistant Roblox** | Intégré à Studio, supporte désormais des LLM externes. Bon pour les tâches courtes in-context et l'automatisation de playtest. |
| `Roblox/studio-rust-mcp-server` | Serveur standalone open source. Roblox a déplacé son investissement vers le MCP intégré — à ne garder que si besoin spécifique. |
| MCP communautaires (`robloxstudio-mcp`, WEPPY…) | Plus d'outils : multi-Studio, génération et upload d'assets via Open Cloud. À auditer avant usage. |

### 1.2 Workflow retenu
1. **Agent de code externe** (Claude Code) connecté au **MCP intégré de Studio** → lecture du DataModel, écriture de Luau, refactor de masse.
2. **Assistant Roblox** pour l'itération rapide dans l'éditeur et l'automatisation des playtests.
3. **Git obligatoire** (Rojo + repo externe). Le MCP modifie le place directement : sans versioning, une mauvaise commande coûte une journée.
4. Travailler sur une **copie** du place, jamais sur la production.

### 1.3 Garde-fous
- `Allow HTTP Requests` activé uniquement pendant les sessions IA
- Relire tout script généré touchant à **DataStore, économie, achats, anti-triche**. L'IA écrit très bien du gameplay et très mal de la sécurité serveur.
- Toute logique d'argent et de drop **côté serveur uniquement**. Aucune exception.
- Auditer tout MCP communautaire avant installation (il a accès à ton place).

### 1.4 Répartition IA / humain

| L'IA fait bien | À faire soi-même |
|---|---|
| Boilerplate de services, UI, refactor de masse | Équilibrage et courbe économique |
| Systèmes de gameplay isolés | Sécurité serveur et anti-triche |
| Génération de variantes de créatures | Direction artistique et identité visuelle |
| Migration et renommage à grande échelle | Décisions de design (ce qui reste, ce qui saute) |

---

## 2. Phases de développement

### P0 — Socle technique · 1–2 semaines
- [x] Studio à jour, MCP intégré activé, agent connecté
- [x] Rojo + repo Git en place, place de dev séparé du place de prod
- [x] Architecture serveur/client posée : ProfileStore pour la sauvegarde, modules de services (Bootstrap, SaveService, Log)
- [x] Log serveur pour tout ce qui touche à l'économie (`[ECON]` ring buffer + print)

**Sortie :** un place vide mais propre, où l'IA peut travailler sans casser la sauvegarde.

### P1 — Vertical slice · 3–4 semaines
Le minimum qui prouve que la boucle est amusante.
- [x] 1 sanctuaire, génération d'Essence AFK (tick 1 s, gains hors ligne à 50 %, cap 12 h)
- [x] 10 créatures, 3 raretés, 2 mutations (données complètes 8 raretés / 6 mutations prêtes pour P2)
- [x] 1 type de Faille avec combat simple (portail cyclique, gardien, cristal, récompenses ×8)
- [x] Éclosion d'œufs + effet de drop rare (flash + bannière + annonce serveur — son à ajouter)
- [x] Sauvegarde fiable (playtest MCP complet exécuté : join, starter, achats, éclosions, faille victoire/défaite, récompenses — en mode mock Studio ; à revalider sur place publié avec accès DataStore)

**Test de vérité :** est-ce que *toi* tu as envie de relancer le lendemain ? Si non, ne pas continuer — corriger la boucle.

### P2 — Systèmes de profondeur · 4–6 semaines
- [x] Index complet avec bonus permanents
- [x] Équipement (Cœurs / Colliers / Reliques) + slots
- [x] Évolution des créatures (4 stades)
- [x] Élevage génétique + arbres généalogiques
- [x] Renaissance et Étoiles

**Sortie :** un joueur peut faire 20 h sans plafonner. ✓ (tests 59/59 → 64/64)

### P3 — Économie & équilibrage · 2–3 semaines
- [x] Courbe chiffrée complète : coût des œufs, rendement d'Essence, temps avant Renaissance 1, 2, 3
- [x] Tables de drop finalisées et **publiées** (voire §7)
- [x] Sinks de monnaie (upgrade du sanctuaire : +2 places, coût base 1000 ×4 par niveau)
- [x] Simulation **avant** implémentation (EconomySim, 7 jours simulés ×3 runs, joueur connecté)
- [x] Cap de créatures : 10 au niveau 1, +2 par niveau de sanctuaire
- [x] Renaissance garde la créature la plus forte

**Résultats de simulation (courbe retenue `{50 000, 250 000, 1 250 000, 6 250 000}`) :**
Renaissance 1 ~13–18 min · Renaissance 2 ~30–40 min · Renaissance 3 ~1h10–1h20 · Renaissance 4 ~2h48–3h31. **4 rebirths en 7 jours** — plus de mur (l'ancienne courbe 10k/100k/1M ne permettait jamais rebirth 4). Taux de fin de semaine ~1700–2300/s (inflation contenue par le cap 10).

**Sortie :** aucune progression bloquée, aucune inflation prévisible. ✓ (64/64 tests verts, playtest remotes : cap, upgrade, rebirth)

### P4 — Social & monétisation · 3–4 semaines
- [ ] Trading + place de marché + anti-arnaque
- [ ] Duels de sanctuaires
- [ ] Gamepasses et bundles
- [ ] Season pass v1
- [ ] Classements et sanctuaires visitables

### P5 — Pré-lancement · 2 semaines
- [ ] Icône et miniatures : **le poste le plus rentable du projet**. Tester plusieurs variantes.
- [ ] Rétention des 3 premières minutes : premier drop rare dans les 60 s
- [ ] Discord ouvert **avant** la sortie
- [ ] Playtest fermé avec 20–30 joueurs adultes recrutés sur Discord / Reddit
- [ ] Anti-triche : vérifier que rien de monétaire ne passe par le client

### P6 — Lancement & live ops · permanent
- [ ] **Update hebdomadaire non négociable.** Sans ça, le jeu meurt en trois semaines.
- [ ] Évènement saisonnier toutes les 2 semaines
- [ ] Suivi : rétention J1 / J7 / J30, ARPDAU, temps avant premier achat
- [ ] Communication publique sur les changements d'équilibrage

---

## 3. Acquisition

L'algorithme Roblox pousse ce qui performe auprès de la masse, c'est-à-dire des ados. **Un jeu à esthétique adulte aura un CTR médiocre sur la page d'accueil.**

Conséquence : l'acquisition doit venir de **l'extérieur**, et être prévue dès P0.
- **Discord** — cœur de la communauté adulte
- **YouTube long format** — guides d'optimisation, tier lists
- **Reddit** — r/roblox, communautés de jeux idle
- **TikTok / Shorts** — clips de drops Ultra Rare

Plus lent que le trafic Roblox natif, mais bien plus fidèle.

---

## 4. Checklist technique & business

**Technique**
- [ ] Toute logique économique côté serveur
- [ ] Sauvegarde testée contre les crashs et les rejoins rapides
- [ ] Git + place de dev séparé
- [ ] Scripts IA relus sur tout ce qui touche DataStore / achats
- [ ] Anti-exploit vérifié avant lancement

**Business**
- [ ] Icône testée en A/B
- [ ] Discord ouvert avant le lancement
- [ ] Cadence d'update hebdo tenable en solo
- [ ] Métriques instrumentées dès P1 (pas après)

---

## 5. Risques identifiés

| Risque | Gravité | Mitigation |
|---|---|---|
| Découverte faible (algo Roblox défavorable au public adulte) | **Élevé** | Acquisition externe planifiée dès P0 |
| Cadence d'update intenable en solo | **Élevé** | Réduire le scope de P2/P4 plutôt que le rythme de live ops |
| Genre saturé | Moyen | Les deux différenciateurs (élevage + duel consenti) doivent être visibles dès la miniature |
| Inflation de l'économie | Moyen | Simulation tableur avant implémentation, sinks dès P3 |
| Code IA non sécurisé sur l'économie | Moyen | Relecture obligatoire, tout côté serveur |
| Perte de travail via commande MCP destructive | Moyen | Git + place de dev séparé dès P0 |
| Mineurs dans une audience visée adulte | Faible | Contenu sûr par défaut, pas de mécanique de pression à l'achat |

---

## 6. En suspens

- Budget temps réel disponible par semaine → conditionne la durée réelle des phases
- Direction artistique P1 : placeholder parts simples — génération de meshes/visuels à planifier
- Sons (éclosion, drop rare, faille) : aucun asset audio en place
- Sauvegarde DataStore : à revalider sur place **publié** (Studio : « Roblox API services unavailable » attendu)
- Place Studio : sauvegarder le fichier (`Ctrl+S`) après toute synchro MCP — les remotes sont désormais déclarées dans `default.project.json`

## 7. Décisions P3 actées

| Sujet | Décision |
|---|---|
| Courbe de renaissance | `{ 50000, 250000, 1250000, 6250000 }` — rebirth 1 ≈ 15 min, rebirth 4 ≈ 3 h (sim 7 j) |
| Cap créatures | 10 au niveau 1 (`MAX_CREATURES_BASE`), +2 par niveau de sanctuaire (`SANCTUARY_SLOTS_PER_LEVEL`) |
| Coût upgrade sanctuaire | base 1000 Essence, ×4 par niveau — reset à 1 au rebirth |
| Renaissance | garde la créature la plus forte + Index + Reliques légendaires ; perd œufs, Essence, niveau de sanctuaire |
| Compteur de renaissance | `TotalEssenceEarned` **cumulatif** (jamais remis à 0) |
| Rejets au cap | éclosion : l'œuf n'est pas consommé ; élevage : vérifié **avant** le paiement (aucune perte) |
