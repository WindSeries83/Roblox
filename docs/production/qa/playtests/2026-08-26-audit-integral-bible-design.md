# Audit intégral du gameplay face à la bible de design

> Date : 2026-08-26  
> Bible : `docs/RIFT_BEASTS_1_bible_design.md` (révision 23/08/2026)  
> Commit audité : `c8866e5296c98d19dd6062f73f11124a9bf13f9d` (`chantierE-socle`)  
> Testeur : agent Codex, session Studio locale, clavier/souris et simulateur tactile  
> Verdict baseline : **NO-GO pré-lancement** — 2 risques P0 transactionnels, FTUE visuellement ambigu et plusieurs systèmes majeurs incomplets. Les correctifs décrits dans l’addendum ont ensuite été implémentés dans le workspace, sans validation publiée.

## Baseline et limites

- État Git non propre laissé intact : `opencode.json`, `rokit.toml` et `src/tests/unit/RunUnitTest.luau` modifiés ; `.agents/`, `.codex/`, `.github/`, `tests/`, `src/tests/unit/Expect.luau` et plusieurs plans non suivis.
- Studio ciblé : `Roblox.rbxlx`, revenu en Edit après chaque session.
- Rojo : deux PID formant un couple wrapper/enfant (`8396 → 16120`), tous deux `rojo serve default.project.json` ; aucun second serveur indépendant.
- Synchronisation : `ReplicatedStorage.Shared.Config.Source` contient `SYNC_MARKER`, `RIFT_INTERVAL = 600`, longueur 10 766 en Edit avant le playtest final.
- ProfileStore indisponible et MemoryStore indisponible sont attendus dans ce place non publié ; aucune sauvegarde réelle n'a été écrite.
- Les captures MCP sont renvoyées comme blocs image, sans chemin local. Elles ont toutes été examinées par l'agent `eyes` sous les identifiants exacts indiqués ci-dessous ; aucune interprétation visuelle n'est issue de l'agent principal.
- Une seule instance Studio : marché/duel multijoueur, MessagingService, téléportations, achats et persistance publiée restent non testables en conditions réelles.
- Le simulateur a déclaré l'iPhone 13 en Portrait, mais la capture est restée en paysage (`749×368`) : le 390×844 n'est pas validé visuellement.

## Portes techniques

| Porte | Résultat | Preuve |
|---|---|---|
| `stylua --check src` | CONFORME | Vérification finale : sortie 0, aucun fichier à reformater. |
| `selene src` | CONFORME | Vérification finale : 0 erreur, 0 warning, 0 parse error. |
| Suite Luau fraîche | CONFORME | 32 modules de cas, **232 run, 232 passed, 0 failed**, 0,085 s dans une nouvelle copie Server Studio. |
| Console démarrage | CONFORME | ProfileStore/MemoryStore indisponibles attendus en Studio non publié ; aucun autre warning/erreur au démarrage ou après l’éclosion testée. |
| EconomySim | NON TESTABLE LOCALEMENT | 5 profils × 3 runs interrompus après >2 min 30 ; outil limité à 7 jours (`MAX_SIM_SECONDS`) au lieu des 14 jours demandés. |

## Légende des preuves

- `C:` code, suivi du fichier et des lignes.
- `T:` test automatisé ; baseline 222/222, puis 232/232 après implémentation (voir addendum).
- `R:` état/log runtime d'une copie Play fraîche.
- `V:` observation de `eyes`, identifiée par la capture MCP.
- `E:` dépendance à un environnement publié ou multijoueur.

## Matrice atomique B0–B9

Chaque ligne reçoit exactement un statut. `P—` signifie qu'aucun défaut n'est attribué à ce statut (prévu, ambigu, non testable ou hors périmètre).

### B0 — Décisions actées

| ID | Exigence | Lot | Statut | Sév. | Catégorie | Preuve / critère de correction |
|---|---|---:|---|---:|---|---|
| B0.1 | Plateforme Roblox | Socle | CONFORME | P— | design | C: projet Rojo et API Roblox. |
| B0.2 | Collection + idle + optimisation | Socle | CONFORME | P— | design | C: `EssenceService`, œufs, évolution, élevage, Index. T: Gameplay/Evolution/Breeding. |
| B0.3 | Cible adulte, mineurs jouables sans ciblage | Transversal | PARTIEL | P3 | design | V: DA nocturne cohérente, UI dense ; aucun contrôle éditorial/âge testable localement. |
| B0.4 | Low-poly crépusculaire, sans pastel enfantin | 3.5 | PARTIEL | P2 | polish | V:`audit-ftue-spawn-desktop` nocturne cohérent mais bloom/surexposition et gros éléments coupés. Corriger exposition et occlusions sur les 4 formats. |
| B0.5 | Serveurs partagés, sanctuaires visitables, trading | 1–4 | PARTIEL | P2 | contenu non livré | C: marché, duels, amis, leaderboard présents ; visites/synchro réelle non validées. Valider à 2 clients et 2 serveurs publiés. |
| B0.6 | Revenus : donner envie, jamais forcer | 1–5 | PARTIEL | P2 | design | V:`audit-boutique-tablet` produits sans prix, valeur ou timer ; proposition peu crédible mais non bloquante. |
| B0.7 | Mondes + renaissances en quelques heures, Index long | 2–4 | PARTIEL | P2 | équilibrage | C: 4 seuils ; mondes absents ; simulation inachevable pendant l'audit. Fournir sim 14 j reproductible et mondes livrés. |
| B0.8 | Social et monétisation pré-lancement P4/P5 | 1–5 | PARTIEL | P2 | contenu non livré | Services de base présents, IDs produits à 0, VIP/zone/groupe incomplets. |
| B0.9 | Surface dopamine sur cœur profond | 1–4 | PARTIEL | P2 | design | Systèmes profonds présents ; V: rare reward textuel, monde masqué, créatures peu visibles. |
| B0.10 | Humour surface, mystère au fond | 4 | PRÉVU NON LIVRÉ | P— | contenu non livré | Pas de pipeline de répliques/PNJ livré ; Lot 4. |
| B0.11 | Monétisation aggressive soft sans paywall/compteur agressif | 1–5 | PARTIEL | P2 | design | C: confort/chance ; Season Premium contient une exclusive, contradiction traitée B7.14/B9.2. |
| B0.12 | FTUE monde d'abord, boucle <5 min sans lecture | 3.5 | NON CONFORME | P1 | écart de design | V:`audit-ftue-spawn-desktop`, `audit-first-rift-desktop` : objectifs concurrents, tutoriel massif, première Faille non gagnée pendant le parcours. Corriger pour un seul objectif monde, puis réussir le scénario agent en <5 min. |
| B0.13 | Monde vivant sans faux joueurs, données globales réelles | 1–4 | PARTIEL | P2 | contenu non livré | C: ticker/global stats réels ; MemoryStore/Messaging non testables ; PNJ sauvages absents (Lot 4). |
| B0.14 | Cadence live ops 10 h/semaine | Post-launch | NON TESTABLE LOCALEMENT | P— | design | E: nécessite historique de production et données live. |

### B1–B2 — Contrat et boucle

