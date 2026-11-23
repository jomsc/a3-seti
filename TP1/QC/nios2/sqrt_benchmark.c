#include <stdint.h>
#include <inttypes.h>
#include <stdio.h>
#ifndef SQRT_CORE_ONLY
#include "sys/alt_timestamp.h"
#endif

/* Meme recurrence que le VHDL, n=32 : A sur 64 bits, resultat sur 32 bits.
 * R*4 evite le decalage d'un entier signe negatif, indefini en C.
 * Les intermediaires tiennent dans int64_t pour cette entree 64 bits.
 */
__attribute__((noinline))
uint32_t sqrt_entier(uint64_t a)
{
    uint64_t d = a;
    uint32_t z = 0;
    int64_t r = 0;
    unsigned i;

    for (i = 0; i < 32; ++i) {
        int64_t paire = (int64_t)(d >> 62);
        int64_t quatre_z = (int64_t)z * 4;

        if (r >= 0)
            r = r * 4 + paire - (quatre_z + 1);
        else
            r = r * 4 + paire + (quatre_z + 3);

        z = (z << 1) | (uint32_t)(r >= 0);
        d <<= 2;
    }
    return z;
}

#ifndef SQRT_CORE_ONLY
/* GCC : empecher le deplacement des acces memoire autour de la mesure. */
#define BARRIERE() __asm__ __volatile__("" ::: "memory")

int main(void)
{
    static const struct {
        uint64_t a;
        uint32_t attendu;
    } essais[] = {
        {UINT64_C(0),                   UINT32_C(0)},
        {UINT64_C(15),                  UINT32_C(3)},
        {UINT64_C(100),                 UINT32_C(10)},
        {UINT64_C(1194877489),          UINT32_C(34567)},
        {UINT64_C(4294967296),          UINT32_C(65536)},
        {UINT64_C(18446744073709551615), UINT32_C(4294967295)}
    };
    volatile uint64_t entree;
    volatile uint32_t resultat;
    alt_u32 frequence, debut, fin, ticks;
    unsigned k;
    int echecs = 0;

    if (alt_timestamp_start() != 0) {
        puts("Erreur : configurer hal.timestamp_timer dans le BSP.");
        return 1;
    }
    frequence = alt_timestamp_freq();
    if (frequence == 0) {
        puts("Erreur : frequence du timestamp nulle.");
        return 1;
    }
    printf("Timestamp : %" PRIu32 " ticks/s ; 32 iterations par calcul\n",
           (uint32_t)frequence);

    /* Cout indicatif de deux lectures, affiche sans le soustraire. */
    debut = alt_timestamp();
    BARRIERE();
    fin = alt_timestamp();
    printf("Intervalle a vide : %" PRIu32 " ticks\n",
           (uint32_t)(fin - debut));

    for (k = 0; k < sizeof essais / sizeof essais[0]; ++k) {
        uint64_t ns;
        uint32_t obtenu;
        entree = essais[k].a;
        if (alt_timestamp_start() != 0)
            return 1;

        debut = alt_timestamp();
        BARRIERE();
        resultat = sqrt_entier(entree);
        BARRIERE();
        fin = alt_timestamp();

        /* Une mesure doit finir avant la saturation du timer 32 bits. */
        if (fin < debut || fin == UINT32_MAX) {
            puts("Erreur : compteur epuise ; mesure invalide.");
            return 1;
        }
        ticks = fin - debut;
        ns = ((uint64_t)ticks * UINT64_C(1000000000)) / frequence;
        obtenu = resultat;
        if (obtenu != essais[k].attendu)
            ++echecs;

        /* UART et conversion en temps restent hors de la mesure. */
        printf("A=%" PRIu64 " ; racine=%" PRIu32
               " ; %s ; ticks=%" PRIu32 " ; temps=%" PRIu64 " ns\n",
               essais[k].a, obtenu,
               obtenu == essais[k].attendu ? "OK" : "ERREUR",
               (uint32_t)ticks, ns);
    }
    return echecs != 0;
}
#endif
