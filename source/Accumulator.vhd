----------------------------------------------------------------------------------
-- File: Accumulator.vhd
-- Created by rtlogik
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Accumulator is
    generic (g_WIDTH: Natural);                                  -- Count width
    
    port (
        i_Clk    : in  Std_Logic;                                -- Clock signal 
        i_Enable : in  Std_Logic;                                -- Counter enable signal
        i_Updown : in  Std_Logic;                                -- Up-Down count for triangle wave (=1)
        i_FTW    : in  Std_Logic_Vector(g_WIDTH-1 downto 0);     -- Frequency Tuning Word 
        --
        o_Count  : out Std_Logic_Vector(g_WIDTH-1 downto 0));    -- Counter output
end Accumulator;

architecture RTL of accumulator is

    constant c_MAX_COUNT: Unsigned(g_WIDTH-1 downto 0) := (others => '1');

    signal w_Inc    : Unsigned(g_WIDTH-1 downto 0);              -- Increment for up mode
    signal w_Inc2   : Unsigned(g_WIDTH-1 downto 0);              -- Increment for up-down mode 
    signal w_Count  : Unsigned(g_WIDTH-1 downto 0);

    signal r_Count  : Unsigned(g_WIDTH-1 downto 0) := (others => '0');

begin --======================== Architecture =========================--

    w_Inc  <= Unsigned(i_FTW);
    w_Inc2 <= Unsigned(i_FTW(g_WIDTH-2 downto 0) & '0');         -- Multiplication by 2 through left-shifting (FTW*2)
    
    --- Next-state logic ---
    COMB: process (r_Count, w_Inc, w_Inc2)
        variable v_Dir: Std_Logic := '0';                        -- To keep track of count direction
    begin
    
        if (i_Updown = '0') then  
            v_Dir := '0';
            if r_Count < (c_MAX_COUNT - w_Inc) then              -- No overloading            
                w_Count <= r_Count + w_Inc;
            else                                                 -- Overloading            
                w_Count <= w_Inc - (c_MAX_COUNT - r_Count);
            end if;
            
        elsif (i_Updown = '1') then 
            if (v_Dir = '0') then    -- Up-count
                if r_Count < (c_MAX_COUNT - w_Inc2) then         -- No overloading              
                    w_Count <= r_Count + w_Inc2;
                else                                             -- Overloading                
                    w_Count <= c_MAX_COUNT - w_Inc2 - (c_MAX_COUNT - r_Count);
                    v_Dir := '1';
                end if;
            elsif (v_Dir = '1') then  -- Down-count
                if r_Count > w_Inc2 then                         -- No overloading                  
                    w_Count <= r_Count - w_Inc2;
                else                                             -- Overloading                  
                    w_Count <= w_Inc2 - r_Count;
                    v_Dir := '0';
                end if;
            end if;
        end if;
        
    end process COMB;

    --- Register ---
    REG: process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            if i_Enable = '1' then
                r_Count <= w_Count;
            else
                r_Count <= (others => '0');
            end if;
        end if;
    end process REG;

    --- Output ---
    o_Count <= Std_Logic_Vector(r_Count);

end RTL;
