library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
end entity testbench;

architecture test_sqrt_seq of testbench is

    constant nb_bits : natural := 32;

    signal sig_A : std_logic_vector(2*nb_bits-1 downto 0);

    signal sig_Result : std_logic_vector(nb_bits-1 downto 0);

    signal sig_clk   : std_logic;
    signal sig_rst   : std_logic;
    signal sig_start : std_logic;
    signal sig_done  : std_logic;

begin

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

    sig_rst <= '1',
               '0' after 5 ns;

    sig_A <= std_logic_vector(to_unsigned(100, 2*nb_bits)),
             std_logic_vector(to_unsigned(25,  2*nb_bits)) after 785 ns;

    sig_start <= '0',
                 '1' after 25 ns,
                 '0' after 765 ns,
                 '1' after 805 ns,
                 '0' after 1545 ns;

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