| ID | Exigence | Statut | Sév. | Catégorie | Preuve / critère de correction |
|---|---|---|---:|---|---|
| B1.1 | Créatures génèrent de l'Essence en continu | CONFORME | P— | design | R: rendement 1,3/s après première éclosion ; C:`EssenceService:98–128`. |
| B1.2 | Rusher termine mondes + renaissance en quelques heures | PARTIEL | P2 | équilibrage | 4 seuils présents ; mondes non livrés ; sim timeout. |
| B1.3 | Joueur tranquille obtient tout sans punition | AMBIGUÏTÉ BIBLE | P— | ambiguïté | Action facultative, mais Relique exclusive Faille requise pour stade 4 ; trancher ce que « tout » couvre. |
| B1.4 | Toujours savoir quoi faire ensuite | NON CONFORME | P1 | écart de design | V: « ouvre le menu Œufs » et « approche-toi… E » simultanés ; étape 2 demande un « Menu » absent. Un seul objectif effectif doit rester. |
| B1.5 | Écran vivant, créatures actives et visibles | PARTIEL | P2 | écart de design | V: aucune créature proche identifiable après hatch/Faille ; silhouettes lointaines seulement. |
| B1.6 | Le jeu respecte le temps | PARTIEL | P2 | design | Hors-ligne et conservation Renaissance sont présents ; les fenêtres transactionnelles marché/receipt restent incompatibles avec une garantie de temps tant qu'elles ne sont pas atomiques. |
| B2.1 | Sanctuaire AFK et rendement hors-ligne réduit | CONFORME | P— | design | C:`Config.OFFLINE_RATE`, services de données ; T: Gameplay/SkillTree. |
| B2.2 | Faille active 2–4 min toutes les ~3–4 min | AMBIGUÏTÉ BIBLE | P— | ambiguïté | §2 dit 3–4 min ; §4.A impose `RIFT_INTERVAL=600` et actif 180 s. Code suit 600/180. |
| B2.3 | Faille donne œufs, reliques, éclats de mutation | PARTIEL | P2 | contenu non livré | Œufs/reliques présents ; aucun système d'éclats identifié. |
| B2.4 | Éclosion/fusion comme sink d'Essence | PARTIEL | P2 | contenu non livré | Éclosion présente ; fusion d'œufs/reliques absente. |
| B2.5 | Élevage avec héritage | CONFORME | P— | design | T: Breeding, 8 cas ; UI pourcentages et généalogie présents. |
| B2.6 | Optimisation équipement/arbre/évolution/remplacement | PARTIEL | P2 | design | Logique présente ; arbre non graphique, portraits neutralisés. |
| B2.7 | Renaissance au plafond, nouveau monde et Mode Rush | PARTIEL | P2 | contenu non livré | Reset/étoiles présents ; monde/thème/Rush absents (Lot 4). |
| B2.8 | Ratio 80 % passif / 20 % actif | NON TESTABLE LOCALEMENT | P— | équilibrage | Nécessite télémétrie ou simulation complète. |
| B2.9 | Action jamais obligatoire, seulement multiplicative | AMBIGUÏTÉ BIBLE | P— | ambiguïté | Stade final exige une Relique disponible uniquement en Faille. Clarifier l'exception ou rendre une voie passive. |
| B2.10 | F2P fait 100 % du contenu | AMBIGUÏTÉ BIBLE | P— | ambiguïté | Season Premium promet une créature exclusive tout en affirmant 100 % du contenu F2P. Définir « contenu » ou offrir une voie F2P. |

### B3 — Systèmes

