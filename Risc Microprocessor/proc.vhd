---------------------------------------------------
-- PROCESSOR
-- 
-- the processor architecture
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.processor_pkg.all;

entity PROCESSOR is  -- given
port(  clk,resetn : in Std_logic;
       iaddr_out  : out Std_logic_vector(iaddr_size-1 downto 0);
       idata_in   : in Std_logic_vector(instr_size-1 downto 0); -- input instruction (taken from bus)
       daddr_out  : out Std_logic_vector(daddr_size-1 downto 0);
       dmem_read, dmem_write : out std_logic;
       ddata_in   : in Std_logic_vector(data_size-1 downto 0);
       ddata_out  : out Std_logic_vector(data_size-1 downto 0)  );
end PROCESSOR;

architecture struct of PROCESSOR is
        component decode
        port (  instruction : in  STD_LOGIC_VECTOR (instr_size-1 downto 0);-- the entire input instruction
                RD : out  STD_LOGIC_VECTOR(rf_addr_size-1 downto 0);  -- the decoded register to write
                RA : out  STD_LOGIC_VECTOR(rf_addr_size-1 downto 0);  -- the decoded register as input1
                RB : out  STD_LOGIC_VECTOR(rf_addr_size-1 downto 0);  -- the decoded register as input2
                immediate : out  STD_LOGIC_VECTOR(data_size-1 downto 0);  -- the decoded value for certain operations
                aluop  : out  alu_op;
                pcop   : out  pc_op;
                memop  : out  mem_op;
                wb_sel : out  wbsel_op);  -- to indicate if ALU,multiplier, or something else should be used
        end component;

        component Rfile
  	port (	clk: in STD_LOGIC;
		resetn: in STD_LOGIC;
		write_enable: in STD_LOGIC;
		address_a, address_b: in STD_LOGIC_VECTOR(rf_addr_size-1 downto 0);  -- addresses of A and B for reading

		a_out: out STD_LOGIC_VECTOR(data_size-1 downto 0);  -- output data for A
		b_out: out STD_LOGIC_VECTOR(data_size-1 downto 0);  -- output data for B

		address_write: in STD_LOGIC_VECTOR(rf_addr_size-1 downto 0);  -- address to write
		data_write: in Std_logic_vector(data_size-1 downto 0));  -- input data to write
        end component;

        component alu                	
                port(A,B,immediate: in std_logic_vector(data_size-1 downto 0);
                     Op:   in alu_op;
                     R:	   out std_logic_vector(data_size-1 downto 0)  );
        end component;

        component program_counter
        port ( clk,resetn : in  STD_LOGIC;
               R1 : in STD_LOGIC_VECTOR (data_size-1 downto 0);
	       R2 : in STD_LOGIC_VECTOR (data_size-1 downto 0);
               immediate : in STD_LOGIC_VECTOR (data_size-1 downto 0);
               Op : in  pc_op;
               output_PC : out  STD_LOGIC_VECTOR (iaddr_size-1 downto 0)    );
        end component;

	component multiplier 
		generic
			(  size : positive := 32);
		port
			(  A, B: in std_logic_vector(size-1 downto 0);
			   R: out std_logic_vector(size-1 downto 0) );
	end component;
        
        component memory_logic
        port (--clk,resetn  : in Std_logic;
        S,RB,offset : in Std_logic_vector(data_size-1 downto 0);  -- source (from register file), register base, offset (think of it as register(offset))
        memop       : in mem_op;
        wb_data     : out Std_logic_vector(data_size-1 downto 0);
        -- Signal for the memory outside (all the above comes from the processor)
        mr,mw       : out Std_logic;
        address     : out Std_logic_vector(daddr_size-1 downto 0);
        wdata       : out Std_logic_vector(data_size-1 downto 0);
        rdata       : in  Std_logic_vector(data_size-1 downto 0) );
        end component;

	signal RD : STD_LOGIC_VECTOR(3 downto 0);  -- the decoded register to write
	signal RA : STD_LOGIC_VECTOR (3 downto 0);  -- the decoded register as input1
	signal RB : STD_LOGIC_VECTOR (3 downto 0);  -- the decoded register as input2
	signal immediate : STD_LOGIC_VECTOR (data_size-1 downto 0);  -- the decoded value for certain operations
        signal aluop : alu_op;
        signal pcop  : pc_op;
        signal memop : mem_op;
        signal wb_sel: wbsel_op;  -- to indicate if ALU,multiplier, or something else should be used

	signal A,B,R,aluR,memR,mulR : STD_LOGIC_VECTOR(data_size-1 downto 0);

        -- signals needed to delay one clock pulse to match access for the memory
        signal wb_sel_delayed : wbsel_op;
        signal aluR_delayed : STD_LOGIC_VECTOR(data_size-1 downto 0);
        signal mulR_delayed : std_logic_vector(31 downto 0);
        signal RD_delayed : STD_LOGIC_VECTOR(rf_addr_size-1 downto 0);

begin  -- struct

-- ports for PROCESSOR:
-- clk, resetn, iaddr_out, idata_in, daddr_out, dmem_read, dmem_write, ddata_in, ddata_out

        -- Pipeline regs (flip flop that delays one clock pulse)
        process(clk)
        begin
           if clk'event and clk='1' then
               wb_sel_delayed <= wb_sel; 
               aluR_delayed <= aluR; -- delay output of ALU before sending into multiplexer for R
               mulR_delayed <= mulR;
               RD_delayed <= RD; -- delay RD that has been decoded from decoder before sending into register
           end if;
        end process;

	decoder : decode port map(idata_in, RD, RA, RB, immediate, aluop, pcop, memop, wb_sel);
        register1 : Rfile port map(clk, resetn, '1', RA, RB, A, B, RD_delayed, R);

        memlogic : memory_logic port map (A,B, immediate, memop, memR, dmem_read,dmem_write, daddr_out, ddata_out, ddata_in);
        
	alu1    : alu    port map(A, B, immediate, aluop, aluR);
	PC1     : program_counter port map(clk,resetn, A, B, immediate, pcop, iaddr_out); --PC increments internally (contains a signal inside)
                                                                                          --(A and B are for comparisons and changes counter if required)
	MUL     : multiplier port map(A, B, mulR);

        R <= aluR_delayed when wb_sel_delayed = wb_alu else
             mulR_delayed when wb_sel_delayed = wb_mul else
             memR         when wb_sel_delayed = wb_mem else
             (others=>'0');

end struct;
