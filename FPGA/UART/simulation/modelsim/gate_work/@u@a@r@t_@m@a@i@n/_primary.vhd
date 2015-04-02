library verilog;
use verilog.vl_types.all;
entity UART_MAIN is
    port(
        TXD             : out    vl_logic;
        CLK             : in     vl_logic;
        RXD             : in     vl_logic;
        T_READY         : out    vl_logic;
        bclk            : out    vl_logic;
        RXD_BUF         : out    vl_logic_vector(7 downto 0)
    );
end UART_MAIN;
