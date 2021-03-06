library verilog;
use verilog.vl_types.all;
entity FPGA2AR9331 is
    generic(
        IDLE            : vl_logic_vector(4 downto 0) := (Hi0, Hi0, Hi0, Hi0, Hi0);
        SEND_START      : vl_logic_vector(4 downto 0) := (Hi0, Hi0, Hi0, Hi0, Hi1);
        SEND_ING_0      : vl_logic_vector(4 downto 0) := (Hi0, Hi0, Hi0, Hi1, Hi0);
        SEND_ING_1      : vl_logic_vector(4 downto 0) := (Hi0, Hi0, Hi0, Hi1, Hi1);
        SEND_ING_2      : vl_logic_vector(4 downto 0) := (Hi0, Hi0, Hi1, Hi0, Hi0);
        SEND_END        : vl_logic_vector(4 downto 0) := (Hi0, Hi0, Hi1, Hi0, Hi1);
        DELAY_1         : vl_logic_vector(4 downto 0) := (Hi0, Hi0, Hi1, Hi1, Hi0);
        DELAY_2         : vl_logic_vector(4 downto 0) := (Hi0, Hi0, Hi1, Hi1, Hi1);
        DELAY_3         : vl_logic_vector(4 downto 0) := (Hi0, Hi1, Hi0, Hi0, Hi0)
    );
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        en              : in     vl_logic;
        ack             : in     vl_logic;
        clk_out         : out    vl_logic;
        data_out        : out    vl_logic_vector(7 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of IDLE : constant is 2;
    attribute mti_svvh_generic_type of SEND_START : constant is 2;
    attribute mti_svvh_generic_type of SEND_ING_0 : constant is 2;
    attribute mti_svvh_generic_type of SEND_ING_1 : constant is 2;
    attribute mti_svvh_generic_type of SEND_ING_2 : constant is 2;
    attribute mti_svvh_generic_type of SEND_END : constant is 2;
    attribute mti_svvh_generic_type of DELAY_1 : constant is 2;
    attribute mti_svvh_generic_type of DELAY_2 : constant is 2;
    attribute mti_svvh_generic_type of DELAY_3 : constant is 2;
end FPGA2AR9331;
