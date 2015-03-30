LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity uarter_r is
generic(R_len:integer:=8);
   port
     (
          bclk,reset,R:in std_logic;
          R_buf:out std_logic_vector(7 downto 0);
          R_ready:out std_logic);
end uarter_r;
architecture  Behavioral of uarter_r is
  type states is(R_START,R_CENTER,R_WAIT,R_SAMPLE,R_STOP);
  signal state:states:=R_START;
  signal R_SYNC:std_logic;
begin 
 PRO1:process(R)
   begin
     if R='1' then
         R_SYNC<='0';
     else
         R_SYNC<='1';
      end if;
 END process PRO1;
 PRO2:process(bclk,reset,R)
    variable xcnt16:std_logic_vector(3 downto 0):="0000"; --
	variable xbitcnt:integer:=0;--wait 16 perido YI WEI   
	variable R_bufs:std_logic_vector(7 downto 0);-- save BIT
   begin 
   if(reset='0')  then
        state<=R_START;
        --RXD_SYNC='1';
        xcnt16:="0000";
        --txds:='1';
   --end if;
   elsif rising_edge(bclk) then
   case state is
   when  R_START=>
      if(R_SYNC='0') then
           state<=R_CENTER;
           R_ready<='0';
           xbitcnt:=0;
           --R_done<='0';
      else 
           state<=R_START;
            R_ready<='0';
      end if;
   when  R_CENTER=>
         if(R_SYNC='0')then 
              if(xcnt16>="0100") then
            state<=R_WAIT;
            xcnt16:="0000";
            --txds:='0';
          else
            xcnt16:=xcnt16+1;
            state<=R_CENTER;
           end if;
           else
           state<=R_START;
           end if;
    when   R_WAIT=>  
           if(xcnt16="1100" ) then
              if(xbitcnt=R_len) then
				R_buf<=R_bufs;--(7 downto 0);
				state<=R_STOP;
				--xbitcnt:=0;
			  else
				state<=R_SAMPLE;
              end if;
              xcnt16:="0000";
           else
               xcnt16:=xcnt16+1;
               state<=R_WAIT;
           end if;
    when   R_SAMPLE=>
             --txds:=R_buf(xbitcnt);
             R_bufs(xbitcnt):=R_SYNC;
             xbitcnt:=xbitcnt+1;
             state<=R_WAIT;
    when   R_STOP=>
             R_ready<='1';
             state<=R_START;
     when others=> state<=R_START;
 end case;
 end if;
end process PRO2;
end Behavioral;
                    
                    
                    
                    
           
           
                     
           
              
   
   