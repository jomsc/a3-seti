# Racine carrée — votre schéma, question 1.b

Cette version traduit le schéma `chemin_donnees.drawio` et l’image fournie en architecture structurelle. Elle suit la figure 1 du sujet `sujet_TP_VHDL_PEMB_2026-2027.pdf` et l’organisation `seq_det`, `control_unit`, `CSM`, `NSC` et `OC` du cours `VHDL_multiplier_Case_study.pdf`.

L’entité principale est **sqrt_struct**, architecture **seq_det**. Le circuit renvoie la racine carrée entière de A : par exemple 15 → 3, 16 → 4. Par défaut, n = 32, donc A fait 64 bits et S fait 32 bits.

## Fichiers et assemblage

| Fichier | Rôle |
|---|---|
| `registre.vhd` | Registre générique, reset, remise à zéro et chargement |
| `mux2_1.vhd` | Multiplexeur à deux entrées, sur un bit ou un bus |
| `additionneur.vhd` | Unique additionneur du chemin de données |
| `chemin_donnees.vhd` | Votre schéma : trois registres, mux, câblages, OR et inverseur |
| `unite_controle.vhd` | FSM et compteur d’itérations, selon le style du cours |
| `sqrt_struct.vhd` | Assemblage structurel de l’unité de contrôle et du chemin de données |
| `tb_sqrt_struct.vhd` | Banc de test de l’ensemble, avec résultat et protocole vérifiés |
| `tb_blocs.vhd` | Banc de test des blocs élémentaires |
| `vecteurs_n32.txt` | 2 023 couples entrée/racine attendue |
| `simuler_modelsim.do` | Compilation, lancement et affichage des signaux dans ModelSim |

La hiérarchie est : `sqrt_struct → CU + DP`, puis `DP → REG_D, REG_R, REG_Z, MUX_D, MUX1, MUX2, ADD`.

La question 1.b demande des entités séparées : il faut donc compiler tous les fichiers matériels dans l’ordre indiqué. Le nombre de processus n’est plus limité à un pour cette version structurelle ; cette contrainte concernait la question 1.a. Le fichier précédent `sqrt_seq.vhd` n’est pas nécessaire ici.

## Lecture précise de votre schéma

Les noms « Shift Left 1 », « Shift Left 2 », « Shift Left 3 » sont interprétés comme les **numéros des blocs**, pas comme des amplitudes de décalage. Les amplitudes et constantes ci-dessous sont imposées par l’algorithme ; elles complètent les indications du dessin.

| Élément du dessin | Traduction dans le code |
|---|---|
| Registre R | `REG_R`, bus `r_q`, signé sur n+2 bits |
| R ≥ 0 à gauche | `RC0 = NOT(r_q(n+1))` |
| Shift Left 1 | R décalé à gauche de **2 bits**, pour 4R |
| Registre D | `REG_D`, bus `d_q`, sur 2n bits |
| Shift Right 1 | Extraction `D(2n-1 downto 2n-2)`, équivalente à la division entière par 2^(2n-2) |
| OR | Assemblage de 4R et de la paire extraite de D |
| Shift Left 2 | D décalé à gauche de **2 bits**, en supprimant les bits déjà consommés |
| Registre Z | `REG_Z`, bus `z_q`, sur n bits |
| Shift Left 3 et les deux blocs `&` | Construction de `Z & "00"` et de `Z & "11"` |
| Inv | Inversion de `Z & "00"`, sur toute sa largeur |
| MUX2 | Choix de `4Z+3` si RC0=0, ou `NOT(4Z)` si RC0=1 |
| + | Une seule addition de deux bus sur n+2 bits |
| R ≥ 0 en sortie du + | `RC1 = NOT(r_next(n+1))`, signe du nouveau R |
| MUX1 | Choix du bit 0 ou 1 selon RC1 |
| `&` sous MUX1 | Décalage de Z d’un bit et insertion du nouveau bit à droite |
| Res | Sortie S, directement reliée à Z |

**Les blocs `&` désignent des concaténations**, et non des portes AND. Les constantes manquantes sont `"11"` sur la branche directe vers MUX2 et `"00"` sur la branche qui passe par l’inverseur.

Le décalage de Z et l’ajout des deux bits fixes sont exprimés ensemble par la concaténation. Il ne faut pas décaler Z de deux bits puis lui concaténer encore deux bits : cela multiplierait Z par 16.

Les blocs « R ≥ 0 » prélèvent le signe d’un bus. Ils ne remplacent pas ce bus par un seul bit : R continue vers son décalage ; la somme complète revient au registre R. RC0 et RC1 sont des fils de commande distincts.

Le schéma ne montre pas toutes les commandes de registre. Le code ajoute `init`, `calcul`, les chargements, les remises à zéro et `MUX_D` pour choisir entre l’entrée A et le D décalé. Ces éléments permettent l’initialisation et la conservation des résultats.

