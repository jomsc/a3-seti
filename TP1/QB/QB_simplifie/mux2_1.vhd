-- Multiplexeur combinatoire du cours : sel=0 choisit I0, sel=1 choisit I1.
-- Aucun front d horloge necessaire pour selectionner une entree.
library ieee;
use ieee.std_logic_1164.all;

entity mux2_1 is
    generic (nb_bits : positive := 1);
    port (I0, I1 : in std_logic_vector(nb_bits-1 downto 0);
          sel : in std_logic;
          S : out std_logic_vector(nb_bits-1 downto 0));
end entity;

architecture proced of mux2_1 is
begin
    P1 : process(I0, I1, sel)
    begin
        if sel = '0' then
            S <= I0;
        else
            S <= I1;
        end if;
    end process;
end architecture;
