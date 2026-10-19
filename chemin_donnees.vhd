-- Question 1.b : traduction structurelle de chemin_donnees.drawio.
-- RC0 = signe de l'ANCIEN R ; RC1 = signe du NOUVEAU R.
-- Convention : RC0/RC1 valent 1 si le nombre correspondant est >= 0.
-- Les blocs de comparaison ne transportent pas le bus : ils prelevent
-- seulement son bit de signe. Les bus R et somme suivent leurs propres fils.
--
-- Pour n=32 : D=64 bits, Z=32 bits, R et additionneur=34 bits.
-- R tient sur n+2 bits : apres k iterations, -(2Z+1) <= R <= 2Z,
-- avec 0 <= Z <= 2**k-1. Voir la preuve et le calcul modulo dans le guide.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity chemin_donnees is
    generic (n : positive := 32);
    port (clk, reset : in std_logic;
          init, calcul : in std_logic;
          A : in std_logic_vector(2*n-1 downto 0);
          S : out std_logic_vector(n-1 downto 0);
          RC0, RC1 : out std_logic);
end entity;

architecture structurelle of chemin_donnees is
    constant W : positive := n+2;
    signal d_q, d_next, d_shift : std_logic_vector(2*n-1 downto 0);
    signal z_q, z_next : std_logic_vector(n-1 downto 0);
    signal r_q, r_next : std_logic_vector(W-1 downto 0);
    signal r_shift, paire, op_a, op_b : std_logic_vector(W-1 downto 0);
    signal quatre_z, plus_z, moins_z : std_logic_vector(W-1 downto 0);
    signal rc0_int, rc1_int, ld_d : std_logic;
    signal bit_z : std_logic_vector(0 downto 0);
begin
    -- Deux tests de signe, sans comparateurs arithmetiques supplementaires.
    rc0_int <= not r_q(W-1);
    rc1_int <= not r_next(W-1);
    RC0 <= rc0_int;
    RC1 <= rc1_int;
    S <= z_q;

    -- Branche gauche du dessin : 4R + paire.
    -- Decaler R de DEUX bits, et non d'un, pour multiplier par 4.
    -- La paire est la division entiere D / 2**(2*n-2).
    -- Aucun diviseur : on prend simplement les deux bits superieurs.
    r_shift <= std_logic_vector(shift_left(unsigned(r_q), 2));
    paire <= std_logic_vector(resize(unsigned(d_q(2*n-1 downto 2*n-2)), W));
    -- Les deux bits bas de r_shift sont nuls ; les autres bits de paire
    -- sont nuls. Les zones ne se recouvrent pas : OR equivaut ici a +.
    op_a <= r_shift or paire;

    -- Branche Z du dessin : & est une CONCATENATION, pas un AND logique.
    -- Z & "00" = 4Z ; Z & "11" = 4Z+3 : aucun additionneur necessaire.
    quatre_z <= z_q & "00";
    plus_z <= z_q & "11";
    -- Identite en complement a deux : NOT(x) = -x-1 (modulo 2**W).
    -- Donc NOT(4Z) = -(4Z+1). Ne PAS inverser (4Z+1) : ce serait -4Z-2.
    moins_z <= not quatre_z;

    MUX2 : entity work.mux2_1(proced)
        generic map (nb_bits => W)
        port map (I0 => plus_z, I1 => moins_z, sel => rc0_int, S => op_b);

    ADD : entity work.additionneur(dataflow)
        generic map (nb_bits => W)
        port map (A => op_a, B => op_b, S => r_next);

    -- Branche basse du dessin : selection du nouveau bit de la racine.
    -- RC1 provient de la SOMME, donc du NOUVEAU R, et non du registre R.
    MUX1 : entity work.mux2_1(proced)
        generic map (nb_bits => 1)
        port map (I0 => "0", I1 => "1", sel => rc1_int, S => bit_z);

    -- Equivalent a Z_next = 2Z + bit_z, sans additionneur.
    -- Le generate traite explicitement n=1 pour eviter une tranche negative.
    Z_UN_BIT : if n = 1 generate
        z_next(0) <= bit_z(0);
    end generate;
    Z_PLUSIEURS_BITS : if n > 1 generate
        z_next <= z_q(n-2 downto 0) & bit_z(0);
    end generate;

    -- D avance de DEUX bits par iteration, modulo 2**(2*n).
    -- Les bits elimines sont justement la paire deja consommee.
    d_shift <= std_logic_vector(shift_left(unsigned(d_q), 2));
    MUX_D : entity work.mux2_1(proced)
        generic map (nb_bits => 2*n)
        port map (I0 => d_shift, I1 => A, sel => init, S => d_next);
    ld_d <= init or calcul;

    -- Init capture A et remet R/Z a zero. Calcul memorise les trois valeurs
    -- nouvelles AU MEME FRONT. Sinon les registres conservent leur valeur.
    REG_D : entity work.registre(proced)
        generic map (nb_bits => 2*n)
        port map (clk => clk, reset => reset, raz => '0', ld => ld_d,
                  din => d_next, q => d_q);
    REG_R : entity work.registre(proced)
        generic map (nb_bits => W)
        port map (clk => clk, reset => reset, raz => init, ld => calcul,
                  din => r_next, q => r_q);
    REG_Z : entity work.registre(proced)
        generic map (nb_bits => n)
        port map (clk => clk, reset => reset, raz => init, ld => calcul,
                  din => z_next, q => z_q);
end architecture;
