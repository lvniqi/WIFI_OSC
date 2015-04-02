library verilog;
use verilog.vl_types.all;
entity shift_register is
    port(
        clk             : in     vl_logic;
        data_in         : in     vl_logic_vector(7 downto 0);
        data_out        : out    vl_logic_vector(31 downto 0);
        done            : out    vl_logic
    );
end shift_register;
