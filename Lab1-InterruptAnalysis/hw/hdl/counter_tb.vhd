library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_tb is
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

stimulus: process
    -- Simulate Avalon write
    procedure AvalonWrite(
        constant addr: std_logic_vector;
        constant data: unsigned) is
    begin
        wait until rising_edge(tb_clk);
        Address <= addr;
        ChipSelect <= '1';
        Read <= '0';
        Write <= '1';
        WriteData <= std_logic_vector(to_unsigned(0, 32-data'length) & data);
        wait for CLK_PERIOD;
        WriteData <= (others => '0');
        Address <= (others => '0');
        ChipSelect <= '0';
        Write <= '0';
    end procedure AvalonWrite;

    procedure AvalonWrite(
        constant addr: std_logic_vector;
        constant data: integer) is
    begin
        AvalonWrite(addr, to_unsigned(data, WriteData'length));
    end procedure AvalonWrite;

    -- Simulate Avalon read
    procedure AvalonRead(
        constant addr: std_logic_vector) is
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
        report "[PASSED]" & LF;
        -- signal simulation end and wait
        sim_ended <= '1';
        wait;
    end procedure TEST_END;

    procedure CHECK_EQUAL(
        constant A: std_logic_vector;
        constant B: unsigned;
        constant msg: string) is
    begin
        if A /= std_logic_vector(B) then
            assert false report "[FAILED]: " & msg severity failure;
        end if;
    end CHECK_EQUAL;

    procedure CHECK_EQUAL(
        constant A: std_logic_vector;
        constant B: integer;
        constant msg: string) is
    begin
        CHECK_EQUAL(A, to_unsigned(B, A'length), msg);
    end CHECK_EQUAL;

begin -- TEST PROCESS
    report "[START TESTBENCH]" & LF;
    TEST_RESET;

    AvalonWrite(ADDR_RELOAD_VALUE, "1010");
    AvalonWrite(ADDR_RELOAD_VALUE, 31);
    AvalonRead(ADDR_RELOAD_VALUE);
    CHECK_EQUAL(ReadData, 31, "Avalon read /= write");

    --CHECK_EQUAL("1", "0", "FOO");
    CHECK_EQUAL("101010", 42, "Bar");

    AvalonWrite(ADDR_CMD_START, to_unsigned(0, 32));
    wait for 4*CLK_PERIOD;
    AvalonWrite(ADDR_CMD_STOP, to_unsigned(0, 32));
    wait for 4*CLK_PERIOD;

    TEST_END;
end process;

end tb;
