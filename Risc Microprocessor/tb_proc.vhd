LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use work.processor_pkg.all;

ENTITY E IS
END E;
 
ARCHITECTURE TB OF E IS

  component PROCESSOR
    port(  clk,resetn : in Std_logic;
       iaddr_out  : out Std_logic_vector(iaddr_size-1 downto 0); -- address obtained from instruction?
       idata_in   : in Std_logic_vector(instr_size-1 downto 0); -- input instruction?
       daddr_out  : out Std_logic_vector(daddr_size-1 downto 0); -- data obtained from instruction?
       dmem_read, dmem_write : out std_logic;
       ddata_in   : in Std_logic_vector(data_size-1 downto 0);
       ddata_out  : out Std_logic_vector(data_size-1 downto 0)  );
  end component;

signal clk,resetn,dmem_write,dmem_read : std_logic;
signal iaddr_out : Std_logic_vector(iaddr_size-1 downto 0);
signal daddr_out : Std_logic_vector(daddr_size-1 downto 0);
signal idata_in  : std_logic_vector(instr_size-1 downto 0);
signal ddata_out,ddata_in : std_logic_vector(data_size-1 downto 0);
  
begin 
 uut : processor port map ( clk,resetn,iaddr_out,idata_in,daddr_out,dmem_read,dmem_write,ddata_in,ddata_out );

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
        wait for 20 ns;
        resetn <= '1';
        wait;
    end process;

   -- Non realistic data, just to check the math
    input_data : process
      begin
        idata_in <= x"10100abc";
        wait for 45 ns;
        idata_in <= x"10200001";
        wait for 20 ns;
        idata_in <= x"00312000";
        wait for 20 ns;       
        wait;
    end process;
    
end TB;

