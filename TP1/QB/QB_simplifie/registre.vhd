library ieee;
use ieee.std_logic_1164.all;

entity registre is
    generic (nb_bits : positive := 32);
    port (clk, reset, raz, ld : in std_logic;
          din : in std_logic_vector(nb_bits-1 downto 0);
          q : out std_logic_vector(nb_bits-1 downto 0));
end entity;

architecture proced of registre is
begin
    P1 : process(clk, reset)
    begin
        if reset = '1' then
            q <= (others => '0');
        elsif rising_edge(clk) then
            if raz = '1' then
                q <= (others => '0');
            elsif ld = '1' then
                q <= din;
            end if;
        end if;
    end process;
end architecture;
