LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART_RXD is
generic(R_len:integer:=8);
   port
     (
          bclk,rst_n,R:in std_logic;
          R_buf:out std_logic_vector(7 downto 0);
          R_ready:out std_logic);
end UART_RXD;
architecture  Behavioral of UART_RXD is
  type states is(R_START,R_CENTER,R_WAIT,R_SAMPLE,R_STOP);
  signal state:states:=R_START;
begin 
 PRO2:process(bclk,rst_n,R)
    variable xcnt16:std_logic_vector(4 downto 0):="00000"; --
	variable xbitcnt:integer:=0;--wait 16 perido YI WEI   
	variable R_bufs:std_logic_vector(7 downto 0);-- save BIT
   begin 
   if(rst_n='0')  then
        state<=R_START;
        --RXD_SYNC='1';
        xcnt16:="00000";
        --txds:='1';
   --end if;
   elsif rising_edge(bclk) then
   case state is
   when  R_START=>
      if(R='0') then
           state<=R_CENTER;
           R_ready<='0';
           xbitcnt:=0;
           --R_done<='0';
      else 
           state<=R_START;
            R_ready<='0';
      end if;
   when  R_CENTER=>
         if(R='0')then 
				if(xcnt16>="00100") then
					xcnt16:="00000";
					state<=R_WAIT;
            --txds:='0';
				else
					xcnt16:=xcnt16+1;
					state<=R_CENTER;
				end if;
			else
           state<=R_START;
		  end if;
    when   R_WAIT=>  
		if(xcnt16>="01100" ) then
			if(xbitcnt=R_len) then
				R_buf<=R_bufs;--(7 downto 0);
				state<=R_STOP;
				--xbitcnt:=0;
		  else
				state<=R_SAMPLE;
			end if;
		  xcnt16:="00000";
		else
			xcnt16:=xcnt16+1;
			state<=R_WAIT;
		end if;
    when   R_SAMPLE=>
             --txds:=R_buf(xbitcnt);
             R_bufs(xbitcnt):=R;
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

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART_TXD is
generic(T_len:integer:=8);
   port
     (
          bclk,rst_n,T_com:in std_logic;
          T_buf:in std_logic_vector(7 downto 0);
          T,T_done:out std_logic);
end UART_TXD;
architecture  Behavioral of UART_TXD is
  type states is(T_IDLE,T_START,T_WAIT,T_SHIFT,T_STOP);
  signal state:states:=T_IDLE;
  --signal tt:std_logic_vector(7 downto 0):="00001111";
  --signal cnt:integer:=0;
begin 
   process(bclk,rst_n,T_com)
    --variable TT:std_logic_vector(7 downto 0):="10000000"; --
    variable xcnt16:std_logic_vector(4 downto 0):="00000"; --
	variable xbitcnt:integer:=0;--wait 16 perido YI WEI   
	variable txds:std_logic;-- save BIT
   begin 
   if(rst_n='0')  then
        state<=T_IDLE;
        T_done<='0';
        txds:='1';
   --end if;
   elsif rising_edge(bclk) then
   case state is
   when  T_IDLE=>
		txds:='1';
		T_done <='1';
      if(T_com='1') then
           T_done<='0';
           state<=T_START;
      else 
           state<=T_IDLE;
      end if;
   when  T_START=>
         if(xcnt16>="00111") then 
            xcnt16:="00000";
				state<=T_WAIT;
          else
            xcnt16:=xcnt16+1;
            txds:='0';
            state<=T_START;
           end if;
    when   T_WAIT=>  
           if(xcnt16>="01011" ) then
					xcnt16:="00000";
               if( xbitcnt= T_len) then
                  xbitcnt:=0;
						state<=T_STOP;
               else
                  state<=T_SHIFT;
               end if;
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
             if(xcnt16>="11000") then
					T_done<='1'; 
					if T_com='0'  then
						xcnt16:="00000";
						state<=T_IDLE;
					else
						xcnt16:=xcnt16;
						state<=T_STOP;
					end if;
                  
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
                    