## Pourquoi un seul additionneur suffit

L’algorithme peut être réécrit avec deux opérandes X et Y :

```text
paire = D(2n-1 downto 2n-2)
X = (R << 2) OR paire

si ancien R >= 0 : Y = NOT(Z & "00")
sinon            : Y = Z & "11"

R_nouveau = X + Y
Z_nouveau = (Z << 1) avec bit 0 = (R_nouveau >= 0)
D_nouveau = D << 2, sur 2n bits
```

Le OR remplace la première addition : les deux bits bas de R décalé sont nuls et la paire ne possède que deux bits utiles. Les zones ne se chevauchent pas ; il n’y a donc aucune retenue entre elles.

Pour l’autre opérande :

- `Z & "11"` vaut exactement 4Z+3.
- En complément à deux, `NOT(x) = -x-1`, modulo la largeur utilisée.
- Donc `NOT(Z & "00") = -(4Z+1)`.

**On inverse 4Z, et non 4Z+1.** Inverser 4Z+1 sans correction produirait -4Z-2. Grâce au choix de 4Z à l’entrée de l’inverseur, aucune addition de 1 n’est nécessaire.

`additionneur.vhd` contient un seul opérateur `+`. Le chemin de données n’en contient aucun autre : les décalages sont fixes, les constantes sont concaténées, et les tests de signe ne lisent qu’un bit. La décrémentation du compteur appartient à l’unité de contrôle ; la contrainte du sujet porte sur l’additionneur du chemin de données.

RC0 est calculé sur **R mémorisé**. RC1 est calculé sur **la sortie de l’additionneur**, avant sa mémorisation. Les trois nouveaux registres sont chargés au même front : cela respecte les deux tests de R dans le bon ordre.

## Largeurs et arithmétique modulo

D possède 2n bits, Z possède n bits, R et l’additionneur possèdent **n+2 bits** : 64, 32 et 34 bits pour n = 32.

Après k itérations, on a les invariants :

```text
0 <= Z <= 2^k - 1
-(2Z+1) <= R <= 2Z
```

Ils sont vrais pour R=Z=0. Pour les deux branches du calcul, le nouveau R est compris entre -4Z-1 et 4Z+2. Si le nouveau R est négatif, le nouveau Z vaut 2Z ; sinon il vaut 2Z+1. L’encadrement est donc conservé.

Avec k ≤ n, R appartient à l’intervalle représentable par un signé sur n+2 bits. Cette largeur évite de conserver les n+4 bits prudents utilisés dans la première version pédagogique.

**Le terme intermédiaire 4R peut dépasser cette largeur.** Ici, c’est volontaire : les opérations sont faites modulo 2^(n+2), et on ne teste que le résultat final. Les bits bas de la somme modulo sont identiques à ceux de la somme mathématique. Comme le nouveau R mathématique tient dans n+2 bits signés, ces bits représentent exactement sa valeur, y compris son signe. Ce raisonnement autorise la largeur réduite ; ce n’est pas une règle générale permettant de tronquer arbitrairement les calculs.

Pour D, le calcul modulo 2^(2n) supprime les deux bits déjà consommés. Pour Z, il n’y a pas de perte utile : avant la dernière itération, il possède au plus n-1 bits significatifs.

## Unité de contrôle : reprendre le cours

Comme dans `control_unit` du cours, trois processus séparent :

- `CSM` : mémorisation de l’état au front d’horloge ; le compteur est également mis à jour ici.
- `NSC` : calcul combinatoire de l’état suivant.
- `OC` : calcul combinatoire des commandes des registres et de done.

Les commandes sont disponibles dès le changement d’état, avant le front où les registres doivent les utiliser. Les enregistrer de nouveau introduirait un cycle de retard, précisément le point signalé dans le cours.

| État | Commandes | Action au prochain front |
|---|---|---|
| wait_state | init=0, calcul=0, done=0 | Accepter start s’il vaut 1 |
| init_state | init=1, calcul=0, done=0 | D←A, R←0, Z←0, i←n-1 |
| comp_state | init=0, calcul=1, done=0 | Une itération, puis décrémenter i ou terminer |
| end_state | init=0, calcul=0, done=1 | Conserver le résultat ; revenir en attente si start=0 |

RC0 et RC1 ne sont pas des entrées de cette unité de contrôle : ils sélectionnent directement les multiplexeurs du chemin de données. Les branches négative et positive prennent toutes deux un cycle, donc le déroulement de la FSM est identique.

Le cours comporte des états de décalage séparés pour son multiplicateur. Ici, ils ne sont pas nécessaires : les décalages sont du câblage et leurs résultats sont chargés en même temps que R. On conserve le style du cours sans reprendre des états propres à un autre algorithme.

## Protocole et nombre de cycles

F0 désigne le front où start=1 est accepté en attente :