| ID | Exigence | Statut | Sév. | Catégorie | Preuve / critère de correction |
|---|---|---|---:|---|---|
| B3.1 | Ordre des 8 raretés | CONFORME | P— | design | C:`Rarities.luau`; T: Data/Gameplay. |
| B3.2 | Ultra Rare ≈1/250 M et annonce serveur avec pseudo | PARTIEL | P2 | équilibrage | Type/annonce présents ; taux 1/250 M non démontré par tables. |
| B3.3 | Secret non documenté, hors gameplay commun | CONFORME | P— | sécurité | `SecretGate.Triggered` est résolu dans `ServerScriptService` et seul le résultat est consommé par `HatchService`; aucun procédé n'est envoyé au client. |
| B3.4 | Rareté lisible sans texte | NON CONFORME | P2 | écart de design | V:`audit-recompense-ultrarare-injectee` : rareté/mutation textuelles, aucun portrait/modèle. |
| B3.5 | Taux affichés éclosion/Faille/élevage | PARTIEL | P2 | UI | Présents, mais V:`audit-first-rift-desktop` débordent du panneau et se chevauchent. |
| B3.6 | Mur public des détenteurs de Secrets | PRÉVU NON LIVRÉ | P— | contenu non livré | Lot 4. |
| B3.7 | Aucun partage in-game du procédé Secret | CONFORME | P— | design | Aucun canal d'aide Secret identifié ; mécanisme néanmoins visible dans code partagé (B3.3). |
| B3.8 | Six mutations et multiplicateurs ×2…×1000 | CONFORME | P— | équilibrage | C:`Mutations.luau`; T: Gameplay/MutationWeights. |
| B3.9 | Mutation indépendante et multiplicative avec rareté | CONFORME | P— | design | T:`Gameplay_Test` power et rolls. |
| B3.10 | Croisement, héritage, mutation nouvelle, génération | CONFORME | P— | design | T: Breeding ; C:`BreedingService`. |
| B3.11 | Pourcentages, généalogie et stats détaillés | PARTIEL | P3 | UI | Pourcentages/généalogie présents ; export de données absent. |
| B3.12 | Export de données d'élevage | PRÉVU NON LIVRÉ | P— | contenu non livré | Aucun export identifié. |
| B3.13 | Slots d'équipement 1 puis +1/stade | CONFORME | P— | design | T: Evolution ; UI Sanctuaire. |
| B3.14 | Cœurs, colliers, reliques avec effets actés | CONFORME | P— | design | C:`Equipment`, `Evolution`, `HatchService`; T: Evolution. |
| B3.15 | Reliques uniquement en Faille et non achetables | CONFORME | P— | sécurité | C: seul grant de Relique dans `RiftService:225–231`; aucune offre Relique. |
| B3.16 | Évolution créatures/reliques/sanctuaire/arbre/rang/Index | PARTIEL | P2 | contenu non livré | Créatures/sanctuaire/arbre/Index présents ; fusion de reliques et rang joueur incomplets. |
| B3.17 | Index liste automatiquement toutes les espèces | CONFORME | P— | design | T:`Index_Test > catalog lists every species once`. |
| B3.18 | Index : possédée/découverte/inconnue | PARTIEL | P2 | UI | T: états logiques conformes ; V:`audit-index-tablet` seulement cadres `???`, sans portrait/silhouette. |
| B3.19 | Filtres familles, compteurs et bonus | CONFORME | P— | design | V: Tout/Feral/Mystic/Wild, 0/14, bonus ; T: famille. |
| B3.20 | Entrée rareté × mutation, Index quasi infini | CONFORME | P— | design | T: clé Species/Rarity/Mutation. |
| B3.21 | Index survit à la Renaissance | CONFORME | P— | progression | C:`Rebirth.ApplyReset` ne touche pas Index ; T: Rebirth. |
| B3.22 | 12 nœuds, 3 branches, +1 point/rebirth, permanents | CONFORME | P— | progression | C:`Config:174+`, `Rebirth:59`; T: SkillTree/Rebirth. |
| B3.23 | Arbre présenté en graphe avec liens/prérequis | NON CONFORME | P2 | UI | V:`audit-arbre-tablet` : liste verticale, aucun lien graphique, recouvrements. Rendre les coordonnées Row/Col et arêtes Requires. |
| B3.24 | Rien de l'arbre n'est vendu | CONFORME | P— | monétisation | Aucun produit/receipt de point d'arbre. |
| B3.25 | Perte rebirth : Essence + améliorations temporaires | CONFORME | P— | progression | C:`Rebirth:54–60`. |
| B3.26 | Conservation rebirth : Index, objets permanents, créatures, arbre | CONFORME | P— | progression | C:`Rebirth.ApplyReset` vide seulement les œufs, remet le sanctuaire au niveau 1 et clone tous les objets ; créatures, Index, étoiles, arbre et `TotalEssenceEarned` restent en place. T:`Rebirth_Test` conservation totale. |
| B3.27 | `TotalEssenceEarned` jamais réinitialisé | CONFORME | P— | progression | `ApplyReset` ne l'écrit pas ; T: seuils reposent dessus. |
| B3.28 | Étoile permanente et monde suivant à chaque rebirth | PARTIEL | P2 | contenu non livré | Étoile/multiplicateur présents ; monde suivant absent. |
| B3.29 | 4 rythmes : 15m/35m/1h15/3h | NON TESTABLE LOCALEMENT | P— | équilibrage | Sim 7 j timeout, aucun résultat exploitable. |
| B3.30 | Mode Rush par monde | PRÉVU NON LIVRÉ | P— | contenu non livré | Lot 4 ; objectifs encore ouverts §10. |
| B3.31 | Duel consenti avec mise et sim statique | PARTIEL | P2 | design | C/T: consentement, wager, sim seedée ; runtime 2 joueurs indisponible. |
| B3.32 | Attaque déployée vs défense non déployée | NON CONFORME | P2 | écart de design | `DuelService:132–137` additionne toutes les créatures du défenseur ; aucun état déployé. |
| B3.33 | Escrow remboursé refus/timeout/départ | CONFORME | P— | sécurité | `DuelService` conserve l'escrow dans `UpdateAsync`, libère une seule fois sur refus/timeout/départ et crédite à la reconnexion. Le runtime deux serveurs reste à valider ; `Duel_Test` couvre la résolution pure. |
| B3.34 | Aucun vol hors ligne | CONFORME | P— | sécurité | Une cible doit être en ligne ; l'escrow du challenger parti reste dans `RiftBeastsDuels_v1` jusqu'au crédit de reconnexion, sans transfert de créature hors ligne. |
| B3.35 | Marché Essence, frais 5 %, caps prix/listings | CONFORME | P— | design | C:`MarketService:43–100`, Config ; T: Market. |
| B3.36 | Retrait double confirmation + 60 s | PARTIEL | P2 | UX | Délai et second appel présents ; V/runtime multijoueur non vérifiés, feedback silencieux. |
| B3.37 | Achat au cap refusé, vendeur intact | CONFORME | P— | sécurité | T:`Market_Test > rejects when buyer sanctuary is full`. |
| B3.38 | Transfert marché atomique, double achat impossible | PARTIEL | P0 | sécurité | Claim `Listing_{id}` désormais atomique par `UpdateAsync` (`MarketService:328–342`) et bloque le double achat ; une panne après claim avant débit/crédit est encore réparée par balayage différé, donc le transfert complet n'est pas transactionnel. |
| B3.39 | Marché DataStore source de vérité, Messaging notification | PARTIEL | P2 | sécurité | Index et listings sont relus depuis DataStore et notifient Messaging hors Studio ; les erreurs de persistance sont seulement journalisées et la concurrence réelle reste non testable localement. |
| B3.40 | Œufs Épique ~2000 et Légendaire ~8000 | CONFORME | P— | équilibrage | C:`Config:11–12`; valeurs encore indicatives. |
| B3.41 | Mythique/UltraRare hors achats, Secret hors gameplay commun | CONFORME | P— | sécurité | `Ascension.ClampToSource` bride Mythic+ à Legendary pour toute source autre que `Rift`; le Secret est résolu par `SecretGate` serveur dans la fenêtre Eclipse/omen, jamais par une table boutique. T:`Ascension_Test`, `Data_Test`. |
| B3.42 | 10→30 espèces | PRÉVU NON LIVRÉ | P— | contenu non livré | Runtime affiche 14 espèces ; Lot 4 vise 30. |
| B3.43 | +3–5 espèces/semaine post-launch | PRÉVU NON LIVRÉ | P— | contenu non livré | Live ops futur. |
| B3.44 | Spawn sans panneau bloquant, œuf visible, prompt unique | PARTIEL | P1 | FTUE | V:`audit-ftue-spawn-desktop` sans plein écran, mais œuf masqué/surexposé et deux objectifs. |
| B3.45 | Première récompense/éclosion <15 s | CONFORME | P— | FTUE | Parcours automatisé : 1 déplacement + maintien E, succès dans l'ordre de 14 s ; logs Hatch/achievement. |
| B3.46 | T+20 créature visible au travail, +N cohérent | NON CONFORME | P2 | FTUE | V:`audit-ftue-first-hatch-desktop` aucune créature proche identifiable ; rendement HUD présent. |
| B3.47 | Première Faille T+60–90, accessible et gagnée | PARTIEL | P1 | FTUE | Ouverture/entrée à ~90 s conformes ; la victoire n'a pas été obtenue avec l'entrée souris disponible. Le cooldown anti-réentrée est désormais codé (`RIFT_REENTRY_COOLDOWN=6`), mais le parcours novice doit encore être rejoué avec une attaque fiable. |
| B3.48 | Menus seulement T+2–3 min, 3 prompts monde | NON CONFORME | P1 | FTUE | Tutoriel 4 étapes dès T0 et ObjectiveBanner demande le menu ; panneau large couvre le monde. |
| B3.49 | Boucle complète <5 min, prochaine action claire | NON CONFORME | P1 | FTUE | Pas de victoire Faille ; objectifs triples ; menu nommé de façon incohérente. |
| B3.50 | Orbes ~45 s, max simultané et plafond horaire | CONFORME | P— | sécurité | Config 45/3/20 ; T: Orbs. Runtime click non observé. |
| B3.51 | Gains cliquables serveur, rate-limités/plafonnés | CONFORME | P— | sécurité | `OrbService` + T: cap ; clic créature gain nul. |
| B3.52 | Peu de joueurs : ticker, stats, marché, Éclipse | PARTIEL | P2 | contenu | Ticker/stats/Éclipse présents ; cross-server non publié, PNJ absent. |
| B3.53 | Beaucoup : ticker ≤10/min, priorité hauts rangs, jauges | PARTIEL | P2 | contenu | Throttle 6 s et bypass hauts rangs ; runtime charge non testée. |
| B3.54 | Streak, quêtes, pity, saison | CONFORME | P— | rétention | T: Streak/Quest/Luck/Season ; HUD pity visible. |

