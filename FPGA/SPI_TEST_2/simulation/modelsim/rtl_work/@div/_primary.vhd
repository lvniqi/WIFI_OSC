library verilog;
use verilog.vl_types.all;
entity Div is
    generic(
        N               : integer := 8
    );
    port(
        clk_in          : in     vl_logic;
        clk_div         : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of N : constant is 1;
end Div;
