library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- btn connected to up/down pushbuttons for now but
-- eventually will get data from UART

entity pong_graph_st is
port(
    clk, reset: in std_logic;
    btn: in std_logic_vector(4 downto 0);
    video_on: in std_logic;
    pixel_x, pixel_y: in std_logic_vector(9 downto 0);
    graph_rgb: out std_logic_vector(2 downto 0);
    hit_cnt: out std_logic_vector(2 downto 0)
);
end pong_graph_st;

architecture game_arch of pong_graph_st is
    -- Signal used to control speed of ast1 and how
    -- often pushbuttons are checked for paddle movement.
    type state_type is (idle, contact);
    signal hit_state_reg, hit_state_next: state_type;
    signal refr_tick: std_logic;
    signal ball1_hit: boolean;
    signal ball2_hit: boolean;
    signal ball3_hit: boolean;
    -- x, y coordinates (0,0 to (639, 479)
    signal pix_x, pix_y: unsigned(9 downto 0);
    -- screen dimensions
    constant MAX_X: integer := 640;
    constant MAX_Y: integer := 480;
    -- wall left and right boundary of wall (full height)
    constant WALL_X_L: integer := 32;
    constant WALL_X_R: integer := 35;
    signal hit_cnter_reg, hit_cnter_next: unsigned(2 downto 0);
    signal ball_x_l, ball_x_r: unsigned(9 downto 0);
    signal ball_y_t, ball_y_b: unsigned(9 downto 0);
    signal ball_x_reg, ball_x_next: unsigned(9 downto 0);
    signal ball_y_reg, ball_y_next: unsigned(9 downto 0);

    signal ball2_x_l, ball2_x_r: unsigned(9 downto 0);
    signal ball2_y_t, ball2_y_b: unsigned(9 downto 0);
    signal ball2_x_reg, ball2_x_next: unsigned(9 downto 0);
    signal ball2_y_reg, ball2_y_next: unsigned(9 downto 0);

    signal ball3_x_l, ball3_x_r: unsigned(9 downto 0);
    signal ball3_y_t, ball3_y_b: unsigned(9 downto 0);
    signal ball3_x_reg, ball3_x_next: unsigned(9 downto 0);
    signal ball3_y_reg, ball3_y_next: unsigned(9 downto 0);

-- square ast1 -- ast1 left, right, top and bottom
-- all vary. Left and top driven by registers below.
    constant AST1_SIZE: integer := 16;
    constant BALL_SIZE: integer := 8;
    signal ast1_x_l, ast1_x_r: unsigned(9 downto 0);
    signal ast1_y_t, ast1_y_b: unsigned(9 downto 0);
-- reg to track left and top boundary
    signal ast1_x_reg, ast1_x_next: unsigned(9 downto 0);
    signal ast1_y_reg, ast1_y_next: unsigned(9 downto 0);
-- reg to track ast1 speed
    signal x_delta_reg, x_delta_next: unsigned(9 downto 0);
    signal y_delta_reg, y_delta_next: unsigned(9 downto 0);
-- ast1 movement can be pos or neg
    constant AST1_V_P: unsigned(9 downto 0):= to_unsigned(1,10);
    constant AST1_V_N: unsigned(9 downto 0):= unsigned(to_signed(-1,10));
    constant BALL_V_P: unsigned(9 downto 0):= to_unsigned(2,10);

    type ball_type is array(0 to 7) of std_logic_vector(0 to 7);
    constant BALL_ROM: ball_type:= (
        "00111100",
        "01111110",
        "11111111",
        "11111111",
        "11111111",
        "11111111",
        "01111110",
        "00111100");
    signal ball_addr, ball_col: unsigned(2 downto 0);
    signal ball_data: std_logic_vector(7 downto 0);
    signal ball_bit: std_logic;

    type ball2_type is array(0 to 7) of std_logic_vector(0 to 7);
    constant BALL2_ROM: ball2_type:= (
        "00111100",
        "01111110",
        "11111111",
        "11111111",
        "11111111",
        "11111111",
        "01111110",
        "00111100");
    signal ball2_addr, ball2_col: unsigned(2 downto 0);
    signal ball2_data: std_logic_vector(7 downto 0);
    signal ball2_bit: std_logic;

    type ball3_type is array(0 to 7) of std_logic_vector(0 to 7);
    constant BALL3_ROM: ball3_type:= (
        "00111100",
        "01111110",
        "11111111",
        "11111111",
        "11111111",
        "11111111",
        "01111110",
        "00111100");
    signal ball3_addr, ball3_col: unsigned(2 downto 0);
    signal ball3_data: std_logic_vector(7 downto 0);
    signal ball3_bit: std_logic;

-- space ship image
    type space_type is array(0 to 31) of std_logic_vector(0 to 31);
    constant SPACE_ROM: space_type:= (
        "00000000000000011000000000000000",
        "00000000000001111110000000000000",
        "00000000000011111111000000000000",
        "00000000000111111111100000000000",
        "00000000001111111111110000000000",
        "00000000001111100111110000000000",
        "00000000001110000001110000000000",
        "00000000011110000001111000000000",
        "00000000111110000001111100000000",
        "00000000111111100111111100000000",
        "00000000111111111111111100000000",
        "00000011111111111111111111000000",
        "00000011111111111111111111000000",
        "00000011111111111111111111000000",
        "00000011111111111111111111000000",
        "00000111111111111111111111100000",
        "00001111111111111111111111110000",
        "00001111111111111111111111110000",
        "00011111111111111111111111111000",
        "00111111111000000000011111111100",
        "01111111110000000000001111111110",
        "01111111100001111110000111111110",
        "01111111000001111110000011111110",
        "01111111100000000000000111111110",
        "00111111110000000000001111111100",
        "00011111111111111111111111111000",
        "00000111111111111111111111100000",
        "00001111111111111111111111110000",
        "00011111111111111111111111111000",
        "00111111111111111111111111111100",
        "01111111111111111111111111111110",
        "11111111111111111111111111111111"
        );
    signal space_addr, space_col: unsigned(5 downto 0);
    signal space_data: std_logic_vector(31 downto 0);
    signal space_bit: std_logic;

    signal space_y_t, space_y_b: unsigned(9 downto 0);
    signal space_x_l, space_x_r: unsigned(9 downto 0);
    constant SPACE_SIZE: integer := 32;
-- reg to track top boundary (x position is fixed)
    signal space_y_reg, space_y_next: unsigned(9 downto 0);
    signal space_x_reg, space_x_next: unsigned(9 downto 0);
-- bar moving velocity when a button is pressed
-- the amount the bar is moved.
    constant SPACE_V: integer:= 1;


-- round ast1 image
    type rom_type is array(0 to 15) of std_logic_vector(0 to 15);
    constant AST1_ROM: rom_type:= (
        "0000011111111100",
        "0000111111111110",
        "0001111111111100",
        "0111111111111100",
        "0011111111111000",
        "0001111111111110",
        "0000111111111111",
        "1111111111111111",
        "0011111111111000",
        "0111111111111000",
        "0011111111100000",
        "0011111111111100",
        "0111111111110000",
        "0111111111100000",
        "0001111111111000",
        "1111111111110000");
    signal rom_addr, rom_col: unsigned(3 downto 0);
    signal rom_data: std_logic_vector(15 downto 0);
    signal rom_bit: std_logic;
    
    constant AST2_SIZE: integer := 16;
    signal ast2_x_l, ast2_x_r: unsigned(9 downto 0);
    signal ast2_y_t, ast2_y_b: unsigned(9 downto 0);
-- reg to track left and top boundary
    signal ast2_x_reg, ast2_x_next: unsigned(9 downto 0);
    signal ast2_y_reg, ast2_y_next: unsigned(9 downto 0);
-- reg to track ast1 speed
    signal ast2_x_delta_reg, ast2_x_delta_next: unsigned(9 downto 0);
    signal ast2_y_delta_reg, ast2_y_delta_next: unsigned(9 downto 0);
-- ast1 movement can be pos or neg
    constant AST2_V_P: unsigned(9 downto 0):= to_unsigned(1,10);
    constant AST2_V_N: unsigned(9 downto 0):= unsigned(to_signed(-1,10));
--ast2angle image
    type ast2_type is array(0 to 15) of std_logic_vector(0 to 15);
    constant AST2_ROM : ast2_type:=(
        "0000011111111100",
        "0000111111111110",
        "0001111111100000",
        "0111111111111100",
        "0011111111111000",
        "0001111111111110",
        "0000111111111111",
        "1111111111110000",
        "0011111111111000",
        "0111111111111000",
        "0011111111100000",
        "0011111111111100",
        "0111111111110000",
        "0111111111100000",
        "0001111111111000",
        "1111111111110000");
    signal ast2_addr, ast2_col: unsigned(3 downto 0);
    signal ast2_data: std_logic_vector(15 downto 0);
    signal ast2_bit: std_logic;

    type ast3_type is array(0 to 15) of std_logic_vector(0 to 15);
    constant AST3_ROM : ast3_type:=(
        "0000011111111100",
        "0000111111111110",
        "0000001111111100",
        "0111111111111100",
        "0011111111111000",
        "0001111111111110",
        "0000111111111111",
        "1111111111100000",
        "0011111111111000",
        "0111111111111000",
        "0011111111100000",
        "0011111111111100",
        "0111111111110000",
        "0111111111100000",
        "0001111111111000",
        "1111111111110000");
    signal ast3_addr, ast3_col: unsigned(3 downto 0);
    signal ast3_data: std_logic_vector(15 downto 0);
    signal ast3_bit: std_logic;

        

    signal ast3_x_l, ast3_x_r: unsigned(9 downto 0);
    signal ast3_y_t, ast3_y_b: unsigned(9 downto 0);
-- reg to track left and top boundary
    signal ast3_x_reg, ast3_x_next: unsigned(9 downto 0);
    signal ast3_y_reg, ast3_y_next: unsigned(9 downto 0);
-- reg to track ast1 speed
    signal ast3_x_delta_reg, ast3_x_delta_next: unsigned(9 downto 0);
    signal ast3_y_delta_reg, ast3_y_delta_next: unsigned(9 downto 0);
-- ast1 movement can be pos or neg

-- object output signals -- new signal to indicate if
-- scan coord is within ast1
    signal wall_on, bar_on, sq_ast1_on, rd_ast1_on, ast2_on, ast2_b_on, space_b_on, space_on,ast3_b_on, ast3_on, firing_on, firing_b_on, firing_on2, firing_b_on2, firing_on3, firing_b_on3 : std_logic;
    signal wall_rgb, bar_rgb, ast1_rgb, ast2_rgb, space_rgb, ast3_rgb, ball_rgb, ball2_rgb, ball3_rgb: std_logic_vector(2 downto 0);
-- ====================================================
    begin
    process (clk, reset)
        begin
        if (reset = '1') then
            space_y_reg <= (others => '0');
            space_x_reg <= ("0100110001");
            ball_x_reg <= (others => '0');
            ball_y_reg <= (others => '0');
            ball2_x_reg <= (others => '0');
            ball2_y_reg <= (others => '0');
            ball3_x_reg <= (others => '0');
            ball3_y_reg <= (others => '0');
            ast1_x_reg <= ("0000001100");
            ast1_y_reg <= (others => '0');
            ast2_x_reg <= (others => '0');
            ast2_y_reg <= ("0011111010");
            x_delta_reg <= ("0000000100");
            y_delta_reg <= ("0000000100");
            ast2_x_delta_reg <= ("0000000100");
            ast2_y_delta_reg <= ("0000000100");
            hit_cnter_reg <= (others => '0');
            ast3_x_reg <= (others => '0');
            ast3_y_reg <= ("0111100000");
            ast3_x_delta_reg <= ("0000000100");
            ast3_y_delta_reg <= ("0000000100");

        elsif (clk'event and clk = '1') then
            space_y_reg <= space_y_next;
            space_x_reg <= space_x_next;
            ast1_x_reg <= ast1_x_next;
            ast1_y_reg <= ast1_y_next;
            ball_x_reg <= ball_x_next;
            ball_y_reg <= ball_y_next;
            ball2_x_reg <= ball2_x_next;
            ball2_y_reg <= ball2_y_next;
            ball3_x_reg <= ball3_x_next;
            ball3_y_reg <= ball3_y_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
            ast2_x_reg <= ast2_x_next;
            ast2_y_reg <= ast2_y_next;
            ast2_x_delta_reg <= ast2_x_delta_next;
            ast2_y_delta_reg <= ast2_y_delta_next;
            ast3_x_reg <= ast3_x_next;
            ast3_y_reg <= ast3_y_next;
            ast3_x_delta_reg <= ast3_x_delta_next;
            ast3_y_delta_reg <= ast3_y_delta_next;
            hit_cnter_reg <= hit_cnter_next; 
            
            if ( ball_x_l <= ast1_x_r) then
                ast1_x_reg <= ("0000001100");
            end if;

        end if;
    end process;

    pix_x <= unsigned(pixel_x);
    pix_y <= unsigned(pixel_y);


    --Process block that implements launching and movement of firing_balls
    --- You can use btn(4) if you already have used 4 btns
    process (ball_x_reg, ball_y_reg, refr_tick, btn(4),space_y_reg, space_x_reg, space_y_t, space_y_b)
        begin
        ball_y_next  <= ball_y_reg;
        ball_x_next <= ball_x_reg;
        --- Default output values below
        if (refr_tick = '1') then
            if(btn(4)='1') then
               ball_x_next <= space_x_l;
               ball_y_next <= ((space_y_t + space_y_b) / 2);
               ball2_x_next <= space_x_l;
               ball2_y_next <= ((space_y_t + space_y_b) / 2);
               ball3_x_next <= space_x_l;
               ball3_y_next <= ((space_y_t + space_y_b) / 2);

            else
                if ((ball_x_r > 0) and (ball_x_reg < MAX_X)) then
                    ball_x_next <= ball_x_reg - BALL_V_P;
                end if;
                if ((ball2_x_r > 0) and (ball2_x_reg < MAX_X) and (ball2_y_reg < MAX_Y)) then
                    ball2_x_next <= ball2_x_reg - BALL_V_P;
                    ball2_y_next <= ball2_y_reg +  BALL_V_P;
                end if;
                if ((ball3_x_r > 0) and (ball3_x_reg < MAX_X)) then
                    ball3_x_next <= ball3_x_reg - BALL_V_P;
                    ball3_y_next <= ball3_y_reg -  BALL_V_P;
                end if;
            end if;
        end if;
    end process;

    

    
    -- set coordinates of square ball.
    ball_x_l <= ball_x_reg;
    ball_y_t <= ball_y_reg;
    ball_x_r <= ball_x_l + BALL_SIZE - 1;
    ball_y_b <= ball_y_t + BALL_SIZE - 1;
-- pixel within square ball
    firing_b_on <= '1' when (ball_x_l <= pix_x) and
        (pix_x <= ball_x_r) and (ball_y_t <= pix_y) and
        (pix_y <= ball_y_b) else '0';
-- map scan coord to ROM addr/col -- use low order three
-- bits of pixel and ball positions.
-- ROM row
    ball_addr <= pix_y(2 downto 0) - ball_y_t(2 downto 0);
-- ROM column
    ball_col <= pix_x(2 downto 0) - ball_x_l(2 downto 0);
-- Get row data
    ball_data <= BALL_ROM(to_integer(ball_addr));
-- Get column bit
    ball_bit <= ball_data(to_integer(ball_col));
-- Turn ball on only if within square and ROM bit is 1.
    firing_on <= '1' when (firing_b_on = '1') and
        (ball_bit = '1') else '0';
    ball_rgb <= "010"; -- green

    -- set coordinates of square ball.
    ball2_x_l <= ball2_x_reg;
    ball2_y_t <= ball2_y_reg;
    ball2_x_r <= ball2_x_l + BALL_SIZE - 1;
    ball2_y_b <= ball2_y_t + BALL_SIZE - 1;
-- pixel within square ball
    firing_b_on2 <= '1' when (ball2_x_l <= pix_x) and
        (pix_x <= ball2_x_r) and (ball2_y_t <= pix_y) and
        (pix_y <= ball2_y_b) else '0';
-- map scan coord to ROM addr/col -- use low order three
-- bits of pixel and ball positions.
-- ROM row
    ball2_addr <= pix_y(2 downto 0) - ball2_y_t(2 downto 0);
-- ROM column
    ball2_col <= pix_x(2 downto 0) - ball2_x_l(2 downto 0);
-- Get row data
    ball2_data <= BALL2_ROM(to_integer(ball2_addr));
-- Get column bit
    ball2_bit <= ball2_data(to_integer(ball2_col));
-- Turn ball on only if within square and ROM bit is 1.
    firing_on2 <= '1' when (firing_b_on2 = '1') and
        (ball2_bit = '1') else '0';
    ball2_rgb <= "010"; -- green


    -- set coordinates of square ball.
    ball3_x_l <= ball3_x_reg;
    ball3_y_t <= ball3_y_reg;
    ball3_x_r <= ball3_x_l + BALL_SIZE - 1;
    ball3_y_b <= ball3_y_t + BALL_SIZE - 1;
-- pixel within square ball
    firing_b_on3 <= '1' when (ball3_x_l <= pix_x) and
        (pix_x <= ball3_x_r) and (ball3_y_t <= pix_y) and
        (pix_y <= ball3_y_b) else '0';
-- map scan coord to ROM addr/col -- use low order three
-- bits of pixel and ball positions.
-- ROM row
    ball3_addr <= pix_y(2 downto 0) - ball3_y_t(2 downto 0);
-- ROM column
    ball3_col <= pix_x(2 downto 0) - ball3_x_l(2 downto 0);
-- Get row data
    ball3_data <= BALL_ROM(to_integer(ball3_addr));
-- Get column bit
    ball3_bit <= ball3_data(to_integer(ball3_col));
-- Turn ball on only if within square and ROM bit is 1.
    firing_on3 <= '1' when (firing_b_on3 = '1') and
        (ball3_bit = '1') else '0';
    ball3_rgb <= "010"; -- green


    space_x_l <= space_x_reg;
    space_y_t <= space_y_reg;
    space_x_r <= space_x_l + SPACE_SIZE - 1;
    space_y_b <= space_y_t + SPACE_SIZE - 1;
-- pixel within square ast1
    space_b_on <= '1' when (space_x_l <= pix_x) and
        (pix_x <= space_x_r) and (space_y_t <= pix_y) and
        (pix_y <= space_y_b) else '0';
-- map scan coord to ROM addr/col -- use low order three
-- bits of pixel and ast1 positions.
-- ROM row
    space_addr <= pix_y(5 downto 0) - space_y_t(5 downto 0);
-- ROM column
    space_col <= pix_x(5 downto 0) - space_x_l(5 downto 0);
-- Get row data
    space_data <= SPACE_ROM(to_integer(space_addr));
-- Get column bit
    space_bit <= space_data(to_integer(space_col));
-- Turn ast1 on only if within square and ROM bit is 1.
    space_on <= '1' when (space_b_on = '1') and
        (space_bit = '1') else '0';
    space_rgb <= "010"; -- green

    -- Process bar movement requests
    process( space_y_reg, space_y_b, space_y_t, refr_tick, btn)
    begin
    space_y_next <= space_y_reg; -- no move
    if ( refr_tick = '1' ) then
    -- if btn 1 pressed and paddle not at bottom yet
        if ( btn(1) = '1' and space_y_b <
            (MAX_Y - 1 - SPACE_V)) then
            space_y_next <= space_y_reg + SPACE_V;
    -- if btn 0 pressed and bar not at top yet
        elsif ( btn(0) = '1' and space_y_t > SPACE_V) then
            space_y_next <= space_y_reg - SPACE_V;
        end if;
    end if;
    end process;

    process( space_x_reg, space_x_l, space_x_r, refr_tick, btn)
    begin
    space_x_next <= space_x_reg; ---no movement
    if(refr_tick = '1') then
        if( btn(2) ='1' and space_x_l > 0 )then
            space_x_next <= space_x_reg - SPACE_V;
        elsif( btn(3) ='1' and space_x_r < (MAX_X-1-SPACE_V)) then
            space_x_next <= space_x_reg + SPACE_V;
        end if;
    end if;
    end process;

-- refr_tick: 1-clock tick asserted at start of v_sync,
-- e.g., when the screen is refreshed -- speed is 60 Hz
    refr_tick <= '1' when (pix_y = 481) and (pix_x = 0)
        else '0';
-- wall left vertical sast2pe
    wall_on <= '1' when (WALL_X_L <= pix_x) and
        (pix_x <= WALL_X_R) else '0';
    wall_rgb <= "000"; -- blue


-- set coordinates of square ast1.
    ast1_x_l <= ast1_x_reg;
    ast1_y_t <= ast1_y_reg;
    ast1_x_r <= ast1_x_l + AST1_SIZE - 1;
    ast1_y_b <= ast1_y_t + AST1_SIZE - 1;
-- pixel within square ast1
    sq_ast1_on <= '1' when (ast1_x_l <= pix_x) and
        (pix_x <= ast1_x_r) and (ast1_y_t <= pix_y) and
        (pix_y <= ast1_y_b) else '0';
-- map scan coord to ROM addr/col -- use low order three
-- bits of pixel and ast1 positions.
-- ROM row
    rom_addr <= pix_y(3 downto 0) - ast1_y_t(3 downto 0);
-- ROM column
    rom_col <= pix_x(3 downto 0) - ast1_x_l(3 downto 0);
-- Get row data
    rom_data <= AST1_ROM(to_integer(rom_addr));
-- Get column bit
    rom_bit <= rom_data(to_integer(rom_col));
-- Turn ast1 on only if within square and ROM bit is 1.
    rd_ast1_on <= '1' when (sq_ast1_on = '1') and
        (rom_bit = '1') else '0';
    ast1_rgb <= "100"; -- red
-- Update the ast1 position 60 times per second.
    ast1_x_next <= ast1_x_reg + x_delta_reg when
        refr_tick = '1' else ast1_x_reg;
    ast1_y_next <= ast1_y_reg + y_delta_reg when
        refr_tick = '1' else ast1_y_reg;
-- Set the value of the next ast1 position according to
-- the boundaries.
    process(x_delta_reg, y_delta_reg, ast1_y_t, ast1_x_l,
    ast1_x_r, ast1_y_t, ast1_y_b, space_y_t, space_y_b, space_x_l, space_x_r)
        begin
        x_delta_next <= x_delta_reg;
        y_delta_next <= y_delta_reg;
        -- ast1 reached top, make offset positive
        if ( ast1_y_t < 1 ) then
            y_delta_next <= AST1_V_P;    
-- reached bottom, make negative
        elsif (ast1_y_b > (MAX_Y - 1)) then
            y_delta_next <= AST1_V_N;
-- reach wall, bounce back
        elsif (ast1_x_l <= WALL_X_R ) then
            x_delta_next <= AST1_V_P;
-- right corner of ast1 inside bar
        elsif ((space_x_l <= ast1_x_r) and
            (ast1_x_r <= space_x_r)) then
-- some portion of ast1 hitting paddle, reverse dir
            if ((space_y_t <= ast1_y_b) and
                (ast1_y_t <= space_y_b)) then
                x_delta_next <= AST1_V_N;
            end if;
        end if;
    end process;

    -- set coordinates of square ast1.
    ast2_x_l <= ast2_x_reg;
    ast2_y_t <= ast2_y_reg;
    ast2_x_r <= ast2_x_l + AST2_SIZE - 1;
    ast2_y_b <= ast2_y_t + AST2_SIZE - 1;
-- pixel within square ast1
    ast2_on <= '1' when (ast2_x_l <= pix_x) and
        (pix_x <= ast2_x_r) and (ast2_y_t <= pix_y) and
        (pix_y <= ast2_y_b) else '0';
-- map scan coord to ROM addr/col -- use low order three
-- bits of pixel and ast1 positions.
-- ROM row
    ast2_addr <= pix_y(3 downto 0) - ast2_y_t(3 downto 0);
-- ROM column
    ast2_col <= pix_x(3 downto 0) - ast2_x_l(3 downto 0);
-- Get row data
    ast2_data <= AST2_ROM(to_integer(ast2_addr));
-- Get column bit
    ast2_bit <= ast2_data(to_integer(ast2_col));
-- Turn ast1 on only if within square and ROM bit is 1.
    ast2_b_on <= '1' when (ast2_on = '1') and
        (ast2_bit = '1') else '0';
    ast2_rgb <= "011"; -- magenta
-- Update the ast1 position 60 times per second.
    ast2_x_next <= ast2_x_reg + ast2_x_delta_reg when
        refr_tick = '1' else ast2_x_reg;
    ast2_y_next <= ast2_y_reg + ast2_y_delta_reg when
        refr_tick = '1' else ast2_y_reg;
-- Set the value of the next ast1 position according to
-- the boundaries.
    process(ast2_x_delta_reg, ast2_y_delta_reg, ast2_y_t, ast2_x_l,
    ast2_x_r, ast2_y_t, ast2_y_b, space_y_t, space_y_b, space_x_l)
        begin
        ast2_x_delta_next <= ast2_x_delta_reg;
        ast2_y_delta_next <= ast2_y_delta_reg;
        -- ast1 reached top, make offset positive
        if ( ast2_y_t < 1 ) then
            ast2_y_delta_next <= AST2_V_P;    
-- reached bottom, make negative
        elsif (ast2_y_b > (MAX_Y - 1)) then
            ast2_y_delta_next <= AST2_V_N;
-- reach wall, bounce back
        elsif (ast2_x_l <= WALL_X_R ) then
            ast2_x_delta_next <= AST2_V_P;
-- right corner of ast1 inside bar
        elsif ((space_x_l <= ast2_x_r) and
            (ast2_x_r <= space_x_r)) then
-- some portion of ast1 hitting paddle, reverse dir
            if ((space_y_t <= ast2_y_b) and
                (ast2_y_t <= space_y_b)) then
                ast2_x_delta_next <= AST2_V_N;
            end if;
        end if;
    end process;
  
        -- set coordinates of square ast1.
        ast3_x_l <= ast3_x_reg;
        ast3_y_t <= ast3_y_reg;
        ast3_x_r <= ast3_x_l + AST2_SIZE - 1;
        ast3_y_b <= ast3_y_t + AST2_SIZE - 1;
    -- pixel within square ast1
        ast3_on <= '1' when (ast3_x_l <= pix_x) and
            (pix_x <= ast3_x_r) and (ast3_y_t <= pix_y) and
            (pix_y <= ast3_y_b) else '0';
    -- map scan coord to ROM addr/col -- use low order three
    -- bits of pixel and ast1 positions.
    -- ROM row
        ast3_addr <= pix_y(3 downto 0) - ast3_y_t(3 downto 0);
    -- ROM column
        ast3_col <= pix_x(3 downto 0) - ast3_x_l(3 downto 0);
    -- Get row data
        ast3_data <= AST3_ROM(to_integer(ast3_addr));
    -- Get column bit
        ast3_bit <= ast3_data(to_integer(ast3_col));
    -- Turn ast1 on only if within square and ROM bit is 1.
        ast3_b_on <= '1' when (ast3_on = '1') and
            (ast3_bit = '1') else '0';
        ast3_rgb <= "101"; -- magenta
    -- Update the ast1 position 60 times per second.
        ast3_x_next <= ast3_x_reg + ast3_x_delta_reg when
            refr_tick = '1' else ast3_x_reg;
        ast3_y_next <= ast3_y_reg + ast3_y_delta_reg when
            refr_tick = '1' else ast3_y_reg;
    -- Set the value of the next ast1 position according to
    -- the boundaries.
        process(ast3_x_delta_reg, ast3_y_delta_reg, ast3_y_t, ast3_x_l,
        ast3_x_r, ast3_y_t, ast3_y_b, space_y_t, space_y_b, space_x_l)
            begin
            ast3_x_delta_next <= ast3_x_delta_reg;
            ast3_y_delta_next <= ast3_y_delta_reg;
            -- ast1 reached top, make offset positive
            if ( ast3_y_t < 1 ) then
                ast3_y_delta_next <= AST2_V_P;    
    -- reached bottom, make negative
            elsif (ast3_y_b > (MAX_Y - 1)) then
                ast3_y_delta_next <= AST2_V_N;
    -- reach wall, bounce back
            elsif (ast3_x_l <= WALL_X_R ) then
                ast3_x_delta_next <= AST2_V_P;
    -- right corner of ast1 inside bar
            elsif ((space_x_l <= ast3_x_r) and
                (ast3_x_r <= space_x_r)) then
    -- some portion of ast1 hitting paddle, reverse dir
                if ((space_y_t <= ast3_y_b) and
                    (ast3_y_t <= space_y_b)) then
                    ast3_x_delta_next <= AST2_V_N;
                end if;
            end if;
        end process;


        
        --ast1 disappear
        -- process(ast1_x_r, ast1_x_l, ast1_y_t, ast1_y_b, ball_x_l, ball_x_r, ball_y_t, ball_y_b)
        --     begin
        --     if ( ball_x_l <= ast1_x_r) then
        --         rd_ast1_on <= '0';
        --     else
        --         rd_ast1_on <= '1';
        --     end if;
        -- end process;
    

--(not equal to) than bar_left_boundary, and x_delta is positive
    
  hit_cnter_next <= hit_cnter_reg+1 when ((x_delta_reg = AST1_V_N) or (ast2_x_delta_reg = AST2_V_N) or (ast3_x_delta_reg = AST2_V_N)) 
                         and (refr_tick = '1')
                         else hit_cnter_reg;
    
    -- ball1_hit  <= ((space_x_l < ast1_x_r) and (ast1_x_r < space_x_l + AST1_V_P) and (x_delta_reg = AST1_V_P) and (space_y_t < ast1_y_b) and (ast1_y_t < space_y_b) and (refr_tick = '1') );
    -- ball2_hit  <= ((space_x_l < ast2_x_r) and (ast2_x_r < space_x_l + AST2_V_P) and (x_delta_reg = AST2_V_P) and (space_y_t < ast2_y_b) and (ast2_y_t < space_y_b) and (refr_tick = '1') );
    -- ball3_hit  <= ((space_x_l < ast3_x_r) and (ast3_x_r < space_x_l + AST2_V_P) and (x_delta_reg = AST2_V_P) and (space_y_t < ast3_y_b) and (ast3_y_t < space_y_b) and (refr_tick = '1') );
    
    
    -- hit_cnter_next <= hit_cnter_reg+1 when (ball1_hit or ball2_hit or ball3_hit) else hit_cnter_reg;
                    
    -- -failed attempt at fsmd
    -- process( ast1_x_l, ast1_x_r, ast1_y_t, ast1_y_b, bar_y_t, bar_y_b, 
    --             hit_state_next, hit_state_reg, bar_x_l, bar_x_r )
    --             begin
    --             hit_state_next <= hit_state_reg;

    --             case hit_state_reg is 
    --                 when idle =>
    --                     if (refr_tick = '1') then
    --                         if (ast1_x_r >= bar_x_l) 
    --                             -- and (ast1_x_r < bar_x_l + AST1_V_P)
    --                             and (x_delta_reg = AST1_V_N)
    --                             -- and (bar_y_t < ast1_y_b)
    --                             -- and (ast1_y_t < bar_y_b) 
    --                             then
    --                             hit_state_next <= contact;
    --                         else
    --                             hit_state_next <= idle;
    --                         end if;
    --                     end if;

    --                 when contact =>
    --                     if (refr_tick = '1') then
    --                         if(x_delta_reg = AST1_V_N) and (ast1_x_r < bar_x_l) then
    --                             hit_cnter_next <= hit_cnter_reg+1;
    --                             hit_state_next <= idle;
    --                         end if;
    --                     end if;
    --             end case;
    -- end process;


    hit_cnt <= std_logic_vector(hit_cnter_reg);

    process (video_on, wall_on, space_on, rd_ast1_on, wall_rgb, space_rgb, ast1_rgb)
        begin
        if (video_on = '0') then
            graph_rgb <= "000"; -- blank
        else
            if (wall_on = '1') then
                graph_rgb <= wall_rgb;
            -- elsif (bar_on = '1') then
            --     graph_rgb <= bar_rgb;
            elsif (space_on = '1') then
                graph_rgb <= space_rgb;
            elsif (rd_ast1_on = '1') then
                graph_rgb <= ast1_rgb;
            elsif (ast2_b_on = '1') then
                graph_rgb <= ast2_rgb;
            elsif (ast3_b_on = '1') then
                graph_rgb <= ast3_rgb;
            elsif (firing_on = '1') then
                graph_rgb <= ball_rgb;
            elsif (firing_on2 = '1') then
                graph_rgb <= ball2_rgb;
            elsif (firing_on3 = '1') then
                graph_rgb <= ball3_rgb;
            else
                graph_rgb <= "111"; -- yellow bkgnd
            end if;
        end if;
    end process;

end game_arch;
        