### B4–B6 — Game feel, UI, social, cartes et cible

| ID | Exigence | Statut | Sév. | Catégorie | Preuve / critère de correction |
|---|---|---|---:|---|---|
| B4.1 | Hover créatures/joueurs/Index avec stats et valeur | PARTIEL | P2 | UI | Hover code/tests pour créatures/listings ; Index sans portrait, autres joueurs non testés. |
| B4.2 | Créatures suivent le joueur | PARTIEL | P2 | game feel | Code FollowController ; V: aucune créature alliée identifiable dans les captures. |
| B4.3 | Farmeur/Cueilleur/Gardien agissent visiblement | PARTIEL | P2 | game feel | `FarmBehaviors` présent ; V: comportement non discernable. |
| B4.4 | Attaques/impacts visibles en Faille | NON CONFORME | P2 | game feel | V:`audit-first-rift-desktop` gardien absent visuellement, petite étincelle seulement. |
| B4.5 | Un objectif prioritaire, jamais contradictoire | NON CONFORME | P1 | UI | V: 2–3 objectifs simultanés et tutoriel obsolète. |
| B4.6 | Sons aux moments clés | PARTIEL | P3 | audio | C:`Audio.luau` assets et triggers ; état de lecture non capturé. Qualité émotionnelle provisoire. |
| B4.7 | Ultra Rare clippable : ralenti + son + annonce | PARTIEL | P2 | game feel | Code Celebration/Cinematic ; V injectée sans effet clairement visible ni portrait. |
| B4.8 | Options vitesse UI/densité d'info | PRÉVU NON LIVRÉ | P— | contenu non livré | Aucune option dédiée identifiée. |
| B4.9 | Couveuse 3D, inventaire, max 3, prompts monde | PARTIEL | P2 | UI | R: 3 œufs posés ; V:`audit-couveuse-3-eggs-world` prompts invisibles, groupe serré et surexposé. |
| B4.10 | 4e placement refusé clairement | NON CONFORME | P3 | UX | Serveur refuse/log seulement (`IncubationService:278–280`), aucun message client. |
| B4.11 | Cinématique monde + carte portrait ≥4 s | PARTIEL | P2 | game feel | Délai 4 s codé ; portrait no-op ; capture après hatch sans carte visible. |
| B4.12 | AutoHatch sans duplication ni contournement cap | PARTIEL | P1 | sécurité | Tests MAX_PLACED, mais AutoPlace ne compte pas dans `placed`; spam visuel/cap non testé. |
| B4.13 | Arche permanente, brille, compte à rebours | PARTIEL | P2 | UI | Runtime gate 0,35/light 3 et countdown ; V arche non identifiable. |
| B4.14 | Créatures cliquables : équiper/évoluer/vendre | PARTIEL | P2 | UI | CreatureHud code ; non vérifié visuellement avec une créature proche. |
| B4.15 | Float +N et feedback clic | PARTIEL | P3 | game feel | Code `Fx.FloatText`; non discerné visuellement. |
| B4.16 | ObjectiveBanner priorité actée | CONFORME | P— | design | T:`Objective_Test`; problème d'intégration avec Tutorial traité B4.5. |
| B4.17 | Pouvoir visible : taille/aura/socles/team/theme | PARTIEL | P2 | game feel | Team power HUD/code partiels ; thème monde/socles/aura non validés. |
| B4.18 | Hotbar bas : Œufs/Faille/Sanctuaire | CONFORME | P— | UI | V toutes captures ; 100×52 px en téléphone paysage. |
| B4.19 | Onglets avancés derrière Plus | CONFORME | P— | UI | Runtime TabBar/Plus. |
| B4.20 | Resize dynamique, safe areas, cibles ≥44 px | PARTIEL | P2 | UI | Resize code ; boutons 100×52 ; V téléphone/tablette chevauchements et bords serrés. |
| B4.21 | Fermeture ✕, re-clic, Échap, B | PARTIEL | P2 | UI | Code pour les quatre ; Escape non testable via VirtualInput CoreGUI ; icône ✕ rendue comme carré rouge selon eyes. |
| B4.22 | Boutique unique prix/valeur/taux/timers | NON CONFORME | P2 | monétisation | V:`audit-boutique-tablet` aucun prix Robux, produits « à configurer », pas de timer VIP/offre. |
| B4.23 | Amis : rejoindre, toast join, visite sanctuaire | PARTIEL | P2 | social | JoinFriend/teleport présent ; toast/visite ami non démontrés, publié requis. |
| B4.24 | HUD possessions permanent | CONFORME | P— | UI | Runtime `🐾 n/max ★ stars 🌟 points`. |
| B4.25 | Groupe Roblox +10 %, tag, œuf quotidien | PRÉVU NON LIVRÉ | P— | contenu non livré | Lot 4 ; aucun `IsInGroup`. |
| B4.26 | Meute +10 %/ami, cap 3, jauge visible | PARTIEL | P2 | social | C/T cap conforme ; HUD texte seulement si amis ; runtime multi non testé. |
| B4.27 | Plafond global des multiplicateurs affiché | NON CONFORME | P2 | équilibrage | Luck cap 1 existe ; Essence multiplie plusieurs sources sans plafond global ni UI de cap. |
| B4.28 | Desktop 1920×1080 sans chevauchement | NON CONFORME | P2 | UI | V:`audit-ftue-spawn-desktop` tutoriel/hotbar, objectifs et éléments coupés. |
| B4.29 | Téléphone portrait 390×844 | NON TESTABLE LOCALEMENT | P— | outil | Simulateur annonce Portrait mais capture reste paysage ; procédure : device physique ou capture PlayClient réellement portrait. |
| B4.30 | Téléphone paysage 844×390 | NON CONFORME | P2 | UI | V:`audit-spawn-844x390` Essence/Faille et contrôles/tutoriel se chevauchent. |
| B4.31 | Tablette 1024×768 | NON CONFORME | P2 | UI | V:`audit-spawn-1024x768` contrôles masquent tutoriel, faisceau blanc géant, hotbar au bord. |
| B5.1 | Sanctuaires multi-mondes | PRÉVU NON LIVRÉ | P— | contenu non livré | Monde 2+ Lot 4. |
| B5.2 | Zone publique risquée sans perte | HORS PÉRIMÈTRE ACTUEL | P— | ambiguïté | Zone « ???? » non définie ; section 10/profondeur ouverte. |
| B5.3 | Aucune Essence passive en Faille | PARTIEL | P2 | sécurité | C:`EssenceService:110–113` force le taux à zéro quand `InRiftCombat=true`; le runtime post-correctif n'a pas été rejoué assez longtemps pour prouver le delta profil. Ajouter un test heartbeat dédié. |
| B5.4 | Éclipse toutes les 2 h, 10 min, indépendante population | CONFORME | P— | design | Config 7200/600 ; T: Eclipse. |
| B5.5 | Zone saisonnière 2 semaines, exclusive non rééditée | PRÉVU NON LIVRÉ | P— | contenu non livré | Live ops post-launch. |
| B6.1 | Profondeur/optimisation/tableurs | PARTIEL | P2 | design | Systèmes et taux présents ; export absent, UI superposée. |
| B6.2 | AFK compatible travail | CONFORME | P— | design | Rendement offline/passif présent. |
| B6.3 | Économie crédible dans 6 mois | NON TESTABLE LOCALEMENT | P— | économie | Nécessite économie live, sim longue et transactions sûres ; P0 marché bloque la crédibilité. |
| B6.4 | Aucune perte de progression subie | PARTIEL | P1 | progression | Renaissance et escrow duel sont maintenant conservateurs ; la fenêtre marché/receipt après claim ou grant reste susceptible de perdre/dupliquer une mutation avant preuve durable. |
| B6.5 | UI dense, propre, non infantilisante | PARTIEL | P2 | UI | Dense/adulte ; V: nombreux chevauchements, monde masqué. |
| B6.6 | Statut visible | PARTIEL | P2 | social | Tags/ticker/leaderboard existent ; créatures, mur VIP et visites incomplets. |
| B6.7 | Jeu sûr et jouable pour mineurs | PARTIEL | P2 | sécurité | Autorité serveur largement présente ; transactions P0 et remotes sans feedback/rate-limit uniforme. |

