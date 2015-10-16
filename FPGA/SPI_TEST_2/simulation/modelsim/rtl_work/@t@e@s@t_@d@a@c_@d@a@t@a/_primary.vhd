library verilog;
use verilog.vl_types.all;
entity TEST_DAC_DATA is
    port(
        pos             : in     vl_logic_vector(2 downto 0);
        data            : out    vl_logic_vector(11 downto 0)
    );
end TEST_DAC_DATA;
