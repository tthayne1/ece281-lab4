library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;
architecture top_basys3_arch of top_basys3 is
    -- signal declarations
    signal w_slow_clk   : std_logic;
    signal w_clk_reset  : std_logic;
    signal w_fsm_reset  : std_logic;
    signal w_floor1     : std_logic_vector(3 downto 0);
    signal w_floor2     : std_logic_vector(3 downto 0);
    signal w_tdm_data   : std_logic_vector(3 downto 0);
    signal w_tdm_sel    : std_logic_vector(3 downto 0);
    constant k_F        : std_logic_vector(3 downto 0) := x"F";
  
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4);
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC;
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 2	);
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;
                o_clk    : out std_logic
        );
    end component clock_divider;
	
begin
	-- PORT MAPS ----------------------------------------
    clkdiv_inst : clock_divider
        generic map ( k_DIV => 25000000 )
        port map (
            i_clk   => clk,
            i_reset => w_clk_reset,
            o_clk   => w_slow_clk
        );
    fsm1_inst : elevator_controller_fsm
        port map (
            i_clk      => w_slow_clk,
            i_reset    => w_fsm_reset,
            is_stopped => sw(0),
            go_up_down => sw(1),
            o_floor    => w_floor1
        );
    fsm2_inst : elevator_controller_fsm
        port map (
            i_clk      => w_slow_clk,
            i_reset    => w_fsm_reset,
            is_stopped => sw(14),
            go_up_down => sw(15),
            o_floor    => w_floor2
        );
    tdm_inst : TDM4
        generic map ( k_WIDTH => 4 )
        port map (
            i_clk   => clk,
            i_reset => btnU,
            i_D3    => k_F,
            i_D2    => w_floor2,
            i_D1    => k_F,
            i_D0    => w_floor1,
            o_data  => w_tdm_data,
            o_sel   => w_tdm_sel
        );
    seg_inst : sevenseg_decoder
        port map (
            i_Hex   => w_tdm_data,
            o_seg_n => seg
        );
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
    led(15)          <= w_slow_clk;
    led(14 downto 0) <= (others => '0');
	
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	-- reset signals
    w_clk_reset <= btnL or btnU;
    w_fsm_reset <= btnR or btnU;

    an <= w_tdm_sel;
	
end top_basys3_arch;