### B7–B9 — Monétisation, classements et règles absolues

| ID | Exigence | Statut | Sév. | Catégorie | Preuve / critère de correction |
|---|---|---|---:|---|---|
| B7.1 | Vendre temps/confort/chance, jamais accès | PARTIEL | P1 | monétisation | Offres majoritairement conformes ; exclusive Season Premium contredit la règle F2P. |
| B7.2 | Prix/taux/valeur affichés avant achat | NON CONFORME | P2 | monétisation | V boutique sans prix Robux et IDs 0. |
| B7.3 | Starter, potions, Server Boost, passes de confort | PARTIEL | P2 | contenu non livré | Définitions/UI présentes ; IDs 0, prix/multiplicateurs diffèrent des valeurs bible. |
| B7.4 | Offre premier achat et retours J2/J7 | PARTIEL | P2 | monétisation | Logique/tests présents ; pas de timer/ID réel. |
| B7.5 | Rename, titres, cosmétiques, bundle mensuel, mur soutiens | PRÉVU NON LIVRÉ | P— | contenu non livré | Lots 4–5/post-launch. |
| B7.6 | FOMO informatif, modal max 1/session | PARTIEL | P2 | monétisation | Eligibility présente ; aucune preuve runtime de limite modale, timers absents. |
| B7.7 | Sinks reroll/fusion/décor | PRÉVU NON LIVRÉ | P— | contenu non livré | Aucun de ces sinks livré. |
| B7.8 | Sim 14 j ×3 F2P/Starter/VIP/whale/meute | HORS PÉRIMÈTRE ACTUEL | P— | équilibrage | La simulation longue est une validation économique explicitement « à valider par sim » ; l'outil local plafonne à 7 j et les 15 runs ont dépassé 2m30. Aucun défaut de balance n'est conclu avant une exécution reproductible. |
| B7.9 | VIP dev product 30 j empilable | NON CONFORME | P1 | monétisation | C:`Config:328` gamepass permanent, aucun `VipExpiresAt` dans migration v7. Implémenter `Vip.Extend/IsActive` et receipt idempotent. |
| B7.10 | Timer VIP et conservation des gains à expiration | PRÉVU NON LIVRÉ | P— | contenu non livré | Aucun expiry/timer ; conservation non testable. |
| B7.11 | SKUs VIP −10 % seulement consommables autorisés | PRÉVU NON LIVRÉ | P— | contenu non livré | Note UI seule ; aucun SKU remisé dans Config. |
| B7.12 | Zone VIP visible, gate serveur, coffre/œuf/statut | PRÉVU NON LIVRÉ | P— | contenu non livré | Lot 2 annoncé mais aucun `VipService`/zone. |
| B7.13 | Aucun double paywall sur exclusive gameplay | PARTIEL | P1 | monétisation | Aucune double vente identifiée ; exclusivité premium unique demeure ambiguë avec F2P 100 %. |
| B7.14 | Receipt d'achat idempotent et atomique | NON CONFORME | P0 | sécurité | `PurchaseService:170–230` claim `pending` avant grant puis `done` après ; crash avant la preuve finale et la sauvegarde du profil peut rejouer l'effet. Rendre le grant et l'état durable rejouables dans une transaction unique. |
| B7.15 | Aucun achat Robux réel pendant l'audit | CONFORME | P— | sécurité | Aucun prompt d'achat déclenché. |
| B8.1 | Classement général | CONFORME | P— | social | Runtime leaderboard total et T: Leaderboard. |
| B8.2 | Classement plafond léger et seuil explicite | NON CONFORME | P2 | contenu non livré | Un seul classement « Essence totale », aucun cumul de dépense ni seuil Starter. |
| B8.3 | Starter seul reste éligible | PRÉVU NON LIVRÉ | P— | contenu non livré | Dépend du classement léger. |
| B8.4 | `TotalEssenceEarned` unique, jamais reset | CONFORME | P— | progression | Save/Essence/Rebirth conformes. |
| B8.5 | Refresh 5 min, sync cross-serveur, snapshots visitables | PARTIEL | P2 | social | 300 s/config et snapshot logique ; Messaging/visite publiée non testables. |
| B9.1 | Action facultative | AMBIGUÏTÉ BIBLE | P— | ambiguïté | Relique Faille obligatoire pour évolution finale. |
| B9.2 | F2P 100 % du contenu | AMBIGUÏTÉ BIBLE | P— | ambiguïté | Exclusive Season Premium. |
| B9.3 | Taux partout | PARTIEL | P2 | UI | Présents mais débordent/masqués. |
| B9.4 | Rusher rapide, Index long | NON TESTABLE LOCALEMENT | P— | équilibrage | Sim non aboutie et mondes absents. |
| B9.5 | Joueur tranquille non puni | PARTIEL | P2 | design | AFK/offline présents ; final evolution/action ambiguë. |
| B9.6 | Prochaine étape toujours visible | NON CONFORME | P1 | UI | Plusieurs étapes incompatibles visibles. |
| B9.7 | Écran vivant | PARTIEL | P2 | game feel | Code animations ; créatures non visibles dans preuves. |
| B9.8 | Rareté sans texte | NON CONFORME | P2 | game feel | Capture Ultra Rare textuelle, portrait absent. |
| B9.9 | Ultra Rare clippable | PARTIEL | P2 | game feel | Code prévu ; capture injectée ne montre pas l'effet attendu. |
| B9.10 | Index et arbre survivent au rebirth | CONFORME | P— | progression | `ApplyReset` ne les remet pas à zéro. |
| B9.11 | Reliques non achetables | CONFORME | P— | monétisation | Aucun SKU/chemin de grant boutique. |
| B9.12 | Aucune perte subie | PARTIEL | P1 | progression | Rebirth et duel remboursent/conservent désormais ; marché et receipts gardent une fenêtre de panne non transactionnelle documentée par AUD-P0-01/02. |
| B9.13 | Pas de réédition limitée | NON TESTABLE LOCALEMENT | P— | live ops | Nécessite catalogue et historique live. |
| B9.14 | Plafond léger affiché | NON CONFORME | P2 | UI | Classement absent. |
| B9.15 | Secrets : mur VIP, procédé caché, aucun partage | PRÉVU NON LIVRÉ | P— | contenu non livré | Mur Lot 4 ; trigger partagé à corriger. |
| B9.16 | Gains VIP conservés à expiration | PRÉVU NON LIVRÉ | P— | contenu non livré | VIP n'expire pas actuellement. |
| B9.17 | Jamais deux paywalls pour même exclusive | PARTIEL | P1 | monétisation | Pas de double paywall observé ; règle F2P contradictoire. |
| B9.18 | Taux publiés avant prix codés | PARTIEL | P2 | équilibrage | Taux présents, prix indicatifs déjà codés sans sim 14 j aboutie. |

