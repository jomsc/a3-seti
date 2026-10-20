-- Unique additionneur du chemin de donnees, comme le bloc adder du cours.
-- Addition sur nb_bits bits, modulo 2**nb_bits ; voir LIRE_MOI.md.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity additionneur is
    generic (nb_bits : positive := 34);
    port (A, B : in std_logic_vector(nb_bits-1 downto 0);
          S : out std_logic_vector(nb_bits-1 downto 0));
end entity;

architecture dataflow of additionneur is
begin
    S <= std_logic_vector(unsigned(A) + unsigned(B));
end architecture;
