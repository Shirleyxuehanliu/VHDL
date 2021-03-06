library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use work.processor_pkg.all;


-- a register file is a classic component of processor architectures.
-- It is composed of a given number of memory locations that can be used
-- to feed ALU operations

entity Rfile is
	port (	clk,resetn: in STD_LOGIC;
		write_enable: in STD_LOGIC;
		address_a, address_b: in STD_LOGIC_VECTOR(rf_addr_size-1 downto 0);  -- addresses of A and B for reading
                
		a_out: out STD_LOGIC_VECTOR(data_size-1 downto 0);  -- output data for A
		b_out: out STD_LOGIC_VECTOR(data_size-1 downto 0);  -- output data for B

		address_write: in STD_LOGIC_VECTOR(rf_addr_size-1 downto 0);  -- address to write
		data_write: in Std_logic_vector(data_size-1 downto 0));  -- input data to write
end;

architecture behavioral of Rfile is

-- define register file data structure (32 registers with size 32-bit each)
type rf_bus_array is array ((2**rf_addr_size - 1) downto 0) of STD_LOGIC_VECTOR(data_size-1 downto 0);

signal tmp_reg : rf_bus_array;

begin
  -- on most RISC processor architectures (except for ARM), Register 0 is grounded
  tmp_reg(0) <= (others => '0');        -- sets Register 0 to be 32'b0

  -- sequential process defining the register i, it is repeated 2^addr_size times
  REGS: for i in 1 to (2**rf_addr_size-1) generate
    process(clk,resetn)
    begin
      if resetn = '0' then
        tmp_reg(i) <= (others => '0');  -- reset all registers
      elsif clk'event and clk = '1' then
        if (write_enable = '1') and (CONV_INTEGER(address_write) = i) then
          tmp_reg(i) <= data_write;
        end if;      
      end if;
    end process;
  end generate REGS;

  a_out <= tmp_reg(CONV_INTEGER(address_a));
  b_out <= tmp_reg(CONV_INTEGER(address_b));
  
end behavioral;
