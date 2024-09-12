library ieee;
use ieee.std_logic_1164.all;

entity pong_top_st is
port(
    clk, reset: in std_logic;
    btn: in std_logic_vector(4 downto 0);
    hsync, vsync: out std_logic;
    rgb_top: out std_logic_vector(2 downto 0);
    vga_pixel_tick: out std_logic;
    blank: out std_logic;
    comp_sync: out std_logic;
    debug: out std_logic_vector(2 downto 0)
);
end pong_top_st;

architecture arch of pong_top_st is
    signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
    signal video_on: std_logic;
    signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);
    signal pong_graph_rgb: std_logic_vector(2 downto 0);
    signal rgb: std_logic_vector(2 downto 0);
    signal p_tick: std_logic;
    signal hit_cnt: std_logic_vector(2 downto 0);
    signal hit_cnter_rgb:std_logic_vector(2 downto 0);
    signal sq_hit_cnter_on: std_logic;

    begin
-- instantiate VGA sync
    vga_sync_unit: entity work.vga_sync
        port map(clk=>clk, reset=>reset, hsync=>hsync,
            vsync=>vsync, comp_sync=>comp_sync,
            video_on=>video_on, p_tick=>p_tick,
            pixel_x=>pixel_x, pixel_y=>pixel_y);
-- instantiate pixel generation circuit
    pong_grf_st_unit: entity work.pong_graph_st(game_arch)
        port map(clk=>clk, reset=>reset, btn=>btn,
            video_on=>video_on, pixel_x=>pixel_x,
            pixel_y=>pixel_y, hit_cnt=>hit_cnt,
            graph_rgb=>pong_graph_rgb);
    
        -- instantiate pixel generation circuit for counter_disp
    counter_disp_unit: entity work.counter_disp
        port map(pixel_x=>pixel_x, pixel_y=>pixel_y,
            hit_cnt=>hit_cnt, sq_hit_cnter_on_output=> sq_hit_cnter_on,
            graph_rgb=>hit_cnter_rgb);

    -- when the current pixel is located within the “sq_hit_cnter�? area,
    -- assign ‘hit_cnter_rgb’ to final ‘rgb’, otherwise assign
    --- ‘pong_graph_rgb’ to the final “rgb�?;
    rgb_next <= hit_cnter_rgb when sq_hit_cnter_on = '1' else
                pong_graph_rgb;


    vga_pixel_tick <= p_tick;

-- Set the high order bits of the video DAC for each
-- of the three colors
    rgb_top <= rgb;
-- rgb buffer, graph_rgb is routed to the output through
-- an output buffer -- loaded when p_tick = ?1?.
-- This syncs. rgb output with buffered hsync/vsync sig.
    process (clk)
        begin
        if (clk'event and clk = '1') then
            if (p_tick = '1') then
                rgb_reg <= rgb_next;
            end if;
        end if;
    end process;
    rgb <= rgb_reg;
    blank <= video_on;

    debug <= hit_cnt;
end arch;


    