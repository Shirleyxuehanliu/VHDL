-------------------------------------------------------------------------------
-- ubus
-- by fcampi@sfu.ca Feb 2014
--
-- Local Bus for the internal data bus
-- of the Qrisc processor up island
-------------------------------------------------------------------------------

-- There is an interesting challenge in this design, that is how to handle
-- ready signals coming from the slaves in case slaves have a response time
-- higher than 1 cycle, for example FIFOs that may be empty or full.
-- 

-- Meaning of signals: MR, MW are in the Phase one of the addressing, and
-- signify that the master requires the bus

-- NREADY comes from the slave in the second phase of the addressing. It means
-- that the SLAVE can not serve the master request, so it freezes the master
-- requiring additional time for the slave to complete the service. It forces
-- an additional Phase one on the bus.

-- BUSY comes from the master during phase2, and signifies that the master is
-- not available to read the output produced by the slave (it only happens
-- during a read operation!). In this case, the phase 2 must be prolonged, and
-- the bus will not access any other bus transitions in phase 1.

library IEEE;
  use std.textio.all;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

  entity ubus is    
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
  end ubus;

  architecture struct of ubus is

  type master_type is (m1,m2, default);
  type slave_type  is (s1,s2,s3,s4, default);
  type acc_type is (nop, read, write, stall);
      
  type Bus_op is
    record
      master : master_type; 
      slave  : slave_type;
      op     : acc_type;     
    end record;

  signal c1_op,c2_op    : Bus_op;
  signal c1_addrbus     : Std_logic_vector(addr_width-1 downto 0);
  signal c1_nready      : Std_logic;
  signal c1_wdatabus    : Std_logic_vector(data_width-1 downto 0);
  signal c2_rdatabus    : Std_logic_vector(data_width-1 downto 0);
  signal c2_BUSY        : Std_logic;
    
  begin  -- struct

    -- C1 predecoding, Determine master with current priority
    -- (priority policy can be evolved, now M1 is prioritary and M2 waits)
    process(M1_MR,M1_MW,M2_MR,M2_MW,c2_BUSY)
    begin
      c1_op.master <= default;
      c1_op.op     <= nop;     
      -- Detecting if Master 1 Is requiring bus service
      if (M1_MR='1') then
        c1_op.master <= m1;
        c1_op.op     <= read;              
      elsif (M1_MW='1') then
        c1_op.master <= m1;
        c1_op.op     <= write;
      -- Detecting if Master 1 Is requiring bus service
      elsif (M2_MR='1') then 
	c1_op.master <= m2;
        c1_op.op     <= read;
      elsif (M2_MW='1') then
        c1_op.master <= m2;
        c1_op.op     <= write;
      end if;
      -- In case of 
      if c2_BUSY='1' then
        c1_op.op <= stall;  
      end if;  
    end process;

    addr_Mux: C1_addrbus  <=  M1_ADDRBUS when c1_op.master=m1 and (c1_op.op=write or c1_op.op=read) else 
                              M2_ADDRBUS when c1_op.master=m2 and (c1_op.op=write or c1_op.op=read) else 
                              (others=>'0');
				  
    wdata_Mux: C1_wdatabus <= M1_WDATABUS when (c1_op.master=m1 and c1_op.op=write) else 
                              M2_WDATABUS when (c1_op.master=m2 and c1_op.op=write) else
                              (others=>'0');          

    -- Cycle Bus 1 (Addressing): Determining the Slave to be addressed based on the bus address table
    process(C1_addrbus,c1_op,c2_BUSY)    
    begin
        c1_op.slave <= default;
        if c1_op.op /= nop and c2_BUSY='0' then
          if    (unsigned(C1_addrbus) >= resize(unsigned(s1_start),addr_width) ) and
                (unsigned(C1_addrbus) <= resize(unsigned(s1_end),  addr_width) ) then
              c1_op.slave <= s1;          
          elsif (unsigned(C1_addrbus) >= resize(unsigned(s2_start),addr_width) ) and
                (unsigned(C1_addrbus) <= resize(unsigned(s2_end)  ,addr_width) ) then
              c1_op.slave <= s2;       
          elsif (unsigned(C1_addrbus) >= resize(unsigned(s3_start),addr_width)  ) and
                (unsigned(C1_addrbus) <= resize(unsigned(s3_end),  addr_width)  ) then
              c1_op.slave <= s3; 
          elsif (unsigned(C1_addrbus) >= resize(unsigned(s4_start),addr_width) ) and
                (unsigned(C1_addrbus) <= resize(unsigned(s4_end)  ,addr_width) ) then
              c1_op.slave <= s4; 
          end if;
        end if;
    end process;
      

    -- Still in Cycle Bus 1: based on the addressed slave, back-annotation the
    -- appropriate NREADY signal. 
    c1_nready <=  S1_NREADY when c1_op.slave=s1 else
                  S2_NREADY when c1_op.slave=s2 else
                  S3_NREADY when c1_op.slave=s3 else
                  S4_NREADY when c1_op.slave=s4 else
                 '0';

    -- NREADY can be asserted (low) in three cases:
    -- a) Master is requiring the bus but another master is having it
    -- b) The slave addressed by the master needs an extension during the
    -- addressing (NREADY='0')
    -- c) The master in phase 2 is needs an extension during the reading (BUSY='0')
    M1_NREADY   <= '1' when (M1_MW='1' or M1_MR='1') and c1_op.master/=m1 else
                   '1' when (c1_op.master=m1 and c1_nready='1') else
                   '1' when (c1_op.master=m1 and c2_BUSY='1')  else 
                   '0';
      
    M2_NREADY   <= '1' when (M2_MW='1' or M2_MR='1') and c1_op.master/=m2 else
                   '1' when (c1_op.master=m2 and c1_nready='1') else
                   '1' when (c1_op.master=m2 and c2_BUSY='1')  else   
                   '0';
      
    S1_ADDRBUS <= C1_addrbus when c1_op.slave = s1 else (others=>'0');
    S2_ADDRBUS <= C1_addrbus when c1_op.slave = s2 else (others=>'0');
    S3_ADDRBUS <= C1_addrbus when c1_op.slave = s3 else (others=>'0');                   
    S4_ADDRBUS <= C1_addrbus when c1_op.slave = s4 else (others=>'0');

    S1_WDATABUS <= C1_wdatabus when c1_op.slave = s1 else (others=>'0');
    S2_WDATABUS <= C1_wdatabus when c1_op.slave = s2 else (others=>'0');
    S3_WDATABUS <= C1_wdatabus when c1_op.slave = s3 else (others=>'0');
    S4_WDATABUS <= C1_wdatabus when c1_op.slave = s4 else (others=>'0');
    
    S1_MR <= '1' when c1_op.op=read and c1_op.slave = s1 else '0';
    S2_MR <= '1' when c1_op.op=read and c1_op.slave = s2 else '0';
    S3_MR <= '1' when c1_op.op=read and c1_op.slave = s3 else '0';
    S4_MR <= '1' when c1_op.op=read and c1_op.slave = s4 else '0';

    S1_MW <= '1' when c1_op.op=write and c1_op.slave = s1 else '0';
    S2_MW <= '1' when c1_op.op=write and c1_op.slave = s2 else '0';
    S3_MW <= '1' when c1_op.op=write and c1_op.slave = s3 else '0';
    S4_MW <= '1' when c1_op.op=write and c1_op.slave = s4 else '0';
      
    -- Sequential process sampling the incoming Address in order to route the
    -- relative data upon reading.
    -- Note: here we need to implement eventual waitstates. If the addressed
    -- slave is not ready, we stay in cycle1 and we can't step on to the
    -- following stage. The active master is stalled as well  
    process(clk,reset)
    begin
        if reset='0' then
          c2_op.op <= nop;
          c2_op.master <= default;
          c2_op.slave  <= default;
        else
            if clk'event and clk='1' then
                if (c1_nready ='0' and c2_BUSY='0') then
                    c2_op.op     <= c1_op.op;
                    c2_op.master <= c1_op.master;
                    c2_op.slave  <= c1_op.slave;
                end if;
            end if;
        end if;
    end process;

    -- selecting input value from All slaves
    c2_rdatabus <= S1_RDATABUS when (c2_op.slave=s1 and c2_op.op=read) else
                   S2_RDATABUS when (c2_op.slave=s2 and c2_op.op=read) else
                   S3_RDATABUS when (c2_op.slave=s3 and c2_op.op=read) else
                   S4_RDATABUS when (c2_op.slave=s4 and c2_op.op=read) else
                   (others=>'0');

    c2_BUSY  <=  M1_BUSY when c2_op.master=m1 and c2_op.op=read else
                 M2_BUSY when c2_op.master=m2 and c2_op.op=read else
                '0';   
    
    M1_RDATABUS <= C2_rdatabus when c2_op.master=m1 else (others=>'0');
    M2_RDATABUS <= C2_rdatabus when c2_op.master=m2 else (others=>'0');
      
    S1_BUSY <= c2_BUSY when c2_op.slave = s1 else '0';
    S2_BUSY <= c2_BUSY when c2_op.slave = s2 else '0';
    S3_BUSY <= c2_BUSY when c2_op.slave = s3 else '0';
    S4_BUSY <= c2_BUSY when c2_op.slave = s4 else '0';      


  end struct;
