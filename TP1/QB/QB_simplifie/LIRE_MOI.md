# Question B — construire et comprendre le circuit

Objectif : une architecture structurelle avec **un seul additionneur dans le chemin de données**, et **une itération complète à chaque cycle de calcul**. Les trois registres R, D et Z changent ensemble au front d’horloge. Les opérations internes à une itération ne prennent pas chacune un cycle.

Le sujet de référence est `sujet_TP_VHDL_PEMB_2026-2027.pdf`, figure 1 et question b. Le modèle d’organisation est la partie « Impose a specific architecture » du cours `VHDL_multiplier_Case_study.pdf` : registres, multiplexeur, additionneur, `control_unit` et assemblage `seq_det`.

## 1. Partir de l’algorithme et identifier les registres

D, R et Z doivent être conservés entre deux itérations : ce sont les trois registres. Le compteur i appartient à l’unité de contrôle.

Pour n=32, A et D font 64 bits, Z et S font 32 bits, R et l’additionneur font 34 bits. R peut être négatif : son bit de poids fort est interprété comme son signe en complément à deux.

L’initialisation charge D=A, R=0 et Z=0. Ensuite chaque itération utilise **l’ancien R** pour choisir la formule, puis **le nouveau R** pour choisir le nouveau bit de Z.

## 2. Réduire le calcul à une addition

```text
paire = les deux bits de poids fort de D
X = (4R) OR paire

si ancien R >= 0 : Y = NOT(4Z)
sinon            : Y = 4Z+3

nouveau R = X + Y
nouveau Z = 2Z avec le bit de poids faible egal a (nouveau R >= 0)
nouveau D = 4D sur 2n bits
```

Les deux bits bas de 4R sont nuls. La paire ne contient que deux bits : OR donne donc le même résultat qu’une addition, sans retenue. En complément à deux, `NOT(x) = -x-1` modulo la largeur. Ainsi `NOT(4Z) = -(4Z+1)` : on ne doit pas inverser 4Z+1, et on n’a pas besoin d’ajouter 1.

Les expressions `Z & "00"` et `Z & "11"` produisent 4Z et 4Z+3 uniquement par connexion de bits. Le seul `+` du chemin de données est dans `additionneur.vhd`. Le décrément du compteur est dans la commande.

## 3. Réaliser les décalages par câblage

`&` désigne une concaténation, pas une porte AND. Une tranche sélectionne des fils existants ; les zéros sont des connexions à la valeur logique 0.

| Opération | Connexion VHDL |
|---|---|
| R multiplié par 4 | `r_q(W-3 downto 0) & "00"` |
| Deux bits supérieurs de D | `d_q(2*n-1 downto 2*n-2)` |
| D multiplié par 4, pour n>1 | `d_q(2*n-3 downto 0) & "00"` |
| 4Z | `z_q & "00"` |
| 4Z+3 | `z_q & "11"` |
| Z suivant, pour n>1 | `z_q(n-2 downto 0) & bit_z(0)` |

Exemple sur huit fils :

```text
entree : b7 b6 b5 b4 b3 b2 b1 b0
<< 2   : b5 b4 b3 b2 b1 b0  0  0
```

Le fil b0 de l’entrée est relié au bit 2 de la sortie, b1 au bit 3, etc. Aucun registre supplémentaire ni cycle supplémentaire n’est nécessaire. Un `shift_left` avec un décalage constant était déjà normalement synthétisé ainsi ; cette écriture rend le câblage visible.

Les `if generate` ne sont pas des étapes exécutées pendant le calcul. Ils choisissent le câblage à l’élaboration selon la constante n. Les petits cas n=1 évitent de déclarer des tranches invalides.

Les mux, l’inverseur et l’additionneur ont toutefois un temps de propagation. Le câblage n’ajoute pas de cycle, mais le chemin combinatoire complet doit se stabiliser avant le prochain front : une fréquence maximale ne peut pas être garantie sans analyse temporelle pour la carte cible.

## 4. Écrire les trois blocs élémentaires du cours

1. `registre.vhd` : un processus horlogé. Priorités : reset asynchrone, remise à zéro synchrone, chargement, conservation.
2. `mux2_1.vhd` : un processus combinatoire qui choisit I0 ou I1. Aucune horloge.
3. `additionneur.vhd` : une affectation concurrente avec un seul `+`. Aucune horloge.

Le registre est réutilisé trois fois. Il n’est pas nécessaire de créer un fichier pour chaque registre ou chaque décalage. Le cours place le décalage dans un registre spécialisé ; ici le même comportement est obtenu en reliant les bits décalés à l’entrée d’un registre générique.

## 5. Assembler votre chemin de données

Dans `chemin_donnees.vhd`, déclarer les fils internes, puis instancier les composants avec `entity work...`, `generic map` pour la largeur et `port map` pour les connexions.

- `RC0 = NOT(r_q(W-1))` : signe de l’ancien R. Il sélectionne MUX2.
- `r_next` : résultat du seul additionneur.
- `RC1 = NOT(r_next(W-1))` : signe du nouveau R. Il sélectionne MUX1.
- MUX1 choisit entre 0 et 1 ; son résultat est le nouveau bit de Z.
- MUX_D choisit A pendant l’initialisation, puis D décalé pendant le calcul.
- REG_R, REG_Z et REG_D chargent les nouvelles valeurs sur le même front.