## Couverture synthétique

Les 165 exigences atomiques B0–B9 se répartissent ainsi : 44 `CONFORME`, 65 `PARTIEL`, 23 `NON CONFORME`, 18 `PRÉVU NON LIVRÉ`, 6 `AMBIGUÏTÉ BIBLE`, 7 `NON TESTABLE LOCALEMENT` et 2 `HORS PÉRIMÈTRE ACTUEL`. Les tendances sont nettes : la logique pure est mieux couverte que le runtime, les systèmes transactionnels concentrent les P0, et l'interface concentre la majorité des P1/P2.

### Règles absolues (18)

| Résultat | Règles |
|---|---|
| CONFORME | 3 : action facultative avec récompense de défaite, Index/arbre persistants, Reliques non achetables. |
| PARTIEL | 6 : taux partout, joueur tranquille, écran vivant, Ultra Rare clippable, absence de perte non garantie par les transactions, taux avant prix. |
| NON CONFORME | 3 : prochaine étape unique, rareté sans texte, classement léger affiché. |
| AMBIGUÏTÉ BIBLE | 2 : F2P 100 % contre exclusive Premium, et absence de double paywall face à cette même exclusive. |
| NON TESTABLE LOCALEMENT | 2 : vitesse rusher et absence de réédition d'items limités. |
| PRÉVU NON LIVRÉ | 2 : mur VIP des Secrets et conservation des gains VIP à expiration. |

## Chronologie FTUE observée

Les captures visuelles ont été prises avant les commits correctifs `a595b60`, `bf18eca` et `b07fb22`. Elles restent valides pour les écarts UI/FTUE visuels, mais les écarts Renaissance, réentrée de Faille, revenu passif et rareté achetable ont été recontrôlés statiquement sur `c8866e5` et ne sont plus comptés comme régressions actives lorsqu'ils sont corrigés.

| Temps approximatif | Action/état | Résultat |
|---|---|---|
| T+0–5 s | Spawn | Aucun plein écran ; œuf/couveuse surexposés, deux objectifs contradictoires, tutoriel sur la hotbar. |
| T+6–14 s | 1 déplacement vers `IncubatingEgg.Shell`, maintien E 0,8 s | Hatch Uncommon réussi, +50 succès, aucun menu nécessaire. |
| T+15–30 s | Après révélation | 1/10, rendement 1,3/s ; créature non identifiable près du joueur ; étape « Ouvre le Menu » sans bouton Menu. |
| T+~90 s | Faille | Arche active (transparence 0,35, lumière 3), entrée réussie ; HUD et taux débordent, gardien non discernable. |
| T+~2 min | Combat | Défaite observée sur l'ancien build capturé ; sur `c8866e5`, cooldown anti-réentrée et garde de revenu passif présents, mais victoire novice non rejouée avec input fiable. |
| T+5 min | Critère global | NON ATTEINT : aucune Faille gagnée, objectifs encore contradictoires, prochaine action ambiguë. |

Interactions minimales mesurées : 1 déplacement + 1 maintien E pour le hatch ; 1 déplacement pour la Faille ; attaques par clics répétés. Le harness n'expose pas un compteur fiable de clics acceptés, donc le TTK n'est pas retenu comme mesure d'équilibrage.

## Captures et observations `eyes`

| Capture | Observation retenue |
|---|---|
| `audit-ftue-spawn-desktop` | Deux objectifs contradictoires, tutoriel empiétant sur hotbar, bloom fort, élément rose coupé. |
| `audit-ftue-first-hatch-desktop` | Créature non identifiable, révélation absente au moment de capture, étape « Menu » incohérente, surexposition. |
| `audit-first-rift-desktop` | Gardien/alliés non identifiables, impacts peu lisibles, objectifs triples, taux hors panneau. |
| `audit-spawn-390x844` | Capture restée paysage ; portrait non validable ; HUD et contrôles se chevauchent. |
| `audit-spawn-844x390` | Essence/Faille se recouvrent, contrôles sur tutoriel, monde masqué. |
| `audit-spawn-1024x768` | Joystick/saut masquent tutoriel, faisceau blanc géant, hotbar au bord. |
| `audit-couveuse-3-eggs-world` | 3 œufs présents, prompts invisibles, sphères/faisceaux blancs surexposés, avatar masque le centre. |
| `audit-sanctuaire-tablet` | Panneau presque vide, aucun portrait/pouvoir, toasts sur titre. |
| `audit-index-tablet` | Cartes `???` vides, aucune silhouette/portrait, rangée coupée. |
| `audit-arbre-tablet` | Liste verticale sans graphe/liens, prérequis/rangs qui se chevauchent. |
| `audit-boutique-tablet` | Aucun prix Robux, aucun timer VIP/offre, produits à configurer. |
| `audit-renaissance-tablet` | Conservation annoncée limitée à la meilleure créature ; aucun monde/thème. |
| `audit-recompense-ultrarare-injectee` | État injecté : carte textuelle, aucun portrait, célébration non discernable. |

## Findings prioritaires

### AUD-P0-01 — Double vente marché cross-serveur

- Exigences : B3.38, B3.39 ; catégorie sécurité/transaction ; P0.
- Environnement : statique, commit audité ; runtime cross-serveur non disponible.
- Reproduction : deux serveurs chargent le même listing, deux acheteurs lancent `MarketBuy` avant le prochain refresh.
- Attendu : un seul claim atomique ; un seul débit, un seul transfert, un seul crédit vendeur.
- Observé : le claim `Listing_{id}` est maintenant atomique (`MarketService:328–342`), mais le débit acheteur, le règlement vendeur et la suppression du listing restent des opérations séparées. Une panne après le claim peut donc déclencher le balayage différé et créditer le vendeur sans preuve durable du débit acheteur.
- Fréquence/confiance : fenêtre rare mais catastrophique ; confiance haute. Joueurs touchés : acheteurs/vendeurs.
- Cause probable : absence de journal transactionnel reliant le claim au débit et au règlement, malgré le verrou atomique du listing.
- Critère : test concurrent et fault-injection prouvant un seul gagnant, un seul débit, un seul transfert et un seul crédit vendeur, y compris après redémarrage.
- Non-régression : test logique avec deux claims et validation sur deux serveurs publiés.

### AUD-P0-02 — Receipt grant non atomique

