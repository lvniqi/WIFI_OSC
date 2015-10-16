library verilog;
use verilog.vl_types.all;
entity Divs_2 is
    generic(
        N               : integer := 2
    );
    port(
        clk             : in     vl_logic;
        clk_div2        : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of N : constant is 1;
end Divs_2;
