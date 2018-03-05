-- Testbench automatically generated online
-- at http://vhdl.lapinoo.net
-- Generation date : 27.10.2017 14:24:40 GMT

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_ParallelPort is
end tb_ParallelPort;

architecture test of tb_ParallelPort is
    signal Clk        : std_logic;
    signal nReset     : std_logic;
    signal Address    : std_logic_vector (2 downto 0);
    signal ChipSelect : std_logic;
    signal Read       : std_logic;
    signal Write      : std_logic;
    signal ReadData   : std_logic_vector (7 downto 0);
    signal WriteData  : std_logic_vector (7 downto 0);
    signal ParPort    : std_logic_vector (7 downto 0);

    constant CLK_PERIOD : time := 1 ns;
    signal tb_Clk : std_logic := '0';
    signal sim_finished : boolean := false;

begin

    dut : entity work.ParallelPort
    port map (Clk        => Clk,
              nReset     => nReset,
              Address    => Address,
              ChipSelect => ChipSelect,
              Read       => Read,
              Write      => Write,
              ReadData   => ReadData,
              WriteData  => WriteData,
              ParPort    => ParPort);

    -- Clock generation
    tb_Clk <= not tb_Clk after CLK_PERIOD/2 when not sim_finished else '0';

    -- EDIT: Check that Clk is really your main clock signal
    Clk <= tb_Clk;

    simulation: process
        -- Reset generation
        procedure async_reset is
        begin
            wait until rising_edge(tb_Clk);
            wait for CLK_PERIOD / 4;
            nReset <= '0';
            wait for CLK_PERIOD / 2;
            nReset <= '1';
        end procedure async_reset;

        -- Simulate Avalon read
        procedure avalon_read(
            addr    : IN std_logic_vector(2 DOWNTO 0);
            data    : OUT std_logic_vector(7 DOWNTO 0)) is
        begin
            Address <= addr;
            ChipSelect <= '1';
            Read <= '1';
            Write <= '0';
            wait until rising_edge(tb_Clk);
            -- 1 wait
            wait until rising_edge(tb_Clk);
            data := ReadData;
        end procedure avalon_read;

        -- Simulate Avalon write
        procedure avalon_write(
            addr    : IN std_logic_vector(2 DOWNTO 0);
            data    : IN std_logic_vector(7 DOWNTO 0)) is
        begin
            wait until rising_edge(tb_Clk);
            Address <= addr;
            ChipSelect <= '1';
            Read <= '0';
            Write <= '1';
            WriteData <= data;
            wait until rising_edge(tb_Clk);
        end procedure avalon_write;

        -- to string functions
        function to_bstring(sl : std_logic) return string is
            variable sl_str_v : string(1 to 3);  -- std_logic image with quotes around
        begin
            sl_str_v := std_logic'image(sl);
            return "" & sl_str_v(2);  -- "" & character to get string
        end function;

        function to_bstring(slv : std_logic_vector) return string is
            alias    slv_norm : std_logic_vector(1 to slv'length) is slv;
            variable sl_str_v : string(1 to 1);  -- String of std_logic
            variable res_v    : string(1 to slv'length);
        begin
            for idx in slv_norm'range loop
                sl_str_v := to_bstring(slv_norm(idx));
                res_v(idx) := sl_str_v(1);
            end loop;
            return res_v;
        end function;

        variable res : std_logic_vector(7 DOWNTO 0);
    begin
        -- EDIT Adapt initialization as needed
        Address <= (others => '0');
        ChipSelect <= '0';
        Read <= '0';
        Write <= '0';
        WriteData <= (others => '0');

        -- Reset generation
        async_reset;

        avalon_write("000", "11111111"); -- write Dir
        avalon_write("010", "11111111"); -- write Port

        avalon_read("001", res); -- read Pin

        report "RegPin = " & to_bstring(res);
        report "RegPin = " & integer'image(to_integer(unsigned(res)));

        -- Stop the clock and hence terminate the simulation
        sim_finished <= true;
        report "DONE" & LF;
        wait;
    end process;

end test;
