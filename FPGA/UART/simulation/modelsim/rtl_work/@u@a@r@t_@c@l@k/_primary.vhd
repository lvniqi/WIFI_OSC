library verilog;
use verilog.vl_types.all;
entity UART_CLK is
    port(
        clk             : in     vl_logic;
        bclk            : out    vl_logic
    );
end UART_CLK;
