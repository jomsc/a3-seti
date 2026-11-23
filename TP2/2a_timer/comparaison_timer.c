/* TP2, question 2a. Timer Avalon 32 bits avec snapshot et periode modifiable.
 * Ce fichier remplace le main de l'application de test.
 */
#include <stdio.h>
#include "system.h"
#include "alt_types.h"
#include "sys/alt_timestamp.h"
#include "altera_avalon_timer_regs.h"

/* Remplacer TIMER_0_BASE par la macro du timer timestamp dans system.h. */
#define BENCH_TIMER_BASE TIMER_0_BASE
#define NB_LECTURES 1000u
#define NB_ESSAIS 5u

static volatile alt_u32 valeur_lue;

/* Valeur brute DECROISSANTE : ce n'est pas un timestamp HAL. */
static __attribute__((noinline)) alt_u32 lire_timer_direct(void)
{
    alt_u32 bas, haut;
    IOWR_ALTERA_AVALON_TIMER_SNAPL(BENCH_TIMER_BASE, 0);
    bas = IORD_ALTERA_AVALON_TIMER_SNAPL(BENCH_TIMER_BASE);
    haut = IORD_ALTERA_AVALON_TIMER_SNAPH(BENCH_TIMER_BASE);
    return ((haut & 0xffffu) << 16) | (bas & 0xffffu);
}

/* Meme chronometrage exterieur pour les deux methodes.
 * Le cout affiche inclut la boucle, l'appel et le stockage volatile.
 */
static int mesurer(int direct, alt_u32 *ticks)
{
    unsigned i;
    alt_u32 debut, fin;
    if (alt_timestamp_start() < 0) return -1;

    /* Prechauffage avant la mesure, identique en nombre de lectures. */
    if (direct) {
        for (i = 0; i < 32u; ++i) valeur_lue = lire_timer_direct();
        debut = alt_timestamp();
        for (i = 0; i < NB_LECTURES; ++i)
            valeur_lue = lire_timer_direct();
        fin = alt_timestamp();
    } else {
        for (i = 0; i < 32u; ++i) valeur_lue = alt_timestamp();
        debut = alt_timestamp();
        for (i = 0; i < NB_LECTURES; ++i)
            valeur_lue = alt_timestamp();
        fin = alt_timestamp();
    }
    if (fin < debut || fin == (alt_u32)-1) return -2;
    *ticks = fin - debut;
    return 0;
}

/* Affichage entier uniquement, sans formats printf 64 bits. */
static void afficher(unsigned essai, const char *nom, alt_u32 ticks,
                     alt_u32 frequence)
{
    alt_u32 entier = ticks / NB_LECTURES;
    alt_u32 millieme = (ticks % NB_LECTURES) * 1000u / NB_LECTURES;
    alt_u32 ns = (alt_u32)(((alt_u64)ticks * 1000000000ULL) /
                          ((alt_u64)frequence * NB_LECTURES));
    printf("%u | %s | %u | %u.%03u | %u\n", essai, nom,
           (unsigned)ticks, (unsigned)entier, (unsigned)millieme,
           (unsigned)ns);
}

int main(void)
{
    unsigned essai;
    alt_u32 direct, hal, frequence;
    alt_u32 min_direct = (alt_u32)-1, min_hal = (alt_u32)-1;
    if (alt_timestamp_start() < 0) {
        puts("ERREUR : verifier hal.timestamp_timer dans le BSP.");
        return 1;
    }
    frequence = alt_timestamp_freq();
    if (frequence == 0) {
        puts("ERREUR : frequence timestamp nulle.");
        return 1;
    }
    printf("Frequence timer : %u Hz\n", (unsigned)frequence);
#ifdef ALT_CPU_FREQ
    printf("Frequence CPU   : %u Hz\n", (unsigned)ALT_CPU_FREQ);
#endif
    printf("Lectures par lot : %u ; essais : %u\n", NB_LECTURES, NB_ESSAIS);
    puts("Essai | Methode | Ticks du lot | Ticks/lecture | ns/lecture (tronques)");
    for (essai = 1; essai <= NB_ESSAIS; ++essai) {
        int err;
        /* Alterner l'ordre pour limiter le biais lie a l'ordre des essais. */
        if (essai & 1u) {
            err = mesurer(1, &direct);
            if (!err) err = mesurer(0, &hal);
        } else {
            err = mesurer(0, &hal);
            if (!err) err = mesurer(1, &direct);
        }
        if (err) {
            puts("ERREUR timer : verifier le BSP et la plage du compteur.");
            return 1;
        }
        afficher(essai, "Direct", direct, frequence);
        afficher(essai, "HAL   ", hal, frequence);
        if (direct < min_direct) min_direct = direct;
        if (hal < min_hal) min_hal = hal;
    }
    puts("Meilleurs lots observes (cout brut, boucle et stockage inclus) :");
    afficher(0, "Direct", min_direct, frequence);
    afficher(0, "HAL   ", min_hal, frequence);
    puts("Comparer aussi la dispersion des cinq essais avant de conclure.");
    return 0;
}
