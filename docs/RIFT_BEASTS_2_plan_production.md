# RIFT BEASTS — Plan de production (IA-first)

> **Document 2/2.** Le *comment*. Voir `RIFT_BEASTS_1_bible_design.md` pour le concept et les systèmes.
> Production solo, assistée par IA via MCP Roblox Studio.

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
- [ ] Studio à jour, MCP intégré activé, agent connecté
- [ ] Rojo + repo Git en place, place de dev séparé du place de prod
- [ ] Architecture serveur/client posée : ProfileStore (ou équivalent) pour la sauvegarde, modules de services
- [ ] Log serveur pour tout ce qui touche à l'économie

**Sortie :** un place vide mais propre, où l'IA peut travailler sans casser la sauvegarde.

### P1 — Vertical slice · 3–4 semaines
Le minimum qui prouve que la boucle est amusante.
- [ ] 1 sanctuaire, génération d'Essence AFK
- [ ] 10 créatures, 3 raretés, 2 mutations
- [ ] 1 type de Faille avec combat simple
- [ ] Éclosion d'œufs + effet de drop rare (ralenti, flash, son, annonce)
- [ ] Sauvegarde fiable

**Test de vérité :** est-ce que *toi* tu as envie de relancer le lendemain ? Si non, ne pas continuer — corriger la boucle.

### P2 — Systèmes de profondeur · 4–6 semaines
- [ ] Index complet avec bonus permanents
- [ ] Équipement (Cœurs / Colliers / Reliques) + slots
- [ ] Évolution des créatures (4 stades)
- [ ] Élevage génétique + arbres généalogiques
- [ ] Renaissance et Étoiles

**Sortie :** un joueur peut faire 20 h sans plafonner.

### P3 — Économie & équilibrage · 2–3 semaines
- [ ] Courbe chiffrée complète : coût des œufs, rendement d'Essence, temps avant Renaissance 1, 2, 3
- [ ] Tables de drop finalisées et **publiées**
- [ ] Sinks de monnaie
- [ ] Simulation sur tableur **avant** implémentation — pas l'inverse

**Sortie :** aucune progression bloquée, aucune inflation prévisible.

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

- Choix final du MCP : intégré seul, ou intégré + communautaire pour la génération d'assets
- Outil de sauvegarde retenu (ProfileStore vs alternative)
- Budget temps réel disponible par semaine → conditionne la durée réelle des phases
