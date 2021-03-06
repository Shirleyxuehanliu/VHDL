library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.processor_pkg.all;

entity program_counter is
    port ( clk, resetn : in Std_logic;
           R1 : in STD_LOGIC_VECTOR (data_size-1 downto 0);
	   R2 : in STD_LOGIC_VECTOR (data_size-1 downto 0);
           immediate : in STD_LOGIC_VECTOR (data_size-1 downto 0);
           Op : in  pc_op;
           output_PC : out  STD_LOGIC_VECTOR (iaddr_size-1 downto 0)    );
end program_counter;

architecture Behavioral of program_counter is
  signal input_pc, temp_pc : std_logic_vector(iaddr_size-1 downto 0);
begin

  Program_Counter: process(clk,resetn)
  begin
    if resetn='0' then
      input_pc <= (others=>'0');
    elsif clk'event and clk='1' then
      input_pc <= temp_PC;
    end if;
  end process;
  
 temp_PC <= input_PC + 1              when Op = pc_cont else      -- increment
             R1(iaddr_size-1 downto 0) when Op = pc_jump else      -- jump
	     (input_PC + immediate(iaddr_size-1 downto 0))    when Op = pc_beq  and (R1 = R2) else  -- branch
	     (input_PC + immediate(iaddr_size-1 downto 0))    when Op = pc_bneq and (R1 /= R2) else  -- branch
	     input_PC + 1;

  output_PC <= temp_PC;
  
end Behavioral;
