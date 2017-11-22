-------------------------------------------------------------------------------
-- counter
-- by fcampi@sfu.ca Feb 2014
--
-------------------------------------------------------------------------------

-- Device implementing a counter for performance estimation
-- It is designed to lie on the external bus, and can support
-- a programmable number of counters from 1 to 16.
-- The operation to be computed is expressed by the address bus
-- So, the last 4 bit of the addressed counter (0000 to 1111) are used to
-- specify the addressed counter, and are expressed as X in the following,
-- while bits 7 to 4 specify the desired operation according to the following 
-- instruction set:
-- 
-- Instruction Set: The counter is programmed by store words (Address Bits 7-4 specify the desired action, Address Bits 3-0 the target counter)
-- Reset Counter            0x1X (Can Preload any value using data_in; Note, reset does not start the counter)
-- Enable Counter onward    0x2X
-- Enable Counter backwards 0x3X 
-- Stop  Counter            0x4X

-- Read  Counter            The counter is read by any load word (bits 7 to 4 are irrelevant, bits 3-0 specify the target counter)

library IEEE;
  use std.textio.all;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  
entity counter is
  generic ( data_size : integer := 16;num_counters : integer range 1 to 16 := 4; signal_active : std_logic := '0');
  port (  clk,resetn :   in  std_logic; 
          rdn,wrn    :   in  std_logic;
          address    :   in  std_logic_vector(7 downto 0);
          data_in    :   in  std_logic_vector(data_size-1 downto 0);
          data_out   :   out std_logic_vector(data_size-1 downto 0) );
end counter;

architecture beh of counter is

type ccount_array is array (0 to num_counters-1) of std_logic_vector(data_size-1 downto 0);  
type cstate_type is (idle, count_up, count_down);
type cstate_array is array (0 to num_counters-1) of cstate_type;
type creset_array is array (0 to num_counters-1) of std_logic;

signal count,next_count   : ccount_array;
signal cstate,next_cstate : cstate_array;
signal creset : creset_array;
signal read_addr : std_logic_vector(3 downto 0);
begin  -- beh

  -- Input detection Logic
  process(address,wrn,cstate)
  variable sel : integer;
  begin

    sel := to_integer(unsigned(address(3 downto 0)));
       
    for i in 0 to num_counters-1 loop
      next_cstate(i) <= cstate(i);
      creset(i) <= '0';
    end loop;  -- i
    
    if wrn=signal_active then
		case address(7 downto 4) is      
			when x"1" =>
				-- reset counter
				creset(sel) <= '1';
			when x"2" =>
				-- enable counter
				next_cstate(sel) <= count_up;
			when x"3" => 
				-- enable count downto
				next_cstate(sel) <= count_down;
			when x"4" =>
				-- stop counter
				next_cstate(sel) <= idle;
			when others => null;
		end case;
	end if;
  end process;

  increments: for i in 0 to num_counters-1 generate
    next_count(i) <= 
      data_in  when creset(i)='1'  else
      count(i) when (cstate(i)=count_down and unsigned(count(i))=to_unsigned(0,data_size) ) else 
      std_logic_vector(unsigned(count(i))+to_unsigned(1,data_size)) when cstate(i)=count_up else
	  std_logic_vector(unsigned(count(i))-to_unsigned(1,data_size)) when cstate(i)=count_down else
	  count(i); -- This last case cover also the idle state
  end generate;  -- i
    
  counters: for i in 0 to num_counters-1 generate
   CounterN: process(clk)
   begin
     if clk'event and clk='1' then
       if resetn='0' then
         count(i)   <= (others=>'0');
         cstate(i)  <= idle;
       else
         cstate(i) <= next_cstate(i);
         count(i) <= next_count(i);
       end if;
     end if;
   end process;
  end generate;  -- i
  
  process(clk)
  begin
    if clk'event and clk='1' then
      if resetn='0' then
        read_addr  <= (others=>'0');
      else
        if rdn=signal_active then 
          read_addr  <= address(3 downto 0); 
        end if;
      end if;
    end if;
  end process;
		
  data_out <= count(to_integer(unsigned(read_addr)));
end beh;
