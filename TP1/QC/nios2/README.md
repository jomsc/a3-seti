# Racine carree entiere sur Nios II

`sqrt_benchmark.c` reprend la recurrence du FPGA : 32 iterations, extraction de
la paire superieure de D, mise a jour de R selon son ancien signe, construction
de Z selon le nouveau signe, puis decalage de D. Il renvoie floor(sqrt(A)) pour
une entree non signee de 64 bits. Aucun flottant ni appel a sqrt/libm.

R est signe sur 64 bits en C pour contenir les intermediaires sans debordement.
Le VHDL utilise une arithmetique modulaire sur 34 bits ; les deux versions donnent
le meme resultat. Une multiplication par 4 remplace le decalage de R negatif,
qui ne serait pas defini en C. Le calcul de Z et le decalage de D sont non signes.

## Compiler et lancer sur la carte

1. Dans Platform Designer, disposer d'un timer compatible timestamp, accessible
   par Nios II. Le driver Interval Timer doit pouvoir lire une capture du compteur.
   Pour reinitialiser le compteur entre les mesures, utiliser un timer dont les
   registres de periode sont configurables en ecriture.
2. Dans le BSP Editor, choisir ce timer dans `hal.timestamp_timer` au lieu de
   `none`. Ne pas utiliser le meme timer comme `hal.sys_clk_timer` : ajouter un
   second timer si le systeme a besoin des deux fonctions.
3. Regenerer le BSP. Si le materiel a change, recompiler le projet Quartus et
   charger le fichier de configuration correspondant sur la carte.
4. Ajouter `sqrt_benchmark.c` comme fichier contenant `main` dans l'application
   Nios II liee au BSP. Retirer l'ancien `main` de cette application.
5. Compiler en C99 ou plus recent, avec une optimisation connue, par exemple
   `-O2`. Utiliser la libc standard pour les formats printf 64 bits (`PRIu64`) ;
   si necessaire desactiver `hal.enable_small_c_library` dans le BSP. Ne pas
   remplacer printf par alt_printf, qui ne prend pas en charge ces formats.
6. Charger l'executable sur le Nios II et lire la console JTAG UART. Conserver
   les lignes avec la frequence, le cout a vide et les six resultats.

Le programme signale l'absence de timer. Les noms du timer et sa frequence
proviennent de ton systeme et de son BSP, ils ne sont pas fixes dans ce fichier.
La cible Nios II et le BSP restent necessaires pour compiler le programme complet.

## Lire la mesure

La mesure entoure un appel a `sqrt_entier`, avec lecture de l'entree et ecriture
volatile du resultat. Ces acces empechent notamment le compilateur de remplacer
le calcul par une constante. Les printf et la conversion des ticks en ns sont
hors de la zone mesuree. Le cout a vide est indicatif et n'est pas soustrait.
Les ns sont calcules par division entiere, avec troncature inferieure a 1 ns ;
la resolution reelle reste celle du timer.

Les ticks sont ceux du timer, pas necessairement des cycles CPU :

    temps_ns = ticks * 1000000000 / frequence_timestamp
    cycles_CPU = ticks * frequence_CPU / frequence_timestamp

Chaque intervalle doit etre plus court que la plage du compteur 32 bits :
environ 2^32 / frequence_timestamp secondes. Le HAL ne garantit pas le
fonctionnement au-dela. Le test de saturation du programme est un controle
supplementaire, pas une autorisation a depasser cette plage.

Pour le rapport, relever la variante du Nios II, les frequences CPU et timestamp,
l'optimisation, la memoire utilisee et la presence de caches/interruptions. Faire
plusieurs executions : les interruptions et les caches peuvent faire varier la
mesure. Ce programme ne desactive pas les interruptions et mesure chaque cas
une fois par execution ; ce n'est pas une moyenne. Si la mesure approche le cout
a vide, une mesure par lot sera preferable.

La comparaison porte sur l'execution logicielle de l'algorithme sur le processeur
Nios II et le circuit de racine carree dedie. Elle ne suppose pas a l'avance un
resultat. Pour QB, les 32 cycles de calcul et les 33 periodes du protocole doivent
etre convertis avec la frequence reelle du circuit implante, pas avec la periode
arbitraire du banc ModelSim. Les 320/330 ns de simulation ne sont pas une mesure
de frequence maximale du FPGA. Les operations 64 bits peuvent couter plusieurs
instructions sur le Nios II 32 bits.

## References du BSP

- [HAL timestamp Nios II](https://www.intel.com/programmable/technical-pdfs/683525.pdf)
- [API du timer et choix system clock / timestamp](https://docs.altera.com/r/docs/683130/25.3/embedded-peripherals-ip-user-guide/hal-apis-and-macros)
- [Registres de periode et reinitialisation du compteur](https://docs.altera.com/r/docs/683130/26.1/embedded-peripherals-ip-user-guide/driver-implementation?contentId=FdTR6S2XVrPhiCM1WphTFA)

## Variante reprenant le Hello World fourni

`hello_world_sqrt.c` teste successivement 0, 1, 15, 512, 1194877489 et
4294967295. Il affiche un tableau avec l'entree, la racine, le resultat attendu,
les timestamps debut/fin, les ticks ecoules, la duree en ns et le bilan OK/ERREUR.
Le compteur est redemarre avant chaque calcul. Tous les affichages restent hors
mesure ; la conversion decimale n'utilise aucun format printf 64 bits.

Utiliser ce fichier a la place du main Hello World, sans ajouter en meme temps
`sqrt_benchmark.c` (deux fonctions main). Modifier le tableau `essais` pour
changer les entrees et les resultats attendus.

Apres les six calculs, la boucle copie toujours les switches sur les LED, mais
n'affiche plus de timestamps repetitifs pour laisser le tableau lisible.
Les acces materiels sont volatile ; verifier que les adresses et les acces
16 bits correspondent au systeme charge. La mesure inclut les lectures du timer,
l'appel, la lecture volatile de l'entree et l'ecriture du resultat.
Les restrictions de plage du timer et les conditions de comparaison indiquees
ci-dessus restent applicables.
