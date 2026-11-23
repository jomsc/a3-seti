#include <stdio.h>
#include "sys/alt_timestamp.h"
#include "alt_types.h"

/* Adresses reprises de ton systeme Nios II. */
volatile unsigned short * const sw =
    (volatile unsigned short *)0x82109070u;
volatile unsigned short * const ledr =
    (volatile unsigned short *)0x82109060u;

/* t1 = fin, t2 = debut. Soustraction non signee sur 32 bits. */
alt_u32 calcul_temps(alt_u32 t1, alt_u32 t2)
{
    return t1 - t2;
}

/* Algorithme du TP : A sur 64 bits, resultat sur 32 bits, sans flottants.
 * R utilise 64 bits pour contenir les intermediaires.
 */
__attribute__((noinline))
alt_u32 racine_carree(alt_u64 a)
{
    alt_u64 d = a;
    alt_u32 z = 0;
    alt_64 r = 0;
    unsigned int i;

    for (i = 0; i < 32; ++i) {
        alt_64 paire = (alt_64)(d >> 62);
        alt_64 quatre_z = (alt_64)z * 4;

        /* Premier test : signe de l'ancien reste. */
        if (r >= 0)
            r = r * 4 + paire - (quatre_z + 1);
        else
            r = r * 4 + paire + (quatre_z + 3);

        /* Second test : signe du nouveau reste. */
        z = (z << 1) | (alt_u32)(r >= 0);
        d <<= 2;
    }
    return z;
}

/* Affichage decimal sans format printf 64 bits, hors chronometrage. */
static void afficher_u64(alt_u64 valeur, unsigned int largeur)
{
    char chiffres[21];
    unsigned int n = 0;
    do {
        chiffres[n++] = (char)('0' + valeur % 10);
        valeur /= 10;
    } while (valeur != 0);
    while (largeur > n) {
        putchar(' ');
        --largeur;
    }
    while (n != 0)
        putchar(chiffres[--n]);
}

int main(void)
{
    static const struct {
        alt_u64 a;
        alt_u32 attendu;
    } essais[] = {
        {0ULL,          0u},
        {1ULL,          1u},
        {15ULL,         3u},
        {512ULL,        22u},
        {1194877489ULL, 34567u},
        {4294967295ULL, 65535u}
    };
    volatile alt_u64 a;
    volatile alt_u32 resultat;
    alt_u32 timestamp_debut, timestamp_fin, ticks, frequence;
    alt_u64 temps_ns;
    unsigned int k, echecs = 0;

    if (alt_timestamp_start() != 0) {
        puts("Erreur : aucun timer timestamp configure dans le BSP.");
        return 1;
    }
    frequence = alt_timestamp_freq();
    if (frequence == 0) {
        puts("Erreur : frequence timestamp nulle.");
        return 1;
    }

    puts("\nRACINE CARREE ENTIERE - NIOS II");
    puts("32 iterations par calcul ; aucun flottant.");
    printf("Frequence timestamp : %u Hz\n\n", (unsigned int)frequence);
    puts("           A |   Racine |  Attendu |      Debut |        Fin |      Ticks |     Temps (ns) | Etat");
    puts("-------------+----------+----------+------------+------------+------------+----------------+-------");

    for (k = 0; k < sizeof essais / sizeof essais[0]; ++k) {
        a = essais[k].a;
        /* Remettre le timer en route pour chaque mesure. */
        if (alt_timestamp_start() != 0) {
            puts("Erreur : impossible de redemarrer le timestamp.");
            return 1;
        }

        timestamp_debut = alt_timestamp();
        __asm__ __volatile__("" ::: "memory");
        resultat = racine_carree(a);
        __asm__ __volatile__("" ::: "memory");
        timestamp_fin = alt_timestamp();

        if (timestamp_fin < timestamp_debut || timestamp_fin == (alt_u32)-1) {
            puts("Erreur : compteur epuise, mesure invalide.");
            return 1;
        }
        ticks = calcul_temps(timestamp_fin, timestamp_debut);
        temps_ns = ((alt_u64)ticks * 1000000000ULL) / frequence;
        if (resultat != essais[k].attendu)
            ++echecs;

        /* Conversion et affichage hors de la zone chronometree.
         * Aucun format printf 64 bits n'est utilise.
         */
        afficher_u64(essais[k].a, 12); printf(" | ");
        afficher_u64(resultat, 8); printf(" | ");
        afficher_u64(essais[k].attendu, 8); printf(" | ");
        afficher_u64(timestamp_debut, 10); printf(" | ");
        afficher_u64(timestamp_fin, 10); printf(" | ");
        afficher_u64(ticks, 10); printf(" | ");
        afficher_u64(temps_ns, 14); printf(" | ");
        puts(resultat == essais[k].attendu ? "OK" : "ERREUR");
    }

    printf("\nBilan : %u/6 calculs corrects.\n", 6u - echecs);
    puts("Debut et Fin sont exprimes en ticks du timer.");
    puts("Tests termines. Les LED suivent maintenant les switches.");

    /* Pas d'affichage repetitif : le tableau reste lisible. */
    while (1) {
        *ledr = *sw;
    }
}
