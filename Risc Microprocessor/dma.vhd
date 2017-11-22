-------------------------------------------------------------------------------
-- dma.vhd by fabio campi 2015
--
-------------------------------------------------------------------------------
--
-- Simple DMA Block, performs simple transfers on the bus
-- The DMA is programmed by means of the following registers
-- Address 0x0 Count registers: number of transfer requested (this should be
--                              written last as it will start the transfer.
--                              Specifying 0xffffffff will cause infinite transfers
-- Address 0x4 Source Base Register
-- Address 0x5 Source Step Register
-- Address 0x6 Destination Base Register
-- Address 0x7 Destination Address Register

-- Every time Count > 0 the DMA will perform Count transfers, from Source Base
-- to Destination Base, incrementing both addresses by their steps at every cycle
-- this VHDL code is open Source, please use freely but no responsibility can
-- be accepted on its functioning

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

 entity DMA is
   generic ( signal_active : std_logic := '0'; size : positive := 32; addr_size : positive := 32);
   Port (   -- System Control Signals
           CLK, reset          : in   Std_logic;
            
           -- M1 port
           M1_BUSY,M1_MR,M1_MW : out  Std_logic;
           M1_NREADY           : in   Std_logic;
           M1_ADDRBUS          : out  Std_logic_vector(addr_size-1 downto 0);
           M1_RDATABUS         : in   Std_logic_vector(size-1 downto 0);
           M1_WDATABUS         : out  Std_logic_vector(size-1 downto 0);

           -- Slave (Control) port
           S1_BUSY,S1_MR,S1_MW : in   Std_logic;               
           S1_NREADY           : out  Std_logic;
           S1_ADDRBUS          : in   Std_logic_vector(3 downto 0);
           S1_RDATABUS         : out  Std_logic_vector(size-1 downto 0);
           S1_WDATABUS         : in   Std_logic_vector(size-1 downto 0) ); 
 end DMA;

 architecture beh of DMA is

 type DMA_State_type is (dma_idle, dma_raddr, dma_rdata, dma_waddr);

 constant signal_not_active : std_logic := not signal_active;
   
 signal DMA_State,next_DMA_state : DMA_State_type;
 signal data_reg, count_reg, next_count  : std_logic_vector(size-1 downto 0); 
 signal rstart_reg, rstep_reg, raddr_reg, next_raddress : std_logic_vector(size-1 downto 0);
 signal wstart_reg, wstep_reg, waddr_reg, next_waddress : std_logic_vector(size-1 downto 0);
 signal ck_S1_ADDRBUS : std_logic_vector(3 downto 0);
 
 begin

    DMA_FSM : process(DMA_State, M1_NREADY, data_reg, count_reg,
                      raddr_reg, waddr_reg, rstart_reg, wstart_reg, rstep_reg, wstep_reg )
    begin  -- This is a Moore's Finite State Machine Definition
              
      -- Default Outputs: No access to Mater bus, open access to slave bus
      M1_ADDRBUS  <= (others=>'0');  M1_WDATABUS <= (others=>'0');
      M1_MR <= signal_not_active; M1_MW <= signal_not_active; M1_BUSY <= signal_not_active;
                                           
      -- Default Option: No address increment
      next_raddress <= raddr_reg;
      next_waddress <= waddr_reg;
      next_count    <= count_reg;

      -- FSM Definition:This is (mostly) MOORE's FSM Notation:
      -- Outputs are only functions of State, not of inputs. We need to take a
      -- small exception for copying the address onto output at the beginning of the DMA transaction
      
      case DMA_State is
         
        when dma_idle =>
           if (unsigned(count_reg) > to_unsigned(0,size) ) then
              next_DMA_state <= dma_raddr;
              next_raddress  <= rstart_reg;
              next_waddress  <= wstart_reg;
            else
              next_DMA_state <= dma_idle;
           end if;
            
        when dma_raddr => 
           M1_ADDRBUS <= raddr_reg(addr_size-1 downto 0); M1_MR <= signal_active;
            
           if M1_NREADY=signal_active then
              -- The bus is not able to respond (may be taken from a higher
              -- priority master), we need to keep asking for it
              next_DMA_state <= dma_raddr;  
           else
              next_DMA_state <= dma_rdata;
           end if;
            
        when dma_rdata =>
        
           if M1_NREADY=signal_active then
              next_DMA_state <= dma_rdata;  -- The bus is not able to respond,we need to keep reading data
           else
              next_DMA_state <= dma_waddr;
           end if;
            
        when dma_waddr =>
           M1_ADDRBUS  <= waddr_reg(addr_size-1 downto 0); M1_MW <= signal_active;
           M1_WDATABUS <= data_reg;
            
           if M1_NREADY=signal_active then
              next_DMA_state <= dma_waddr;  -- The bus is not able to respond,we need to keep writing
           else
              if count_reg /= std_logic_vector(to_unsigned(1,size)) then  -- DMA Transfer is not over yet
                 next_DMA_state <= dma_raddr;
                 next_raddress  <= std_logic_vector( signed(raddr_reg) + signed(rstep_reg) );
                 next_waddress  <= std_logic_vector( signed(waddr_reg) + signed(wstep_reg) );
                 if count_reg /= x"ffffffff" then next_count     <= std_logic_vector( signed(count_reg) - to_signed(1,size)); end if;
              else
                 next_DMA_state <= dma_idle;  -- DMA Transfer is OVER!
                 next_count     <= (others=>'0');
              end if;
           end if;                                                                                 
        when others => next_DMA_state <= dma_idle;                        
      end case;       
    end process;
    
   DMA_RFile: process(clk)
   begin
     if clk'event and clk='1' then 
         if reset='0' then
           DMA_State    <= dma_idle;
           data_reg     <= (others => '0');
           count_reg    <= (others => '0');
           rstart_reg   <= (others => '0');           
           rstep_reg    <= (others => '0');
           wstart_reg   <= (others => '0');
           wstep_reg    <= (others => '0');
           raddr_reg    <= (others => '0');
           waddr_reg    <= (others => '0'); 
         else
	    -- Writing external registers from outside. In this release, the processor can overwrite parameters during a transaction 
		-- Note: The Address Registers are Read-Only, can only be written by the DMA increment logic
	   if S1_MW=signal_active and S1_BUSY=signal_not_active then
              if S1_ADDRBUS = "0000" then count_reg    <= S1_WDATABUS;  end if;
              if S1_ADDRBUS = "0100" then rstart_reg   <= S1_WDATABUS;  end if;             
              if S1_ADDRBUS = "0101" then rstep_reg    <= S1_WDATABUS;  end if;
              if S1_ADDRBUS = "0110" then wstart_reg   <= S1_WDATABUS;  end if;
              if S1_ADDRBUS = "0111" then wstep_reg    <= S1_WDATABUS;  end if;
            end if;
     
            DMA_State <= next_DMA_state;
            raddr_reg <= next_raddress;
            waddr_reg <= next_waddress;
		
           -- Data Register: It can be neither read nor written from the bus, it
           -- is used to pass data from READ to Write. It may eventually become a FIFO
           if DMA_State = dma_rdata and M1_NREADY=signal_not_active then
              data_reg <= M1_RDATABUS;            
           elsif DMA_State=dma_waddr then
             count_reg <= next_count;   
           end if;
      end if;
    end if;
  end process;

       
  -- Slave Bus Response Logic:
       
  process(clk)  -- Sampling Read address for producing Output when the DMA state is being read
  begin
     if clk'event and clk='1' then
        if reset='0' then 
           ck_S1_ADDRBUS <= (Others=>'1');
        else
            if S1_MW=signal_active and S1_BUSY=signal_not_active then ck_S1_ADDRBUS <= S1_ADDRBUS; end if;
        end if;
     end if;        
   end process;
      
  S1_RDATABUS <= count_reg    when ck_S1_ADDRBUS = "0000" else
                 rstart_reg   when ck_S1_ADDRBUS = "0100" else                 
                 rstep_reg    when ck_S1_ADDRBUS = "0101" else
                 wstart_reg   when ck_S1_ADDRBUS = "0110" else
                 wstep_reg    when ck_S1_ADDRBUS = "0111" else
                 -- The following registers (currently accessed location) are READ-ONLY
                 raddr_reg    when ck_S1_ADDRBUS = "1000" else
                 waddr_reg    when ck_S1_ADDRBUS = "1000" else
                 (Others=>'0');
				 
  S1_NREADY <= signal_not_active;
  
 end beh;
