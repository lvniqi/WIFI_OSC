LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity uarter is
generic(T_len:integer:=8);
   port
     (
          bclk,reset,T_com:in std_logic;
          T_buf:in std_logic_vector(7 downto 0);
          T,T_done:out std_logic);
end uarter;
architecture  Behavioral of uarter is
  type states is(T_IDLE,T_START,T_WAIT,T_SHIFT,T_STOP);
  signal state:states:=T_IDLE;
  --signal tt:std_logic_vector(7 downto 0):="00001111";
  --signal cnt:integer:=0;
begin 
   process(bclk,reset,T_com)
    --variable TT:std_logic_vector(7 downto 0):="10000000"; --
    variable xcnt16:std_logic_vector(4 downto 0):="00000"; --
	variable xbitcnt:integer:=0;--wait 16 perido YI WEI   
	variable txds:std_logic;-- save BIT
   begin 
   if(reset='1')  then
        state<=T_IDLE;
        T_done<='0';
        txds:='1';
   --end if;
   elsif rising_edge(bclk) then
   case state is
   when  T_IDLE=>
      if(T_com='1') then
           state<=T_START;
           T_done<='0';
      else 
           state<=T_IDLE;
      end if;
   when  T_START=>
         if(xcnt16>="00011") then 
            state<=T_WAIT;
            xcnt16:="00000";
          else
            xcnt16:=xcnt16+1;
            txds:='0';
            state<=T_START;
           end if;
    when   T_WAIT=>  
           if(xcnt16>="01100" ) then
               if( xbitcnt= T_len) then
                  state<=T_STOP;
                  xbitcnt:=0;
               else
                  state<=T_SHIFT;
               end if;
               xcnt16:="00000";
           else
               xcnt16:=xcnt16+1;
               state<=T_WAIT;
           end if;
    when   T_SHIFT=>
             txds:=T_buf(xbitcnt);
			 --txds:=tt(xbitcnt);
             --txds:=T_buf(xbitcnt);
             xbitcnt:=xbitcnt+1;
             state<=T_WAIT;
    when   T_STOP=>
             if(xcnt16>="01111") then
                 if T_com='0'  then
                     state<=T_IDLE;
                     xcnt16:="00000";
                  else
                     xcnt16:=xcnt16;
                     state<=T_STOP;
                  end if;
                  T_done<='1'; 
              else
                  xcnt16:=xcnt16+1;
                  txds:='1';  
                  state<=T_STOP;
              end if;
     when others=> state<=T_IDLE;
 end case;
 end if;
 T<=txds;
end process;
end Behavioral;
                    
                    
                    
                    
           
           
                     
           
              
   
   