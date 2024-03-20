--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm 
	  port(
		  i_clk, i_reset  : in    std_logic;
          i_left, i_right : in    std_logic;
          o_lights_L      : out   std_logic_vector(2 downto 0);
          o_lights_R      : out   std_logic_vector(2 downto 0)
	  );
	end component;

	-- test I/O signals
	--Inputs
	signal w_clk, w_reset : std_logic := '0';
	signal w_left, w_right : std_logic := '0';
	
	--Outputs
	signal w_lights_L : std_logic_vector(2 downto 0) := "000";
	signal w_lights_R : std_logic_vector(2 downto 0) := "000";
	
	
	-- constants
	constant k_clk_period : time := 10 ns;
	
begin
	-- PORT MAPS ----------------------------------------
	
	uut: thunderbird_fsm port map (
	       i_clk => w_clk,
	       i_reset => w_reset,
	       i_left => w_left,
	       i_right => w_right,
	       o_lights_R => w_lights_R,
	       o_lights_L => w_lights_L
        );	       
	
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    
    clk_proc : process
    begin
        w_clk <= '0';
        wait for k_clk_period/2;
        w_clk <= '1';
        wait for k_clk_period/2;
    end process;
    
	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
	
	sim_proc: process
	begin
	   
	   -- sequential timing
	   w_reset <= '1';
	   wait for k_clk_period*1;
	       assert w_lights_R = "000" report "bad reset on right lights" severity failure;
	       assert w_lights_L = "000" report "bad reset on left lights" severity failure;
	   
	   w_reset <= '0';
	   wait for k_clk_period*1;
	   
	   -- Left signal is pressed and held and released in the middle of the second cycle
	   w_left <= '1'; wait for k_clk_period;
	       assert w_lights_L = "001" report "improper display on light La" severity failure;
	       wait for k_clk_period;
	       assert w_lights_L = "011" report "improper display on light Lb" severity failure;
           wait for k_clk_period;
           assert w_lights_L = "111" report "improper display on light Lc" severity failure;
           wait for k_clk_period*3;
       w_left <= '0';
       wait for k_clk_period*2;
       
       -- Right signal is pressed and held and released in the middle of the second cycle
       w_right <= '1'; wait for k_clk_period;
           assert w_lights_R = "001" report "improper display on light Ra" severity failure;
           wait for k_clk_period;
           assert w_lights_R = "011" report "improper display on light Rb" severity failure;
           wait for k_clk_period;
           assert w_lights_R = "111" report "improper display on light Rc" severity failure;
           wait for k_clk_period*3;
       w_right <= '0';
       wait for k_clk_period*2;
       
       -- Hazards are turned on when in the OFF state
       w_right <= '1'; w_left <= '1'; wait for k_clk_period;
           assert w_lights_R = "111" report "Does not turn on all right lights when hazards are displayed" severity failure;
           assert w_lights_L = "111" report "Does not turn on all left lights when hazards are displayed" severity failure;
           wait for k_clk_period;
           assert w_lights_R = "000" report "Does not turn off all right lights when hazards are displayed" severity failure;
           assert w_lights_L = "000" report "Does not turn off all left lights when hazards are displayed" severity failure;
           wait for k_clk_period;
           w_right <= '0'; w_left <= '0'; wait for k_clk_period;
           
        -- Hit right blinker while the left blinker is being displayed, should finish the left cycle before changing
        -- to hazards
        w_left <= '1'; wait for k_clk_period*2;
        w_right <= '1'; wait for k_clk_period*3;
        w_right <= '0'; w_left <= '0'; wait for k_clk_period*3;
        
        -- Hit left blinker while the right blinker is being displayed, should finish the right cycle before changing
        -- to hazards
        w_right <= '1'; wait for k_clk_period*2;
        w_left <= '1'; wait for k_clk_period*3;
        w_right <= '0'; w_left <= '0'; wait for k_clk_period*3;
           
        -- Input is chaged from left to right while left is being displayed
        w_left <= '1'; wait for k_clk_period*2;
        w_right <= '1'; w_left <= '0'; wait for k_clk_period*3;
        w_right <= '0'; w_left <= '0'; wait for k_clk_period*3;
        
        -- Input is chaged from right to left while right is being displayed
        w_right <= '1'; wait for k_clk_period*2;
        w_left <= '1'; w_right <= '0'; wait for k_clk_period*3;
        w_right <= '0'; w_left <= '0'; wait for k_clk_period*3;
        
        -- Reset is pressed while displaying left blinker
        w_left <= '1'; wait for k_clk_period*2;
        w_reset <= '1'; wait for k_clk_period*4;
        w_left <= '0'; wait for k_clk_period;
        w_reset <= '0'; wait for k_clk_period;
        
        
        -- Reset is pressed while displaying right blinker
        w_right <= '1'; wait for k_clk_period*2;
        w_reset <= '1'; wait for k_clk_period*4;
        w_right <= '0'; wait for k_clk_period;
        w_reset <= '0'; wait for k_clk_period;
        
	       
	
	   wait;
	end process;
	
	-----------------------------------------------------	
	
end;