| Front | Action |
|---|---|
| F0 | Passage en init_state |
| F1 | Capture de A, initialisation, passage en comp_state |
| F2 | Première itération |
| … | Une itération par front |
| F(n+1) | Dernière itération ; passage en end_state ; done=1 après stabilisation |

Il y a **n cycles de calcul** et **n+1 périodes d’horloge entre F0 et done**. Pour n=32 : 32 cycles de calcul et une latence de 33 périodes après acceptation de start.

Cette latence diffère d’une période de celle du fichier précédent `sqrt_seq.vhd` : dans la version précédente done était enregistré en exécutant end_state au front suivant ; ici, comme dans l’unité de contrôle structurelle du cours, done est décodé directement depuis l’état. Ce n’est pas une différence du nombre d’itérations.

Maintenir A stable de F0 à F1 inclus. Après F1, A peut changer. Un start impulsionnel fonctionne : done dure alors une période. Si start reste à 1, done reste à 1 et le résultat est conservé. Après avoir mis start à 0, le front suivant ramène en attente et done retombe ; une nouvelle demande peut être acceptée au front d’après.

Reset est actif à 1 et asynchrone : il annule l’opération, remet les registres à zéro et ramène en attente. En utilisation matérielle, start et A sont supposés synchrones à clk et le relâchement du reset doit respecter les contraintes de la cible.

S expose Z, donc peut varier pendant le calcul. Lire le résultat avec done=1, après stabilisation des signaux. Le banc laisse 1 ns après chaque front pour observer le circuit.

## Lancer dans ModelSim

1. Extraire tout ce dossier dans un chemin Windows local sans accent, par exemple `C:\VHDL\sqrt_structurel`.
2. Ouvrir ModelSim et fermer toute simulation précédente si nécessaire.
3. Dans la console ModelSim, lancer :

```tcl
do C:/VHDL/sqrt_structurel/simuler_modelsim.do
```

Le script crée la bibliothèque work si nécessaire, compile les sources dans l’ordre, lance `tb_sqrt_struct`, ajoute les signaux et exécute tous les tests. Il utilise le dossier du script pour retrouver les vecteurs. Ne pas copier une ancienne bibliothèque work dans le dossier neuf.

La sortie attendue contient `PASS n=32 vecteurs=2023`. `std.env.stop` arrête ensuite le banc, ce qui est normal. Une erreur d’assertion avant ce message signifie un échec.

Pour lancer aussi les tests des blocs après la simulation principale :

```tcl
quit -sim
vcom -2008 -work work tb_blocs.vhd
vsim work.tb_blocs
run -all
```

Le script ModelSim est fourni pour cette organisation ; il n’a pas été exécuté dans ta machine virtuelle. Les sources ont été compilées et simulées avec GHDL.

Pour synthétiser, sélectionner `sqrt_struct` comme sommet et uniquement les six fichiers matériels. Les fichiers `tb_...`, les vecteurs et le script de simulation ne sont pas du matériel.

## Vérifications effectuées le 19 octobre 2026

Avec GHDL 6.0.0 :

- Compilation des six fichiers matériels en VHDL-93 et compilation de l’ensemble avec les bancs en VHDL-2008 : réussies.
- Tests unitaires : les 256 couples d’entrées d’un additionneur sur 4 bits, les deux sélections du multiplexeur et le chargement, la conservation et les priorités de reset du registre : réussis.
- Simulation du circuit complet : **11 502 entrées**, plus redémarrage après reset pour chaque largeur : réussie.
- Synthèse générique pour n=1 et n=32 : réussie.
- Vérification de la description synthétisée : un opérateur d’addition dans le chemin de données ; la décrémentation distincte du compteur est dans la commande.

| n | Entrées testées | Couverture |
|---:|---:|---|
| 1 | 4 | Toutes les entrées |
| 2 | 16 | Toutes les entrées |
| 3 | 64 | Toutes les entrées |
| 4 | 256 | Toutes les entrées |
| 5 | 1 024 | Toutes les entrées |
| 6 | 4 096 | Toutes les entrées |
| 8 | 1 996 | Limites, voisinages de carrés et données aléatoires |
| 16 | 2 023 | Limites, voisinages de carrés et données aléatoires |
| 32 | 2 023 | Limites, voisinages de carrés et données aléatoires |

Les résultats attendus proviennent de `math.isqrt`, indépendamment de la récurrence du composant. Le banc vérifie aussi done à la bonne période, start impulsionnel ou maintenu, le changement de A après capture, la conservation du résultat, le reset pendant une opération et le redémarrage. Les vecteurs n=32 sont inclus pour reproduire le cas demandé par le TP.

Aucune fréquence maximale ni occupation FPGA n’est annoncée : il faudrait une synthèse et un placement-routage pour la carte cible. Le code impose un seul additionneur logique dans le chemin de données ; son implantation physique dépend du synthétiseur et de la cible. La question 1.c n’est pas traitée ici.
