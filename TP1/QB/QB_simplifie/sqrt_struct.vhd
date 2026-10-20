library ieee;
use ieee.std_logic_1164.all;

entity sqrt_struct is
    generic (n : positive := 32);
    port (clk, reset, start : in std_logic;
          A : in std_logic_vector(2*n-1 downto 0);
          S : out std_logic_vector(n-1 downto 0);
          done : out std_logic);
end entity;

architecture seq_det of sqrt_struct is
    signal sig_init, sig_calcul : std_logic;
    signal sig_RC0, sig_RC1 : std_logic;
begin
    CU : entity work.unite_controle(proced)
        generic map (n => n)
        port map (clk => clk, reset => reset, start => start,
                  init => sig_init, calcul => sig_calcul, done => done);

    DP : entity work.chemin_donnees(structurelle)
        generic map (n => n)
        port map (clk => clk, reset => reset, init => sig_init,
                  calcul => sig_calcul, A => A, S => S,
                  RC0 => sig_RC0, RC1 => sig_RC1);
end architecture;
