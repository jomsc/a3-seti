library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
end entity testbench;


architecture test_sqrt_seq of testbench is

    -- Même principe que nb_bits dans le cours
    constant nb_bits : natural := 32;

    -- A est sur 2*n bits
    signal sig_A : std_logic_vector(2*nb_bits-1 downto 0);

    -- Result est sur n bits
    signal sig_Result : std_logic_vector(nb_bits-1 downto 0);

    -- Signaux de contrôle
    signal sig_clk   : std_logic;
    signal sig_rst   : std_logic;
    signal sig_start : std_logic;
    signal sig_done  : std_logic;

begin


    ------------------------------------------------------------
    -- Instanciation du circuit à tester
    ------------------------------------------------------------

    DUT : entity work.sqrt_seq(sqrt_seq_proc)

        generic map (
            n => nb_bits
        )

        port map (
            clk    => sig_clk,
            rst    => sig_rst,
            start  => sig_start,
            A      => sig_A,
            Result => sig_Result,
            done   => sig_done
        );


    ------------------------------------------------------------
    -- RESET
    ------------------------------------------------------------

    -- Reset actif au début pendant 5 ns
    sig_rst <= '1',
               '0' after 5 ns;


    ------------------------------------------------------------
    -- VALEURS DE A À TESTER
    ------------------------------------------------------------

    -- Premier calcul :
    -- sqrt(100) = 10

    -- Deuxième calcul à partir de 785 ns :
    -- sqrt(25) = 5

    sig_A <= std_logic_vector(to_unsigned(100, 2*nb_bits)),
             std_logic_vector(to_unsigned(25,  2*nb_bits)) after 785 ns;


    ------------------------------------------------------------
    -- SIGNAL START
    ------------------------------------------------------------

    -- Premier calcul lancé à 25 ns.
    --
    -- On maintient start à 1 pendant le calcul.
    -- Lorsqu'il redescend à 0, le circuit peut retourner
    -- dans wait_state.
    --
    -- Puis on relance un deuxième calcul.

    sig_start <= '0',
                 '1' after 25 ns,
                 '0' after 765 ns,
                 '1' after 805 ns,
                 '0' after 1545 ns;


    ------------------------------------------------------------
    -- GÉNÉRATION DE L'HORLOGE
    ------------------------------------------------------------

    Pclk : process

        constant nb_periods : natural := 100;

    begin

        sig_clk <= '0';

        wait for 10 ns;

        for i in 1 to nb_periods loop

            sig_clk <= '1';
            wait for 10 ns;

            sig_clk <= '0';
            wait for 10 ns;

        end loop;

        wait;

    end process Pclk;


end architecture test_sqrt_seq;