library verilog;
use verilog.vl_types.all;
entity fifo_control is
    port(
        clk             : in     vl_logic;
        data            : out    vl_logic_vector(7 downto 0);
        isfull          : out    vl_logic
    );
end fifo_control;
