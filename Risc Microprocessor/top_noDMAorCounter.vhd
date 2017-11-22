library ieee;
use ieee.std_logic_1164.all;

use work.processor_pkg.all;

entity top is
  port(  clk,resetn : in Std_logic
         );
end top;

architecture struct of top is

  component PROCESSOR
    port(  clk,resetn : in Std_logic;
           iaddr_out  : out Std_logic_vector(iaddr_size-1 downto 0);
           idata_in   : in Std_logic_vector(instr_size-1 downto 0); -- input instruction
           daddr_out  : out Std_logic_vector(daddr_size-1 downto 0);
           dmem_read, dmem_write : out std_logic;
           ddata_in   : in Std_logic_vector(data_size-1 downto 0);
           ddata_out  : out Std_logic_vector(data_size-1 downto 0)  );
  end component;

  component SRAM
    generic ( addr_size : integer := 8;word_size : integer := 16 );
    port (  clk       :   in  std_logic;
            rdn       :   in  std_logic;
            wrn       :   in  std_logic;
            address   :   in  std_logic_vector(addr_size-1 downto 0);
            bit_wen   :   in  std_logic_vector(word_size-1 downto 0);
            data_in   :   in  std_logic_vector(word_size-1 downto 0);
            data_out  :   out std_logic_vector(word_size-1 downto 0) );
  end component;
  
  component ubus    
    generic(addr_width : integer := 32; data_width : integer := 32;
            s1_start : Std_logic_vector := X"40001000";
            s1_end   : Std_logic_vector := X"40002000";
            s2_start : Std_logic_vector := X"50000000";
            s2_end   : Std_logic_vector := X"f0000000";
            s3_start : Std_logic_vector := X"00000000";
            s3_end   : Std_logic_vector := X"00000000";
            s4_start : Std_logic_vector := X"00000000";
            s4_end   : Std_logic_vector := X"00000000");
    port ( clk,reset           : in Std_logic;
           -- M1 port
           M1_BUSY,M1_MR,M1_MW : in   Std_logic;
           M1_NREADY           : out  Std_logic;
           M1_ADDRBUS          : in   Std_logic_vector(addr_width-1 downto 0);
           M1_RDATABUS         : out  Std_logic_vector(data_width-1 downto 0);
           M1_WDATABUS         : in   Std_logic_vector(data_width-1 downto 0);

           -- M2 port
           M2_BUSY,M2_MR,M2_MW : in   Std_logic;
           M2_NREADY           : out  Std_logic;
           M2_ADDRBUS          : in   Std_logic_vector(addr_width-1 downto 0);
           M2_RDATABUS         : out  Std_logic_vector(data_width-1 downto 0);
           M2_WDATABUS         : in   Std_logic_vector(data_width-1 downto 0);
             
           -- S1 port
           S1_BUSY,S1_MR,S1_MW : out  Std_logic;               
           S1_NREADY           : in   Std_logic;
           S1_ADDRBUS          : out  Std_logic_vector(addr_width-1 downto 0);
           S1_RDATABUS         : in   Std_logic_vector(data_width-1 downto 0);
           S1_WDATABUS         : out  Std_logic_vector(data_width-1 downto 0);
  
           -- S2 port
           S2_BUSY,S2_MR,S2_MW : out  Std_logic;
           S2_NREADY           : in   Std_logic;
           S2_ADDRBUS          : out  Std_logic_vector(addr_width-1 downto 0);
           S2_RDATABUS         : in   Std_logic_vector(data_width-1 downto 0);
           S2_WDATABUS         : out  Std_logic_vector(data_width-1 downto 0);
    
           -- S3 port
           S3_BUSY,S3_MR,S3_MW : out  Std_logic;
           S3_NREADY           : in   Std_logic;
           S3_ADDRBUS          : out  Std_logic_vector(addr_width-1 downto 0);
           S3_RDATABUS         : in   Std_logic_vector(data_width-1 downto 0);
           S3_WDATABUS         : out  Std_logic_vector(data_width-1 downto 0);
  
           -- S4 port
           S4_BUSY,S4_MR,S4_MW : out  Std_logic;
           S4_NREADY           : in   Std_logic;
           S4_ADDRBUS          : out  Std_logic_vector(addr_width-1 downto 0);
           S4_RDATABUS         : in   Std_logic_vector(data_width-1 downto 0);
           S4_WDATABUS         : out  Std_logic_vector(data_width-1 downto 0) );
  end component;

  signal iaddr_out : std_logic_vector(iaddr_size-1 downto 0);
  signal idata_in  : std_logic_vector(instr_size-1 downto 0);

  -- Processor Signals
  signal dmem_write,dmem_read : Std_logic;
  signal daddr_out : std_logic_vector(daddr_size-1 downto 0);
  signal ddata_in,ddata_out : std_logic_vector(data_size-1 downto 0);

  -- SRAM Signals
  signal sram_Mr,sram_Mw : std_logic;
  signal sram_addr : std_logic_vector(daddr_size-1 downto 0);
  signal sram_rdata,sram_wdata : std_logic_vector(data_size-1 downto 0);
  
begin  -- struct

  proc  : PROCESSOR port map (clk, resetn, iaddr_out, idata_in, daddr_out, dmem_read, dmem_write, ddata_in, ddata_out);

  IRAM  : SRAM -- instruction memory
    generic map ( addr_size => 11, word_size => 32 ) 
    port map (clk, '1', '0', iaddr_out(10 downto 0), x"FFFFFFFF", x"00000000", idata_in); -- x"FFFFFFFF" for bit_wen since read-only
  
  DRAM  : SRAM -- data memory 
    generic map ( addr_size => 11, word_size => 32 )
    port map (clk, sram_Mr,sram_MW,sram_addr(10 downto 0), x"00000000", sram_wdata, sram_rdata); --
                                                                                          
  
  ubus1 : ubus generic map (addr_width => daddr_size, data_width => data_size,
                            s1_start=>X"4000",s1_end=>X"47ff",
                            s2_start=>X"0000",s2_end=>X"0000",
                            s3_start=>X"0000",s3_end=>X"0000",
                            s4_start=>X"0000",s4_end=>X"0000")
                port map (clk, resetn,
                         -- Master 1: Processor
                         '0', dmem_read, dmem_write,open,daddr_out, ddata_in,ddata_out,

                         -- Master 2: DMA
                         '0','0','0',open, x"0000",open,x"00000000",
			 --'0',DMAM_MR,DMAM_MW,DMAM_NREADY,DMAM_ADDRBUS,DMAM_RDATABUS,DMAM_WDATABUS,

                         -- Slave 1
                         open,sram_mr,sram_MW,'0',sram_addr,sram_rdata,sram_wdata,

                         -- Slave 2 (use this slave so outside source can access?)
                         open,open,open,'0',open,x"00000000",open,
			 --EXT_BUSY,S1_MR,S1_MW,EXT_NREADY,EXT_ADDRBUS,EXT_RDATABUS,EXT_WDATABUS,

			 -- Slave 3 (for DMA as slave signals)
                         open,open,open,'0',open,x"00000000",open,
			 --DMAS_BUSY,DMAS_MR,DMAS_MW,'0',DMAS_ADDRBUS,DMAS_RDATABUS,DMAS_WDATABUS,

			 -- Slave 4 (for my_Counter)
                         open,open,open,'0',open,x"00000000",open );
			 --CNT_BUSY,CNT_MR,CNT_MW,'0',CNT_ADDRBUS,CNT_RDATABUS,CNT_WDATABUS );

end struct;
