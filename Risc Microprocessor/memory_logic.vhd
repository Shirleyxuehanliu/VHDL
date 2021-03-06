-------------------------------------------------------------------------------
-- SW R1, R2, 0x8   -> R1=S , R2-> RB, 0x8 offset

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.processor_pkg.all;

entity memory_logic is
  port (S,RB,offset : in Std_logic_vector(data_size-1 downto 0);  -- source (from register file), register base, offset (think of it as register(offset))
        memop       : in mem_op;
        wb_data     : out Std_logic_vector(data_size-1 downto 0);
        -- below are signals from the memory (all the above comes from the processor)
        mr,mw       : out Std_logic;
        address     : out Std_logic_vector(daddr_size-1 downto 0);
        wdata       : out Std_logic_vector(data_size-1 downto 0);
        rdata       : in  Std_logic_vector(data_size-1 downto 0) );
end memory_logic;

architecture beh of memory_logic is

  signal internal : std_logic_vector(data_size-1 downto 0);

begin  -- beh

  internal <= Std_logic_vector(unsigned(RB) + unsigned(offset)) when memop = mem_sw or memop = mem_lw else (others=>'0');
  address <= internal(daddr_size-1 downto 0);

  mr <= '1' when memop=mem_lw else '0';
  mw <= '1' when memop=mem_sw else '0';

  wdata <= S when memop=mem_sw else (others=>'0');  -- store the data from register file to SRAM memory
  wb_data <= rdata;

end beh;
