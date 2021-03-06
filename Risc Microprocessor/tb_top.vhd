LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use work.processor_pkg.all;

ENTITY E IS
END E;
 
ARCHITECTURE TB OF E IS

component top
    port(  clk,resetn : in Std_logic;

    -- Slave port to control the subsystem from outside to the testbench
    EXT_BUSY, S1_MR, S1_MW  : out  Std_logic;
    EXT_NREADY              : in   Std_logic;
    EXT_ADDRBUS             : out  Std_logic_vector(daddr_size-1 downto 0);
    EXT_RDATABUS            : in   Std_logic_vector(data_size-1 downto 0);
    EXT_WDATABUS            : out  Std_logic_vector(data_size-1 downto 0));
end component;

signal clk,resetn : std_logic;
signal EXT_BUSY, S1_MR, S1_MW  : Std_logic;
signal EXT_NREADY              : Std_logic;
signal EXT_ADDRBUS             : Std_logic_vector(daddr_size-1 downto 0);
signal EXT_RDATABUS            : Std_logic_vector(data_size-1 downto 0);
signal EXT_WDATABUS            : Std_logic_vector(data_size-1 downto 0);

begin
    EXT_NREADY   <= '0';
    EXT_RDATABUS <= x"00000000";

    uut : top port map (clk,resetn,EXT_BUSY, S1_MR, S1_MW,EXT_NREADY,EXT_ADDRBUS,EXT_RDATABUS,EXT_WDATABUS);

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