- Exigence : B7.14 ; catégorie sécurité/économie ; P0.
- Environnement : statique sur `c8866e5` ; receipt sandbox non déclenché, aucun Robux réel.
- Reproduction : receipt reçu, claim `pending`, grant réussi, processus interrompu avant l'état `done` et la sauvegarde du profil.
- Attendu : replay sans double grant, et `PurchaseGranted` seulement après preuve durable.
- Observé : claim `pending` par `ReceiptsStore:UpdateAsync` avant grant, puis état `done` écrit après grant (`PurchaseService:170–230`). Une interruption avant l'écriture `done` et avant la sauvegarde du profil laisse un receipt rejouable avec effet déjà appliqué en mémoire.
- Fréquence/confiance : rare mais catastrophique ; confiance haute. Joueurs : tous acheteurs.
- Cause probable : le claim durable et le profil/grant ne sont pas dans une même transaction ; la fenêtre résiduelle est reconnue par le commentaire `ponytail` du code.
- Critère : même `PurchaseId` rejoué N fois donne exactement un effet ; panne entre chaque étape couverte.
- Non-régression : test fault-injection du store et validation sandbox produit publié sans Robux réel.

### AUD-P2-03 — Défense de duel utilise toutes les créatures

- Exigence : B3.32 ; catégorie écart de design ; P2.
- Environnement : code serveur `c8866e5` ; duel multi-joueur non disponible dans l'instance Studio unique.
- Reproduction : profil défenseur avec une équipe déployée et une créature forte non déployée, accepter un duel.
- Attendu : puissance défensive calculée uniquement sur l'équipe déployée/validée.
- Observé : `DuelService:199` passe `defenderProfile.Data.Creatures` complet à `DuelSim.TeamPower` ; aucun état de déploiement n'est sélectionné.
- Fréquence/confiance : toujours pour un profil multi-créatures ; haute. Joueurs : participants aux duels.
- Critère : la défense et le résultat changent uniquement avec l'équipe déclarée, jamais avec une créature de réserve.
- Non-régression : test DuelSim avec réserve forte + équipe faible, puis duel à deux clients publié.

### AUD-P2-04 — Erreur runtime du compagnon au démarrage

- Exigences : B1.5/B4.2/B4.3 ; catégorie bug/game feel ; P2.
- Environnement : Play Server frais du commit `c8866e5`.
- Reproduction : démarrer une session et attendre l'initialisation de `CreatureDisplay`.
- Attendu : module client initialisé, créature et effets disponibles sans stack trace.
- Observé : console `Fx is not a valid member of PlayerScripts "Players.windseries83.PlayerScripts"`, `CreatureDisplay:11` ; les captures `eyes` ne montrent ensuite aucune créature proche identifiable.
- Fréquence/confiance : systématique au démarrage observé ; haute. Joueurs : tous les joueurs après hatch.
- Critère : résolution sûre de `Fx` ou fallback, zéro erreur console et créature visible avec comportement Farm/Cueilleur/Gardien.
- Non-régression : Play neuf, hatch, suivi 60 s et fermeture de session sans duplication de connexions.

### AUD-P1-05 — FTUE donne plusieurs prochaines actions

- Exigences : B0.12/B1.4/B3.44/B3.48/B4.5/B9.6 ; design/UI ; P1.
- Environnement : Play neuf desktop, captures `eyes` synchronisées sur le build FTUE.
- Reproduction : nouveau profil, spawn.
- Attendu : un prompt monde unique, zéro menu avant le farm visible.
- Observé : ObjectiveBanner demande le menu, Tutorial demande E, puis « Menu » inexistant ; toasts Faille s'ajoutent.
- Fréquence/confiance : toujours ; haute. Joueurs : nouveaux.
- Critère : à chaque état FTUE, une seule consigne effective ; les autres surfaces sont masquées ou cohérentes.
- Non-régression : test pur d'arbitrage Objective/Tutorial + playtest <5 min.

### AUD-P1-06 — Première victoire de Faille non démontrée en FTUE

- Exigence : B3.47 ; catégorie FTUE/équilibrage ; P1.
- Environnement : Play neuf, arche et HUD observés ; input souris disponible mais non instrumenté pour compter les attaques acceptées.
- Reproduction : nouveau profil, attendre l'ouverture, entrer et attaquer avec les clics disponibles.
- Attendu : Faille accessible et gagnable par un novice avant T+5 min.
- Observé : arche et HUD présents à ~90 s, mais la session observée s'est terminée en défaite ; le harness n'a pas confirmé assez d'attaques acceptées pour conclure à un TTK conforme. Le cooldown anti-réentrée est désormais présent.
- Fréquence/confiance : résultat non concluant mais critère non prouvé ; confiance moyenne. Joueurs : nouveaux joueurs.
- Critère : scénario reproductible gagnant avec feedback d'attaque et récompense unique, sans réentrée automatique.
- Non-régression : Play neuf avec input fiable, chronométrage T+60–90/T+5 min et logs `Enter/Attack/Won`.

### AUD-P2-07 — Arbre d'étoiles présenté comme liste

- Exigence : B3.23 ; catégorie UI/progression ; P2.
- Environnement : capture `eyes` `audit-arbre-tablet`, profil tablette temporaire.
- Reproduction : ouvrir l'arbre sur tablette ou desktop.
- Attendu : trois branches, liens et prérequis lisibles comme graphe.
- Observé : `audit-arbre-tablet` montre une liste verticale sans arêtes graphiques ; les rangs/prérequis se chevauchent.
- Fréquence/confiance : systématique ; haute. Joueurs : tous les joueurs investissant des étoiles.
- Critère : chaque nœud est positionné par branche/colonne, chaque lien `Requires` visible, achat et verrouillage lisibles.
- Non-régression : test de correspondance graphe/Config + captures des quatre formats.

### AUD-P2-08 — UI responsive masque le monde

- Exigences B4.20/B4.28/B4.30/B4.31 ; UI ; P2.
- Environnement : captures `eyes` desktop 1920×1080, téléphone paysage 844×390 et tablette 1024×768 ; portrait déclaré mais non capturé correctement.
- Reproduction : lancer un Play neuf sur chaque format et laisser HUD, tutoriel, hotbar et panneau Faille visibles.
- Attendu : safe areas respectées, aucune intersection HUD/objectif/contrôle, listes défilables et cibles tactiles ≥44 px.
- Observé : chevauchements HUD/objectifs/tutoriel/contrôles sur desktop, téléphone paysage et tablette ; portrait non capturé.
- Fréquence/confiance : systématique dans les trois captures ; haute. Joueurs : tous les utilisateurs tactiles et petits écrans.
- Cause probable : ancres et largeurs compactes calculées sans rectangle réservé commun pour toasts, joystick et hotbar.
- Critère : rectangles effectifs sans intersection interdite, safe areas respectées, scroll accessible, boutons ≥44 px.
- Non-régression : Device Simulator + coordonnées `AbsolutePosition/AbsoluteSize` sur 4 formats.

### AUD-P2-09 — Rareté et Index sans visuel

