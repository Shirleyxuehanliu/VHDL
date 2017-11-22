LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use work.processor_pkg.all;

ENTITY E IS
END E;
 
ARCHITECTURE TB OF E IS

component top
    port(  clk,resetn : in Std_logic  );
end component;

signal clk,resetn : std_logic;  
begin
 uut : top port map (clk,resetn);

    clock_engine : process
    begin
      clk <= '0';
      wait for 10 ns;
      clk <= '1';
      wait for 10 ns;
    end process;

    reset_engine : process
      begin
        resetn <='0';
        wait for 50 ns;
        resetn <= '1';
        wait;
    end process;
    
end TB;


