library verilog;
use verilog.vl_types.all;
entity shift_registerv2 is
    generic(
        IDLE            : vl_logic_vector(3 downto 0) := (Hi0, Hi0, Hi0, Hi0);
        START           : vl_logic_vector(3 downto 0) := (Hi0, Hi0, Hi0, Hi1);
        \WAIT\          : vl_logic_vector(3 downto 0) := (Hi0, Hi0, Hi1, Hi0);
        WAIT_2          : vl_logic_vector(3 downto 0) := (Hi0, Hi0, Hi1, Hi1);
        TEMP_TEMP       : vl_logic_vector(3 downto 0) := (Hi0, Hi1, Hi0, Hi0)
    );
    port(
        clk             : in     vl_logic;
        en              : in     vl_logic;
        reset           : in     vl_logic;
        data_in         : in     vl_logic_vector(31 downto 0);
        has_done        : in     vl_logic;
        data_out        : out    vl_logic_vector(7 downto 0);
        done_test       : out    vl_logic;
        done            : out    vl_logic;
        done_testv2     : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of IDLE : constant is 2;
    attribute mti_svvh_generic_type of START : constant is 2;
    attribute mti_svvh_generic_type of \WAIT\ : constant is 2;
    attribute mti_svvh_generic_type of WAIT_2 : constant is 2;
    attribute mti_svvh_generic_type of TEMP_TEMP : constant is 2;
end shift_registerv2;