MUX1 pourrait être remplacé directement par RC1 ; il est conservé pour correspondre à votre dessin. Le OR est également conservé pour rendre la correspondance visible. Ces éléments peuvent être simplifiés automatiquement à la synthèse.

Les noms « Shift Left 1/2/3 » du schéma sont les numéros des blocs. Les trois décalages correspondants sont de deux bits. « Shift Right 1 » extrait la paire supérieure de D. Les blocs `&` sur la branche Z se traduisent avec les constantes `00` et `11` indiquées plus haut ; ne pas décaler puis concaténer encore deux bits, ce qui multiplierait Z par 16.

## 6. Écrire la commande comme dans le cours

`unite_controle.vhd` conserve trois processus :

| Processus | Travail |
|---|---|
| CSM | Mémoriser l’état et le compteur au front d’horloge |
| NSC | Calculer l’état suivant à partir de l’état, start et i |
| OC | Calculer immédiatement init, calcul et done à partir de l’état |

Les commandes de OC ne sont pas enregistrées une seconde fois : elles doivent être disponibles avant le front où les registres les utilisent, comme expliqué dans le cours.

```text
wait --start=1--> init --> comp --derniere iteration--> end
                           ^                         |
                           | iterations restantes   | start=0
                           +------------------       v
                                                   wait
```

En `init`, charger les registres et mettre i=n-1. En `comp`, réaliser une itération et décrémenter i si i>0. Quand i=0, réaliser encore cette dernière itération, puis aller en `end`. Ne jamais décrémenter zéro.

Pas d’état « shift » : tous les décalages sont des connexions combinatoires. Les états de décalage séparés du multiplicateur du cours sont propres à son organisation ; on ne les recopie pas ici.

## 7. Assembler le sommet et compter les cycles

`sqrt_struct.vhd` instancie CU et DP, comme `seq_det` dans le cours. Les fils init/calcul relient la commande aux registres du chemin de données.

| Front | Action |
|---|---|
| F0 | start accepté en wait ; entrée dans init |
| F1 | Capture de A, R=Z=0 ; entrée dans comp |
| F2 | Première itération |
| ... | Une itération par front |
| F(n+1) | Dernière itération ; entrée dans end ; done monte après stabilisation |

Pour n=32 : **32 cycles de calcul, 33 périodes entre l’acceptation de start et done**. A doit rester stable jusqu’à F1 inclus. Lire S lorsque done=1. Si start reste à 1, le résultat et done sont maintenus. Dès que start=0 est vu en end, le circuit revient en attente et done retombe. Un start d’un seul cycle fonctionne également.

## 8. Pourquoi R tient sur n+2 bits

Après k itérations : `0 <= Z <= 2^k-1` et `-(2Z+1) <= R <= 2Z`. Pour k<=n, le résultat R tient dans un signé sur n+2 bits.

Le calcul de 4R peut déborder temporairement : les opérations sont volontairement réalisées modulo 2^(n+2). Les bits conservés donnent le résultat exact, puisque le R final de chaque itération est représentable et que seul son signe final est testé. On n’utilise pas le signe de 4R intermédiaire. Cette justification est indispensable pour autoriser la troncature.

D reste sur 2n bits : les deux bits éliminés sont ceux déjà consommés. Z gagne un bit par itération ; avant la dernière itération il tient dans n-1 bits.

## 9. Préparer la simulation ModelSim

Il reste six fichiers matériels, un banc de test autonome, un script ModelSim et ce guide. Le banc contient directement 17 calculs : petits nombres, carrés et voisins, grandes valeurs sur 64 bits, reset en cours de calcul et redémarrage. Il vérifie aussi les cycles et start/done.

`tb_blocs.vhd` était un banc unitaire supplémentaire ; il n’est pas nécessaire à cette simulation. `vecteurs_n32.txt` n’est plus utilisé par le banc simplifié. Ces deux fichiers sont retirés du dossier simplifié.

Dans ModelSim, placer ce dossier sous un chemin Windows local sans accent, puis exécuter :

```tcl
do C:/VHDL/sqrt_structurel/simuler_modelsim.do
```

Le script compile les six fichiers matériels dans l’ordre de dépendance, puis le banc. Il lance la simulation et affiche les signaux. Le message de réussite contient `PASS : 17 calculs`. Le banc arrête son horloge à la fin : la commande `run -all` se termine sans dépendre de `std.env.stop`. Tous les fichiers utilisent VHDL-93.

Pour regarder seulement le début manuellement, remplacer `run -all` par `run 400 ns`. Observer `current_state`, `i`, `r_q`, `r_next`, `S`, `sig_RC0`, `sig_RC1` et `done`. R et Z doivent changer au même front pendant les 32 itérations ; les valeurs combinatoires entre deux fronts sont des préparations du prochain chargement.

Pour la synthèse, choisir **sqrt_struct** comme sommet et exclure le banc de test.

## Validation de cette version — 20 octobre 2026

Compilation et simulation avec GHDL 6.0.0 : le banc autonome passe ses 17 calculs en VHDL-93. Le banc de régression précédent a également été exécuté sur le matériel modifié : 11 502 entrées réussies, exhaustives pour n=1 à 6 et complétées par des valeurs limites et aléatoires pour n=8, 16 et 32. La synthèse générique passe pour n=1 et n=32. Ce sont des validations GHDL ; le script ModelSim reste à exécuter sur votre machine virtuelle. La fréquence maximale sur FPGA n’a pas été mesurée.
