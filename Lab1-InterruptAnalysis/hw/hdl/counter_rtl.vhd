library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
port(
    -- Avalon interfaces signals
    Clk         : in std_logic;
    nReset      : in std_logic;

    Address     : in std_logic_vector (2 downto 0);
    ChipSelect  : in std_logic;

    Read        : in std_logic;
    Write       : in std_logic;

    ReadData    : out std_logic_vector (31 downto 0);
    WriteData   : in std_logic_vector (31 downto 0);

    -- Interrutp line
    IRQ         : out std_logic
);
end counter;

architecture rtl of counter is
    -- signals for register access
    signal reg_count            : unsigned(31 downto 0);
    signal reg_reload_value     : unsigned(31 downto 0);
    signal reg_control          : std_logic_vector(1 downto 0);
    signal reg_status           : std_logic_vector(1 downto 0);
    -- internal states
    signal counter_running      : boolean := false;

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
    -- always update current state
    reg_status(RUNNING_FLAG) <= '1' when counter_running else '0';

    -- Process to Write to register
    pRegWr: process(Clk, nReset)
    begin
        if nReset = '0' then
            counter_running <= false;
            reg_count <= (others => '1');
            reg_reload_value <= (others => '1');
            reg_control <= (others => '0');
            reg_status(IRQ_FLAG) <= '0';
        elsif rising_edge(Clk) then
            -- counter logic and interrupt handling
            if counter_running then
                if reg_count = 0 then
                    reg_count <= reg_reload_value;
                    reg_status(IRQ_FLAG) <= '1';
                    if reg_control(ONE_SHOT) = '1' then
                        counter_running <= false;
                    end if;
                else
                    reg_count <= reg_count - 1;
                end if;
            end if;
            -- Write access logic
            if ChipSelect = '1' and Write = '1' then
                case Address(2 downto 0) is
                    when ADDR_COUNT => null;
                    when ADDR_RELOAD_VALUE => reg_reload_value <= unsigned(WriteData);
                    when ADDR_CONTROL => reg_control <= WriteData(1 downto 0);
                    when ADDR_STATUS => reg_status(IRQ_FLAG) <= reg_status(IRQ_FLAG) and not WriteData(IRQ_FLAG);
                    when ADDR_CMD_START => counter_running <= true;
                    when ADDR_CMD_STOP => counter_running <= false;
                    when ADDR_CMD_RESET => reg_count <= reg_reload_value; -- writing to reset preserves counter state
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    -- Read Process from registers
    pRegRd: process(Clk)
    begin
        if rising_edge(Clk) then
            -- default value
            ReadData <= (others => '0');
            -- read registers
            if ChipSelect = '1' and Read = '1' then
                case Address(2 downto 0) is
                    when ADDR_COUNT => ReadData <= std_logic_vector(reg_count);
                    when ADDR_RELOAD_VALUE => ReadData <= std_logic_vector(reg_reload_value);
                    when ADDR_CONTROL => ReadData(1 downto 0) <= reg_control;
                    when ADDR_STATUS => ReadData(1 downto 0) <= reg_status;
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    -- Interrupt signaling
    pInt: process(Clk, nReset)
    begin
        if nReset = '0' then
            IRQ <= '0';
        elsif rising_edge(Clk) then
            IRQ <= '0';
            if (reg_control(IRQ_MASK) and reg_status(IRQ_FLAG)) /= '0' then
                IRQ <= '1';
            end if;
        end if;
    end process;

end rtl;
