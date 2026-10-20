library ieee;
use ieee.std_logic_1164.all;

entity unite_controle is
    generic (n : positive := 32);
    port (clk, reset, start : in std_logic;
          init, calcul, done : out std_logic);
end entity;

architecture proced of unite_controle is
    type state is (wait_state, init_state, comp_state, end_state);
    signal current_state, next_state : state;
    signal i : natural range 0 to n-1;
begin
    CSM : process(clk, reset)
    begin
        if reset = '1' then
            current_state <= wait_state;
            i <= 0;
        elsif rising_edge(clk) then
            current_state <= next_state;
            if current_state = init_state then
                i <= n-1;
            elsif current_state = comp_state then

                if i > 0 then
                    i <= i-1;
                end if;
            end if;
        end if;
    end process;

    NSC : process(current_state, start, i)
    begin
        next_state <= current_state;
        case current_state is
            when wait_state =>
                if start = '1' then next_state <= init_state; end if;
            when init_state =>
                next_state <= comp_state;
            when comp_state =>
                if i = 0 then next_state <= end_state; end if;
            when end_state =>
                if start = '0' then next_state <= wait_state; end if;
        end case;
    end process;

    OC : process(current_state)
    begin

        init <= '0';
        calcul <= '0';
        done <= '0';
        case current_state is
            when wait_state => null;
            when init_state => init <= '1';
            when comp_state => calcul <= '1';
            when end_state => done <= '1';
        end case;
    end process;
end architecture;
