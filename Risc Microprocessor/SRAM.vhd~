-------------------------------------------------------------------------------
-- Memory.vhd
-------------------------------------------------------------------------------
--
-- Simple non-synthesizable SRAM memory template
-- fcampi@sfu.ca Oct 2013

library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;


entity SRAM is
  generic ( addr_size : integer := 8;
            word_size : integer := 16 );
  port (  clk	    : 	in  std_logic;
          rdn	    :	in  std_logic;
          wrn	    :	in  std_logic;
          address   :	in  std_logic_vector(addr_size-1 downto 0);
          bit_wen   :   in  std_logic_vector(word_size-1 downto 0);
          data_in   :	in  std_logic_vector(word_size-1 downto 0);
          data_out  :	out std_logic_vector(word_size-1 downto 0) );
end SRAM;

architecture behv of SRAM is			
  
  type ram_type is array (0 to 2**addr_size-1) of std_logic_vector(word_size-1 downto 0);
  signal ram_array : ram_type;
  signal addr_clk : std_logic_vector(addr_size-1 downto 0);
  begin
    
    process(clk)
    begin 
      if clk'event and clk='1' then 
        if rdn='0' then 
          addr_clk <= address;
        end if; 
        -- Data Write 
        if wrn='0' then 
          for i in 0 to word_size-1 loop
            if bit_wen(i)='0' then
              ram_array(Conv_Integer(unsigned(address)))(i) <= data_in(i);
            end if;            
          end loop;
        end if;
      end if;
    end process;
        
    -- Data Read
    data_out <= ram_array(Conv_Integer(unsigned(addr_clk)));

end behv;
