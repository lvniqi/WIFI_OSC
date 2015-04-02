LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART_CLK_BUILD is
--generic(cnt:integer:=8);
   port
     (clk:in std_logic;
          bclk:buffer std_logic);
end UART_CLK_BUILD;

architecture  Behavioral of UART_CLK_BUILD is
begin
   process(clk)
   variable cnt:integer;
   --variable cnt2:integer:=0;
      begin
       if(clk'event and clk='1')  then
        if(cnt>=7) then
           bclk<=not bclk;
           cnt:=0;
        else
           cnt:=cnt+1;
        end if;
      end if;
end process;
end Behavioral;
                    
                    
                    
                    
           
           
                     
           
              
   
   