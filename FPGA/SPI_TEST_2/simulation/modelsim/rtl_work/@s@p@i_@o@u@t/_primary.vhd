library verilog;
use verilog.vl_types.all;
entity SPI_OUT is
    generic(
        IDLE            : vl_logic_vector(1 downto 0) := (Hi0, Hi0);
        SEND            : vl_logic_vector(1 downto 0) := (Hi0, Hi1);
        SEND_n          : vl_logic_vector(1 downto 0) := (Hi1, Hi0);
        \END\           : vl_logic_vector(1 downto 0) := (Hi1, Hi1)
    );
    port(
        clk             : in     vl_logic;
        data_in         : in     vl_logic_vector(15 downto 0);
        rst_n           : in     vl_logic;
        en              : in     vl_logic;
        sclk            : out    vl_logic;
        dout            : out    vl_logic;
        sync_n          : out    vl_logic;
        isIDLE          : out    vl_logic;
        isEND           : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of IDLE : constant is 2;
    attribute mti_svvh_generic_type of SEND : constant is 2;
    attribute mti_svvh_generic_type of SEND_n : constant is 2;
    attribute mti_svvh_generic_type of \END\ : constant is 2;
end SPI_OUT;
