library IEEE;
use IEEE.std_logic_1164.all;

package processor_pkg is
type pc_op is (pc_cont,pc_jump,pc_beq,pc_bneq);
type alu_op is (alu_addi,alu_andi,alu_ori,alu_slti,alu_lui,alu_add,alu_sub,alu_and,alu_or,alu_slt,alu_sll,alu_srl,alu_sra);
type mem_op is (mem_nop,mem_lw,mem_sw);
type wbsel_op is (wb_alu,wb_mul,wb_mem);
subtype op_type is STD_LOGIC_VECTOR(7 downto 0);

constant iaddr_size : positive := 16; -- for proc.vhd
constant instr_size : positive := 32; -- for proc.vhd
constant daddr_size : positive := 16; -- for proc.vhd
constant data_size  : positive := 32; -- for proc.vhd
constant rf_addr_size : positive := 4;

constant op_addi : op_type := x"10";
constant op_andi : op_type := x"11";
constant op_ori  : op_type := x"12";
constant op_slti : op_type := x"13";
constant op_lui  : op_type := x"14";
constant op_lw   : op_type := x"15";    -- memory operation
constant op_sw   : op_type := x"16";    -- memory operation
constant op_beq  : op_type := x"1a"; -- for program counter
constant op_bneq : op_type := x"1b"; -- for program counter

constant op_add : op_type := x"00";
constant op_sub : op_type := x"01";
constant op_and : op_type := x"02";
constant op_or  : op_type := x"03";
constant op_slt : op_type := x"04";
constant op_sll : op_type := x"05";
constant op_srl : op_type := x"06";
constant op_sra : op_type := x"07";

constant op_mul : op_type := x"08";
constant op_j   : op_type := x"0f"; -- for program counter

end processor_pkg;
