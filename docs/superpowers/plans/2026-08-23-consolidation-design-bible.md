# Consolidation du design dans la bible — Plan d'exécution

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** La bible (`docs/RIFT_BEASTS_1_bible_design.md`) devient la source unique du design en absorbant les 4 specs datées, qui sont ensuite supprimées.

**Architecture:** Fusion sémantique par sections de la bible (structure conservée), conflits tranchés par règle « la version la plus récente gagne ». Le plan de production reste le doc 2/2 et reçoit uniquement les artefacts d'exécution (lots, risques, tâches humaines) extraits de la spec revenus.

**Tech Stack:** Markdown, git.

**Spec:** Décision actée en session du 23/08/2026 (choix utilisateur : « Bible = doc unique »).

## Global Constraints

- Structure de la bible conservée (§0-§10) ; enrichissement en place, pas de refonte
- Conflits : contenu le plus récent gagne (ex. VIP Pass 30 j remplace toute mention d'un VIP gamepass permanent)
- Les principes intangibles de la bible restent intangibles (« F2P fait 100 % du contenu », Reliques non achetables…)
- Aucune référence morte vers `docs/superpowers/specs/` ne doit subsister après suppression
- Commits sans accents (convention repo)

---

### Task 1: En-tête + §0 décisions actées

**Files:** Modify `docs/RIFT_BEASTS_1_bible_design.md:3-20`

- [ ] En-tête : révision → 23/08/2026 ; ajouter « Consolide les specs antérieures (18–23/08) — source unique du design. »
- [ ] §0 : ajouter les décisions des specs : positionnement hybride brain rot/cœur profond (revenus §0), ton humour en surface data-driven, cadence ~10 h/sem, population vivante garantie (jamais de faux joueurs), monétisation « aggressive soft », FTUE « le monde d'abord »

### Task 2: Systèmes §3 — enrichissements des specs

**Files:** Modify bible §3 (3.9, 3.10, nouvelles sous-sections)

- [ ] §3.9 Duels : préciser « sim statique résolu serveur : score attaquant = Σ power équipe déployée, défense = Σ power créatures non déployées, ratio + aléa seedé ; mise en escrow, remboursement sur refus/timeout 60 s » (source p4 §0)
- [ ] §3.10 Trading : préciser « listings en Essence uniquement (pas de Robux joueur↔joueur, ToS), frais 5 %, cap listings, retrait double confirmation + délai 60 s, transfert atomique ; marché cross-serveur visé (listings DataStore + propagation MessagingService) » (sources p4 §0, revenus §3.B)
- [ ] Ajouter §3.11 « Œufs & chasse haut de gamme » : œufs Épique (~2 000 Essence) / Légendaire (~8 000), drop au-dessus possible par palier, Faille = source exclusive Mythique/UltraRare/Secret (revenus §1.1)
- [ ] Ajouter §3.12 « Espèces & live ops contenu » : vague 10 → 30 espèces pipeline IA, +3-5/semaine post-lancement (revenus §1.2)
- [ ] Ajouter §3.13 « Arbre d'Étoiles » : +1 point/renaissance, ~12 nœuds permanents, branches Farm/Faille/Économie, rien de vendable — précise §3.7 (revenus §1.3)
- [ ] §3.8 Mondes : ajouter « Monde N+1 = même île recolorée via DecorTemplates, multiplicateurs ×N, espèces exclusives » (revenus §1.4)
- [ ] Ajouter §3.14 « FTUE — le monde d'abord » : séquence T+0 nid/prompt unique → T+10 s éclosion spectaculaire (<15 s première récompense, pity conservé) → T+20 s farm visible → T+60-90 s première faille accélérée → T+2-3 min menus en dernier (3 prompts, auto-ouverture unique onglet Œufs) ; critère : boucle complète vécue en < 5 min sans tutoriel lu ; orbes ambiantes ~45 s plafonnées serveur ; teasing couveuse verrouillée (source ftue §1-3)
- [ ] Ajouter §3.15 « Vivant à toutes les échelles » : MaxPlayers 12-16, ticker drops global MessagingService, compteurs mondiaux, PNJ sauvages, marché cross-serveur, Éclipse sur horloge serveur (revenus §3)
- [ ] §5 Maps ligne Éclipse : préciser « toutes les 2 h, 10 min, ciel modifié, mutation boostée ×10, créature exclusive, horloge serveur — jamais conditionnée à la population » (revenus §1.5)

### Task 3: Game feel §4 + nouvelle section UI/Social

**Files:** Modify bible §4, ajouter section après §6

- [ ] §4 : ajouter les manifestations concrètes livrées/actées — couveuse 3D + BillboardGui, arche de faille permanente avec compte à rebours, créatures cliquables (équiper/évoluer/vendre prix suggéré modifiable), FloatText +N Essence, ObjectiveBanner (priorité faille > quêtes > premier œuf > Renaissance + état teasing), pouvoir visible (taille par niveau, socles d'upgrade, puissance topbar, renaissance cinématique) (sources p5, ftue §4)
- [ ] Nouvelle section « UI/UX mobile-first » : barre d'action bas (Œufs · Faille · Sanctuaire), avancés derrière « Plus », audit Device Simulator, pyramide de célébration, boutique dédiée onglet unique, bouton « Rejoindre un ami » + toast + bonus meute (revenus §4)
- [ ] Nouvelle section « Social » : groupe Roblox officiel (+10 % Essence permanent + tag + œuf commun/jour), bonus meute (+10 %/ami actif cap ×3), garde-fous caps affichés + plafond global multiplicateurs entrant dans la sim (revenus §5)

### Task 4: Monétisation §7 — remplacement de la gamme

**Files:** Modify bible §7

- [ ] Remplacer intégralement « ### Les produits » par la gamme complète du 23/08 (Starter Pack 149 R$, potions 49/149, Server Boost 99, Auto-Éclosion/+Slots/Rendement 249/199/199, offres 1er achat −50 % et retour J2/J7, packs Essence, Season Premium existant, VIP Pass 30 j ~399 R$ avec remise −10 % SKU doublés + Zone VIP de luxe détaillée, rename 49 R$, titres rotatifs 49–99 R$, cosmétiques 49–199 R$, bundle mensuel ~499 R$, mur des soutiens 99/499/999, bonus Roblox Premium natifs, pub récompensée en piste post-lancement) — copier les blocs §2.1/§2.5/§2.6 de la spec revenus tels quels
- [ ] Conserver intacts : principe « vendre du temps, du confort et de la chance », « Ce qui ne marche pas », leviers, santé économie
- [ ] Ajouter règle de validation : « Aucun prix ni multiplicateur codé avant passage EconomySim (F2P/Starter/whale léger, 14 jours ×3 runs, plafond global borné) » (revenus §2.4)

### Task 5: Classements §8 + checklist §9 + en suspens §10

**Files:** Modify bible §8, §9, §10

- [ ] §8 règles communes : préciser compteur = `Stats.TotalEssenceEarned`, refresh 5 min, sync cross-serveur MessagingService, snapshots sanctuaires pour visite (p4 §0)
- [ ] §9 checklist : ajouter « Le pass VIP conserve tout ce qui est gagné à l'expiration », « Jamais deux paywalls derrière la même exclusive gameplay », « Taux publiés avant tout code de prix »
- [ ] §10 fusionner : prix finaux (œufs/potions/bundles/VIP/bundle mensuel — sim), valeurs nœuds Arbre d'Étoiles, objectifs Mode Rush, activation pub récompensée (ARPDAU post-lancement), chemin du Secret ; conserver nom définitif + seuil Starter Pack

### Task 6: Artefacts d'exécution → plan de production

**Files:** Modify `docs/RIFT_BEASTS_2_plan_production.md` (section fin)

- [ ] Ajouter « Roadmap pré-lancement (lots, 23/08) » : tableau des 5 lots (chasse/moteur/écran/monde/lancement) depuis revenus §6
- [ ] Ajouter risques techniques suivis (marché cross-serveur, multiplicateurs empilés, cache Rojo, cadence live ops) depuis revenus §8
- [ ] Ajouter tâches humaines (groupe Roblox, IDs produits réels, icône/thumbnails A/B, Discord, playtest fermé 20-30) depuis revenus §9

### Task 7: Vérification, suppression des specs, commit

- [ ] Grep vérifications : aucun « cashback » restant dans la bible (mécanisme abandonné) ; aucune mention d'un « VIP gamepass permanent » ; références internes bible cohérentes (numéros de sections)
- [ ] `git rm docs/superpowers/specs/2026-08-18-p4-social-monetization-design.md docs/superpowers/specs/2026-08-19-p5-gamefeel-world-design.md docs/superpowers/specs/2026-08-21-ftue-monde-vivant-design.md docs/superpowers/specs/2026-08-23-revenus-brainrot-design.md`
- [ ] Commit : `docs: consolidation du design dans la bible (absorption des 4 specs), artefacts d'execution vers plan de production`
