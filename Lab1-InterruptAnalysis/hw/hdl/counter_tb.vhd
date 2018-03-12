library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity counter_tb is
    generic (runner_cfg : string);
end counter_tb;

architecture tb of counter_tb is
    signal Clk           : std_logic;
    signal nReset        : std_logic;
    signal Address       : std_logic_vector (2 downto 0);
    signal ChipSelect    : std_logic;
    signal Read          : std_logic;
    signal Write         : std_logic;
    signal ReadData      : std_logic_vector (31 downto 0);
    signal WriteData     : std_logic_vector (31 downto 0);
    signal IRQ           : std_logic;

    constant CLK_PERIOD : time := 20 ns; -- EDIT Put right period here
    signal tb_clk : std_logic := '0';
    signal sim_ended : std_logic := '0';

    -- TODO: put in a package
    -- register address layout
    constant ADDR_COUNT         : std_logic_vector(2 downto 0) := "000";
    constant ADDR_RELOAD_VALUE  : std_logic_vector(2 downto 0) := "001";
    constant ADDR_CONTROL       : std_logic_vector(2 downto 0) := "010";
    constant ADDR_STATUS        : std_logic_vector(2 downto 0) := "011";
    constant ADDR_CMD_START     : std_logic_vector(2 downto 0) := "100";
    constant ADDR_CMD_STOP      : std_logic_vector(2 downto 0) := "101";
    constant ADDR_CMD_RESET     : std_logic_vector(2 downto 0) := "110";
    -- control register bit positions
    constant IRQ_MASK           : integer := 0;
    constant ONE_SHOT           : integer := 1;
    -- status register bit positions
    constant IRQ_FLAG           : integer := 0;
    constant RUNNING_FLAG       : integer := 1;
begin
    dut : entity work.counter
    port map (Clk           => Clk,
              nReset        => nReset,
              Address       => Address,
              ChipSelect    => ChipSelect,
              Read          => Read,
              Write         => Write,
              ReadData      => ReadData,
              WriteData     => WriteData,
              IRQ           => IRQ);

    -- Clock generation
    tb_clk <= not tb_clk after CLK_PERIOD/2 when sim_ended /= '1' else '0';
    Clk <= tb_clk;

test_runner: process
    -- Simulate Avalon write
    procedure AvalonWrite(
        constant addr: std_logic_vector(2 downto 0);
        constant data: unsigned(31 downto 0)) is
    begin
        wait until rising_edge(tb_clk);
        Address <= addr;
        ChipSelect <= '1';
        Read <= '0';
        Write <= '1';
        WriteData <= std_logic_vector(data);
        wait for CLK_PERIOD;
        WriteData <= (others => '0');
        Address <= (others => '0');
        ChipSelect <= '0';
        Write <= '0';
    end procedure AvalonWrite;

    -- Simulate Avalon read
    procedure AvalonRead(
        constant addr: std_logic_vector(2 downto 0)) is
    begin
        wait until rising_edge(tb_clk);
        Address <= addr;
        ChipSelect <= '1';
        Read <= '1';
        Write <= '0';
        wait for CLK_PERIOD;
        Address <= (others => '0');
        ChipSelect <= '0';
        Read <= '0';
    end procedure AvalonRead;

    -- Reset UUT
    procedure TEST_RESET is
    begin
        -- init values
        Address <= (others => '0');
        ChipSelect <= '0';
        Read <= '0';
        Write <= '0';
        WriteData <= (others => '0');

        -- RESET generation
        wait for CLK_PERIOD/4;
        nReset <= '0';
        wait for CLK_PERIOD/4;
        nReset <= '1';
        wait until rising_edge(tb_clk);
    end procedure TEST_RESET;

    -- Reset UUT
    procedure TEST_END is
    begin
        -- signal simulation end and wait
        sim_ended <= '1';
    end procedure TEST_END;

begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
        TEST_RESET;
        if run("Test to_string for integer") then
            check_equal(to_string(17), "17");
        elsif run("Test to_string for boolean") then
            check_equal(to_string(true), "true");
        elsif run("Test Avalon read/write") then
            AvalonWrite(ADDR_RELOAD_VALUE, to_unsigned(3, 32));
            AvalonRead(ADDR_RELOAD_VALUE);
            check_equal(unsigned(ReadData), to_unsigned(3, 32));
        end if;
    end loop;

    TEST_END;
    test_runner_cleanup(runner);
end process;

end tb;
