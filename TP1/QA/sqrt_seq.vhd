library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sqrt_seq is 

    generic ( n : natural := 32 );

    port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        start  : in  std_logic;

        A      : in  std_logic_vector(2*n-1 downto 0);

        Result : out std_logic_vector(n-1 downto 0);

        done   : out std_logic
    );

end entity sqrt_seq;


architecture sqrt_seq_proc of sqrt_seq is

    signal D : unsigned(2*n-1 downto 0);

    signal Z : unsigned(n-1 downto 0);

    signal i : integer range 0 to n-1;

    type state is (wait_state, init_state, comp_state, end_state);
    signal curr_state : state; 

begin

    Result <= std_logic_vector(Z);

    PCalc : process(clk, rst) is 

        variable R : signed(n+1 downto 0);

    begin 

        if rst = '1' then

            curr_state <= wait_state;

        elsif clk'event and clk = '1' then

            case curr_state is

                when wait_state =>

                    done <= '0';

                    R := to_signed(0, n+2);

                    D <= to_unsigned(0, 2*n);
                    Z <= to_unsigned(0, n);

                    i <= 0;

                    if start = '1' then
                        curr_state <= init_state;
                    else 
                        curr_state <= wait_state;
                    end if;

                when init_state =>

                    done <= '0';

                    R := to_signed(0, n+2);

                    D <= unsigned(A);
                    Z <= to_unsigned(0, n);

                    i <= 0;

                    curr_state <= comp_state;

                when comp_state =>

                    done <= '0';

                    if R >= 0 then

                        R := (R sll 2) + signed( resize( D(2*n-1 downto 2*n-2), R'length ) ) - signed(resize(Z, R'length) sll 2) - to_signed(1, R'length);

                    else

                        R := (R sll 2) + signed( resize( D(2*n-1 downto 2*n-2), R'length ) ) + signed(resize(Z, R'length) sll 2) + to_signed(3, R'length);

                    end if;

                    if R >= 0 then

                        Z <= (Z sll 1) + to_unsigned(1, n);

                    else

                        Z <= Z sll 1;

                    end if;

                    D <= D sll 2;

                    if i = n-1 then

                        i <= 0;

                        curr_state <= end_state;

                    else

                        i <= i + 1;

                        curr_state <= comp_state;

                    end if;

                when end_state =>

                    done <= '1';

                    if start = '1' then
                        curr_state <= end_state;
                    else 
                        curr_state <= wait_state;
                    end if;

                when others =>

                    done <= '0';

                    R := to_signed(0, n+2);

                    D <= to_unsigned(0, 2*n);
                    Z <= to_unsigned(0, n);

                    i <= 0;

                    curr_state <= wait_state;

            end case;

        end if;

    end process PCalc;

end architecture sqrt_seq_proc;