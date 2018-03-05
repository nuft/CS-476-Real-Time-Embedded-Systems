library ieee;
use ieee.std_logic_1164.all;

ENTITY ParallelPort IS
   PORT(
--   Avalon interfaces signals
      Clk 			: IN std_logic;
      nReset 		: IN std_logic;

      Address 		: IN std_logic_vector (2 DOWNTO 0);
      ChipSelect	: IN std_logic;

      Read 			: IN std_logic;
      Write 		: IN std_logic;

      ReadData 		: OUT std_logic_vector (7 DOWNTO 0);
      WriteData		: IN std_logic_vector (7 DOWNTO 0);
--   Parallel Port external interface
      ParPort		: INOUT std_logic_vector (7 DOWNTO 0)
   );
End ParallelPort;

ARCHITECTURE comp OF ParallelPort IS
 --   signals for register access
   signal   iRegDir	 	:  std_logic_vector (7 DOWNTO 0);
   signal   iRegPort	:  std_logic_vector (7 DOWNTO 0);
   signal   iRegPin 	:  std_logic_vector (7 DOWNTO 0);
BEGIN
	pPort: process(iRegDir, iRegPort)
		begin
			for i in 0 to 7 loop
				if iRegDir(i) = '1' then
					ParPort(i) <= iRegPort(i);
				else
					ParPort(i) <= 'Z';
				end if;
			end loop;
		end process;

	-- Parallel Port Input value
	iRegPin <= ParPort;

	-- Process to Write to register
    pRegWr: process(Clk, nReset)
        begin
            if nReset = '0' then
                iRegDir <= (others => '0'); -- Input by default

            elsif rising_edge(Clk) then
                if ChipSelect = '1' and Write = '1' then -- Write cycle
                    case Address(2 downto 0) is
                        when "000" => iRegDir <= WriteData ;
                        when "010" => iRegPort <= WriteData;
                        when "011" => iRegPort <= iRegPort OR WriteData;
                        when "100" => iRegPort <= iRegPort AND NOT WriteData;
                        when others => null;
                    end case;
                end if;
            end if;
        end process;

    -- Read Process to registers
    pRegRd: process(Clk)
        begin
            if rising_edge(Clk) then
                ReadData <= (others => '0'); -- default value
                if ChipSelect = '1' and Read = '1' then -- Read cycle
                    case Address(2 downto 0) is
                        when "000" => ReadData <= iRegDir ;
                        when "001" => ReadData <= iRegPin;
                        when "010" => ReadData <= iRegPort;
                        when others => null;
                    end case;
                end if;
            end if;
    end process;

END comp;