- Exigences B3.4/B3.18/B4.7/B9.8 ; game feel/UI ; P2.
- Environnement : Play desktop/tablette et carte Ultra Rare injectée côté serveur pour isoler le rendu.
- Reproduction : éclore un œuf, ouvrir l'Index dans les états `???`/découverte/possédée, puis afficher une récompense Ultra Rare.
- Attendu : taille, aura, particules ou silhouette identifient la rareté sans lire le texte ; la carte reste visible ≥4 s.
- Observé : `CreaturePortrait.Show` volontairement no-op ; Index et Ultra Rare sans portrait/silhouette, carte injectée textuelle seulement.
- Fréquence/confiance : systématique dans les captures disponibles ; haute. Joueurs : tous les joueurs lors d'un hatch ou de la consultation de l'Index.
- Cause probable : retrait volontaire des portraits 3D sans fallback graphique partagé.
- Critère : chaque état possède silhouette/portrait/forme et rareté identifiable sans texte, validés par `eyes`.
- Non-régression : cas HatchResult commun/épique/Ultra Rare injectés, puis captures eyes desktop et tactile.

### AUD-P2-10 — VIP livré comme entitlement permanent

- Exigences B7.9–B7.12 ; monétisation ; P1/P2.
- Environnement : statique sur `c8866e5`, boutique tablette `audit-boutique-tablet`, aucun achat réel.
- Reproduction : ouvrir Boutique et inspecter `Config.GAMEPASSES.VIP`, puis tenter de distinguer VIP actif, expiré et SKU remisé.
- Attendu : dev product 30 jours empilable, horloge serveur, timer visible, gains conservés après expiration, zone visible mais gate serveur.
- Observé : VIP est un gamepass permanent, pas de `VipExpiresAt`, timer, SKU remisé ni zone ; IDs produits restent à 0.
- Fréquence/confiance : toujours dans le build audité ; haute. Joueurs : acheteurs VIP et joueurs observant la zone/boutique.
- Cause probable : entitlement historique booléen non migré vers une date et contenu VIP non livré.
- Critère : dev product 30 j empilable, clock serveur, expiry conservant les gains, zone gate serveur et SKU mapping testés.
- Non-régression : tests VIP/Purchase avec horloge injectée et captures actif/expiré sans prompt Robux réel.

## Autres écarts et polish P3

- 4e œuf refusé sans feedback client.
- Icône de fermeture rendue comme carré rouge dans plusieurs captures.
- Faisceaux d'œufs et bloom écrasent les silhouettes ; prompts invisibles.
- La qualité émotionnelle audio reste un jugement provisoire ; seuls les déclenchements sont objectivement couverts.

## Éléments prévus mais non livrés

Lot 4 : espèces 15–30, monde 2/thème/Rush, mur VIP Secrets, mur des soutiens, rename/cosmétiques/titres, PNJ sauvages, groupe Roblox.  
Lot 5 : IDs produits réels, publication, playtest fermé multi.  
Post-launch : rotations live ops, zone saisonnière, pub récompensée éventuelle.

## Plans de correction P0–P2

- [FTUE, monde, game feel et UI](../../../superpowers/plans/2026-08-26-correctifs-ftue-monde-ui.md)
- [Boucle principale, progression et économie](../../../superpowers/plans/2026-08-26-correctifs-progression-economie.md)
- [Social, monétisation et live ops](../../../superpowers/plans/2026-08-26-correctifs-social-monetisation-liveops.md)

## Procédures de validation ultérieure

- Marché : deux serveurs publiés, deux acheteurs synchronisés sur le même listing, store instrumenté, un seul commit.
- Duel : deux clients ; refus, timeout, déconnexion des deux rôles et crash serveur ; réconciliation à la reconnexion.
- Achats/VIP : environnement de test publié, receipts sandbox, replays de `PurchaseId`, expiration via horloge injectée ; aucun achat Robux réel pendant QA agent.
- Messaging/DataStore : vérifier ordering, duplicate notifications et reprise après panne ; DataStore reste la source de vérité.
- Téléportations/amis/visites : deux serveurs publiés et comptes amis.
- Portrait 390×844 : PlayClient/device physique ou capture Studio réellement portrait ; vérifier safe areas et clavier virtuel.
- Live ops/items limités : audit du catalogue publié et historique des rotations.
- Balance : relancer `EconomySim` sur 14 jours, 3 runs par profil (F2P/Starter/VIP/whale/meute), puis comparer les quatre cibles de renaissance ; jusqu'à cette exécution, B7.8 reste `HORS PÉRIMÈTRE ACTUEL`.

## Conclusion

La logique pure est solide (232/232), et les correctifs récents ont fermé la conservation Renaissance, le cooldown de Faille, le passif en combat, le Secret serveur, le plafonnement Mythic, le crash `CreatureDisplay`, l’objectif FTUE concurrent et le VIP daté. Le GO reste bloqué par la validation publiée des transactions/cross-server, l’arbre graphique, les surfaces VIP/sociales non livrées et les quatre captures responsive complètes. Les éléments Lot 4–5 sont séparés des régressions et ne doivent pas masquer les défauts déjà présents.

## Addendum d’implémentation — workspace 2026-08-26

Cet addendum distingue le commit audité ci-dessus des changements effectués ensuite dans le workspace partagé. Aucun profil persistant réel ni achat Robux n’a été utilisé.

| Axe | Changement livré | Vérification locale |
|---|---|---|
| FTUE | `Objective.Tutorial` devient la source unique ; `Tutorial` ne rend plus de bannière concurrente ; menus/action bar restent masqués jusqu’à `TutorialDone`. | Play neuf : objectif « Approche l’œuf… », `Content.Visible=false`, `ActionBar.Visible=false`, puis objectif Faille après HatchResult. |
| Faille | Difficulté tutorielle (HP/dégâts réduits) et dégâts stockés dans le combat ; cooldown conservé. | `Rift_Test` + `RiftDifficulty` passent ; aucune erreur console au boot/hatch. |
| Créatures | `CreatureDisplay` attend ses modules Rojo ; `CreaturePortrait` utilise le template ou un fallback géométrique coloré/silhouette. | Appel Client direct : modèle créé avec 12 descendants, fond visible ; aucune erreur `Fx` au démarrage. |
| Transactions | Ledger marché `Escrowed → Open → Claimed → BuyerApplied → SellerApplied → Settled`, crédit vendeur online/offline via message ProfileStore ; receipts bornés et sauvegarde confirmée avant `PurchaseGranted`. | Tests `MarketTransaction`/`PurchaseLedger`, lint et suite Studio. Le crash fault-injection et deux serveurs restent à publier. |
| Progression/VIP | migration v9 (`EconomyLedger`, `MarketLedger`, `DuelDefense`, `VipExpiresAt`), VIP 30 jours empilable, bonus/tags lus par date serveur, défense duel déployée. | `Migration_Test`, `Vip_Test`, `Duel_Test` et suite Studio. Zone VIP, catalogue réel et téléportations restent hors place non publié. |
| UI | cibles `UiKit.Button` portées à 44 px minimum ; bannière objectif contrainte 280–460 px ; onglet Marché masqué tant que `MARKET_ENABLED=false`; bouton de déploiement duel. | `stylua --check src`, `selene src`, inspection Client Play. Captures multi-formats à refaire dans un vrai portrait. |

Résultat de la nouvelle session Server Studio : **232 run, 232 passed, 0 failed**. Les messages ProfileStore/MemoryStore « API indisponibles » restent attendus dans ce place non publié. Le runner Lune local est conservé comme outil auxiliaire mais ne remplace pas la session Studio : son shim ne supporte pas les yields/metamethods Roblox et termine en échec avant exécution des cas.
