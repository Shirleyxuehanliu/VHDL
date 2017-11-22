library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_SIGNED.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity decode is  
  port (   instruction : in  STD_LOGIC_VECTOR (instr_size-1 downto 0);-- the entire input instruction              
           RD : out  STD_LOGIC_VECTOR(rf_addr_size-1 downto 0);  -- the decoded register to write
           RA : out  STD_LOGIC_VECTOR(rf_addr_size-1 downto 0);  -- the decoded register as input1
           RB : out  STD_LOGIC_VECTOR(rf_addr_size-1 downto 0);  -- the decoded register as input2
           immediate : out  STD_LOGIC_VECTOR(data_size-1 downto 0);  -- the decoded value for certain operations
           aluop  : out  alu_op;
           pcop   : out  pc_op;
           memop  : out  mem_op;
           wb_sel : out  wbsel_op);  -- to indicate if ALU,multiplier, or something else should be used
end decode;
 
architecture Behavioral of decode is
 
begin

  process(instruction)  -- since a lot of different instructions, so better than using "when"
    variable Op : STD_LOGIC_VECTOR(7 downto 0);
    variable r1,r2,r3 : std_logic_vector(3 downto 0);
  begin
     Op := instruction(31 downto 24);  -- we changed size of Op,r1,r2,r3 on purpose
     r1 := instruction(23 downto 20);   -- 4 bits
     r2 := instruction(19 downto 16);   -- 4 bits
     r3 := instruction(15 downto 12);   -- 4 bits

     aluop <= alu_add; pcop <= pc_cont; memop <= mem_nop;

     RD <= (others => '0');  -- best to set write destination to '0' in case operation does not need to write but accidentally writes
     RA <= r2;  -- default for RA
     RB <= r3;  -- default for RB
     wb_sel <= wb_alu;  -- default indicates that ALU should be used (otherwise it would be multiplier)
     
     if Op = op_addi then  -- if add immediate
        aluop <= alu_addi;  -- then ALU operation is ADDITION
        RD <= r1;  -- destination to write is r1
		   -- don't need to write for RA or RB here since same as default
     elsif Op = op_andi then
        aluop <= alu_andi;
        RD <= r1;
     elsif Op = op_ori then
        aluop <= alu_ori;
        RD <= r1;
     elsif Op = op_slti then  -- set R = 1 if A < immediate
        aluop <= alu_slti;
        RD <= r1;
     elsif Op = op_lui then  -- load immediate on upper 8 bits of A
        aluop <= alu_lui;
        RD <= r1;

     elsif Op = op_lw then              -- the one of only 2 memory operations
        memop <= mem_lw;
        wb_sel <= wb_mem;
        RD <= r1;
        RB <= r2;              
     elsif Op = op_sw then              -- the one of only 2 memory operations
        memop <= mem_sw;
        RA <= r1;
        RB <= r2;

     elsif Op = op_beq then
        pcop <= pc_beq;
     elsif Op = op_bneq then
        pcop <= pc_bneq;
        RA <= r1;
        RB <= r2;

     elsif Op = op_add then
        aluop <= alu_add;
        RD <= r1;
     elsif Op = op_sub then
        aluop <= alu_sub;
        RD <= r1;
     elsif Op = op_and then
        aluop <= alu_and;
        RD <= r1;
     elsif Op = op_or then
        aluop <= alu_or;
        RD <= r1;
     elsif Op = op_slt then  -- set R = 1 if A < B
        aluop <= alu_slt;
        RD <= r1;
     elsif Op = op_sll then  -- shift left logical A of B bit locations
        aluop <= alu_sll;
        RD <= r1;
     elsif Op = op_srl then  -- shift right logical A of B bit locations
        aluop <= alu_srl;
        RD <= r1;
     elsif Op = op_sra then  -- shift right arithmetical A of B bit locations
        aluop <= alu_sra;
        RD <= r1;

     elsif Op=op_mul then
        RD <= r1;
        wb_sel <= wb_mul; -- to indicate multiplier should be used
        
     elsif Op=op_j then
        pcop <= pc_jump;
     -- no need to assign an else statement
     end if;
  end process;

     immediate <= std_logic_vector( resize(signed(instruction(15 downto 0)),data_size) );

end Behavioral;
 
