-- Banc de test simple et autonome : aucun fichier de vecteurs a charger.
-- La question B demande une simulation avec n=32 (A sur 64 bits).
-- Les wait et les delais sont reserves a la simulation, pas au circuit.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sqrt_struct is
end entity;

architecture test of tb_sqrt_struct is
    constant n : positive := 32;
    signal clk, reset, start : std_logic := '0';
    signal A : std_logic_vector(2*n-1 downto 0) := (others => '0');
    signal S : std_logic_vector(n-1 downto 0);
    signal done : std_logic;
    signal termine : boolean := false;
begin
    DUT : entity work.sqrt_struct(seq_det)
        generic map (n => n)
        port map (clk => clk, reset => reset, start => start,
                  A => A, S => S, done => done);

    horloge : process
    begin
        while not termine loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
        wait;
    end process;

    stimulus : process
        -- Observer les valeurs APRES la mise a jour des registres et de done.
        procedure tick is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;

        procedure verifier(valeur : std_logic_vector(63 downto 0);
                           attendu : std_logic_vector(31 downto 0);
                           maintenir_start : boolean := false) is
        begin
            A <= valeur; start <= '1';
            tick; -- F0 : start accepte, entree dans init_state.
            assert done = '0' report "done pendant init" severity failure;
            if not maintenir_start then start <= '0'; end if;
            tick; -- F1 : capture A, R=Z=0, entree dans comp_state.
            assert done = '0' and unsigned(S) = 0
                report "Initialisation incorrecte" severity failure;
            A <= not valeur; -- Apres capture, A ne doit plus intervenir.
            for k in 1 to n loop
                tick; -- Une iteration COMPLETE au front courant.
                if k < n then
                    assert done = '0' report "Fin prematuree" severity failure;
                else
                    assert done = '1' report "Fin en retard" severity failure;
                end if;
            end loop;
            assert S = attendu report "Racine incorrecte" severity failure;
            if maintenir_start then
                tick;
                assert done = '1' and S = attendu
                    report "Resultat non conserve" severity failure;
                start <= '0';
            end if;
            tick; -- Retour en attente ; done retombe.
            assert done = '0' and S = attendu
                report "Retour en attente incorrect" severity failure;
        end procedure;
    begin
        reset <= '1'; wait for 2 ns;
        assert unsigned(S) = 0 and done = '0'
            report "Reset incorrect" severity failure;
        reset <= '0'; tick;

        -- Petits nombres, carres parfaits et leurs voisins.
        verifier(x"0000000000000000", x"00000000"); -- 0 -> 0
        verifier(x"0000000000000001", x"00000001"); -- 1 -> 1
        verifier(x"0000000000000002", x"00000001"); -- 2 -> 1
        verifier(x"0000000000000003", x"00000001"); -- 3 -> 1
        verifier(x"0000000000000004", x"00000002"); -- 4 -> 2
        verifier(x"0000000000000009", x"00000003"); -- 9 -> 3
        verifier(x"000000000000000F", x"00000003"); -- 15 -> 3
        verifier(x"0000000000000010", x"00000004"); -- 16 -> 4
        verifier(x"0000000000000011", x"00000004"); -- 17 -> 4
        verifier(x"0000000000000064", x"0000000A"); -- 100 -> 10

        -- Valeurs qui depassent un entier signe classique sur 32 bits.
        verifier(x"00000000FFFFFFFF", x"0000FFFF");
        verifier(x"0000000100000000", x"00010000");
        verifier(x"FFFFFFFE00000000", x"FFFFFFFE");
        verifier(x"FFFFFFFE00000001", x"FFFFFFFF");
        verifier(x"FFFFFFFE00000002", x"FFFFFFFF");
        verifier(x"FFFFFFFFFFFFFFFF", x"FFFFFFFF", true);

        -- Interrompre une operation apres quelques iterations.
        A <= (others => '1'); start <= '1'; tick;
        start <= '0'; tick;
        for k in 1 to 3 loop tick; end loop;
        reset <= '1'; wait for 1 ns;
        assert done = '0' and unsigned(S) = 0
            report "Reset pendant le calcul incorrect" severity failure;
        reset <= '0';
        for k in 1 to n+1 loop
            tick;
            assert done = '0' report "Calcul annule encore actif" severity failure;
        end loop;
        verifier(x"0000000000000010", x"00000004"); -- Redemarrage.

        report "PASS : 17 calculs, 32 iterations par calcul, reset et start/done";
        termine <= true;
        wait;
    end process;
end architecture;
