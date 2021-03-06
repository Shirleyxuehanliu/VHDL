---------------------------------------------------
-- ALU = Arithmetic Logic Unit
-- 
-- ALU is a digital circuit which does arithmetic
-- and logical operations. It is a basic block in 
-- any processor.
--
-- The ALU described here receives two input
-- operands 'A' and 'B' which are 32 bits long.
-- The result is denoted by 'R' which is also 32
-- bits long. The input signal 'Op' is a 3-bits
-- value which tells the ALU what operation to be
-- performed. Since 'Op' is 3-bits long there can
-- be 2^3 = 8 operations.
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- numeric_std is a IEEE standard package, but std_logic_arith and std_logic_unsigned is not
use ieee.std_logic_unsigned.all;

use work.processor_pkg.all;
---------------------------------------------------

entity alu is
	port(A,B,immediate: in std_logic_vector(data_size-1 downto 0);
	     Op:   in alu_op;
	     R:	   out std_logic_vector(data_size-1 downto 0)  );
end alu;

---------------------------------------------------

architecture behv of alu is
begin
        R <= (A + immediate)   when Op = alu_addi else  -- ADDI (add A to immediate)
             (A and immediate) when Op = alu_andi else  -- ANDI (AND A, immediate)
             (A or immediate)  when Op = alu_ori else  -- ORI (OR A, immediate)
             (x"0000000" & "0001") when Op = alu_slti and (A < immediate) else  -- SLTI (set R=1 if A < immediate)
             (immediate(16-1 downto 8) & A(23 downto 0)) when Op = alu_lui else  -- LUI (load immediate on upper 8 bits of A)
             (A + B) when Op = alu_add else  -- ADD (add A to B)
             (A - B) when Op = alu_sub else  -- SUB (subtract A from B)
             (A and B) when Op = alu_and else  -- AND (AND A, B)
             (A or B) when Op = alu_or else  -- OR (OR A, B)
             (x"0000000" & "0001") when Op = alu_slt and (A < B) else  -- SLT (set R=1 if A < B)
             std_logic_vector(shift_left(unsigned(A), to_integer(unsigned(B)))) when Op = alu_sll else -- shift left logical A of B bits
             std_logic_vector(shift_right(unsigned(A),to_integer(unsigned(B)))) when Op = alu_srl else  -- shift right logical A of B bits
             std_logic_vector(shift_right(signed(A),  to_integer(unsigned(B)))) when Op = alu_sra else  -- shift right arithmetical A of B bits
             x"00000000";
             -- lw, sw are not done here
             -- beq, bneq are for program counter, so not done here
end behv;

----------------------------------------------------
