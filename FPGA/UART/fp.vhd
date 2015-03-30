LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fre is
--generic(cnt:integer:=8);
   port
     (clk,reset:in std_logic;
          bclk:buffer std_logic);
end fre;

architecture  Behavioral of fre is
begin
   process(clk,reset)
   variable cnt:integer;
   --variable cnt2:integer:=0;
      begin
      if(reset='1') then
         cnt:=0;
         bclk<='0';
       elsif(clk'event and clk='1')  then
        if(cnt>=7) then
           bclk<=not bclk;
           cnt:=0;
        else
           cnt:=cnt+1;
        end if;
      end if;
end process;
end Behavioral;
                    
                    
                    
                    
           
           
                     
           
              
   
   