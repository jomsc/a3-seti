library ieee;
use ieee.std_logic_1164.all;

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

    rc0_int <= not r_q(W-1);
    rc1_int <= not r_next(W-1);
    RC0 <= rc0_int;
    RC1 <= rc1_int;
    S <= z_q;

    r_shift <= r_q(W-3 downto 0) & "00";
    paire(W-1 downto 2) <= (others => '0');
    paire(1 downto 0) <= d_q(2*n-1 downto 2*n-2);

    op_a <= r_shift or paire;

    quatre_z <= z_q & "00";
    plus_z <= z_q & "11";

    moins_z <= not quatre_z;

    MUX2 : entity work.mux2_1(proced)
        generic map (nb_bits => W)
        port map (I0 => plus_z, I1 => moins_z, sel => rc0_int, S => op_b);

    ADD : entity work.additionneur(dataflow)
        generic map (nb_bits => W)
        port map (A => op_a, B => op_b, S => r_next);

    MUX1 : entity work.mux2_1(proced)
        generic map (nb_bits => 1)
        port map (I0 => "0", I1 => "1", sel => rc1_int, S => bit_z);

    Z_UN_BIT : if n = 1 generate
        z_next(0) <= bit_z(0);
    end generate;
    Z_PLUSIEURS_BITS : if n > 1 generate
        z_next <= z_q(n-2 downto 0) & bit_z(0);
    end generate;

    D_UNE_PAIRE : if n = 1 generate
        d_shift <= "00";
    end generate;
    D_PLUSIEURS_PAIRES : if n > 1 generate
        d_shift <= d_q(2*n-3 downto 0) & "00";
    end generate;
    MUX_D : entity work.mux2_1(proced)
        generic map (nb_bits => 2*n)
        port map (I0 => d_shift, I1 => A, sel => init, S => d_next);
    ld_d <= init or calcul;

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
