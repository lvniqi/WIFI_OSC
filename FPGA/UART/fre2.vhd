LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fre2 is
   port
     (clk,reset:in std_logic;
          blk2:buffer std_logic);
end fre2;

architecture  Behavioral of fre2 is
begin
   process(clk,reset)
   variable cnt:integer;
   --variable cnt2:integer:=0;
      begin
      if(reset='1') then
         cnt:=0;
         blk2<='0';
       elsif(clk'event and clk='1')  then
        if(cnt>=500) then
           blk2<='1';
           cnt:=0;
        else
           blk2<='0';
           cnt:=cnt+1;
        end if;
      end if;
end process;
end Behavioral;
                    
                    
                    
                    
           
           
                     
           
              
   
   