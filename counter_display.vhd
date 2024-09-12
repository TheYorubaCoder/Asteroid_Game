library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity counter_disp is
    Port (
        pixel_x : in STD_LOGIC_VECTOR (9 downto 0);
        pixel_y : in STD_LOGIC_VECTOR (9 downto 0);
        hit_cnt: in STD_LOGIC_VECTOR (2 downto 0);
        sq_hit_cnter_on_output: out std_logic;
        graph_rgb: out std_logic_vector(2 downto 0)
    );
end counter_disp;

architecture Behavioral of counter_disp is
    -- x, y coordinates (0,0 to (639, 479)
    signal pix_x, pix_y: unsigned(9 downto 0);

    -- signal that stores the unsigned 'hit_cnt' value
    signal hit_cnter: unsigned(2 downto 0);

    -- Square cnter size and boundaries
    constant CNT_SIZE: integer := 16;
    constant HIT_CNT_X_L: integer := 610;
    constant HIT_CNT_X_R: integer:= HIT_CNT_X_L + CNT_SIZE - 1;
    constant HIT_CNT_Y_T: integer := 80;
    constant HIT_CNT_Y_B: integer:= HIT_CNT_Y_T + CNT_SIZE - 1;
    -- new data type to store the 16x16 rom images of counter values 0-7
    type counter_type is array(0 to 15) of std_logic_vector(15 downto
    0);
    -- signal that stores the rom image of the current cnter value
    signal cnter_rom_current: counter_type;
-- constant rom images for 0-7
--- Write your own VHDL code below:
--- Initialize images for other CNTER_ROM VALUES (1-7)
    constant CNTER_ROM_0: counter_type:= (
    "0000101111110000",
    "0001111111111100",
    "0111000000001111",
    "0110000000000011",
    "1110000000000011",
    "1110000000000011",
    "1110000000000011",
    "1110000000000011",
    "1110000000000011",
    "1110000000000011",
    "1110000000000011",
    "1110000000000011",
    "1110000000000111",
    "0111000000011110",
    "0011111111111100",
    "0000111111111000");
    constant CNTER_ROM_1: counter_type:= (
        "0000011111110000",
        "0000011111111000",
        "0000011110011100",
        "0000011110011110",
        "0000011110001111",
        "0000011110000000",
        "0000011110000000",
        "0000011110000000",
        "0000011110000000",
        "0000011110000000",
        "0000011110000000",
        "0000011110000000",
        "0000011110000000",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111");
    
        constant CNTER_ROM_2: counter_type:= (
            "0011111111111100",
            "0111111111111110",
            "1111110000000111",
            "1111110000000011",
            "1111110000000000",
            "0111110000000000",
            "0111110000000000",
            "0001111111000000",
            "0000111111100000",
            "0000001111110000",
            "0000000011110000",
            "0000000001111000",
            "0000000000111100",
            "0000000000111100",
            "0000000000011110",
            "1111111111111111");
    
        constant CNTER_ROM_3: counter_type:= (
        "0001111111111000",
        "0011111111111100",
        "0111100000011111",
        "1111000000000111",
        "1111000000000000",
        "1111000000000000",
        "1111111100000000",
        "0001111111100000",
        "0011111100000000",
        "0111110000000000",
        "1111100000000000",
        "1111100000000000",
        "1111100000000000",
        "0111110000001111",
        "0011111111111100",
        "0001111111111000");

    constant CNTER_ROM_4: counter_type:= (
        "0000111100000000",
        "0000111110000000",
        "0000111101100000",
        "0000111100110000",
        "0000111100011000",
        "0000111100001100",
        "0000111100000110",
        "1111111111111111",
        "1111111111111111",
        "0000111100000000",
        "0000111100000000",
        "0000111100000000",
        "0000111100000000",
        "0000111100000000",
        "0000111100000000",
        "0000111100000000");
    
    constant CNTER_ROM_5: counter_type:= (
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "0000000000001111",
        "0000000000001111",
        "0000000000001111",
        "0000000111111111",
        "0000111111111111",
        "0111111111111111",
        "1111111110000000",
        "1111111100000000",
        "1111110000000000",
        "1111110000000000",
        "1111110000000000",
        "1111111111111111",
        "1111111111111111");
        
    constant CNTER_ROM_6: counter_type:= (
        "0011111111111100",
        "0111111111111100",
        "1111000000011110",
        "1100000000111110",
        "1100000000111111",
        "0000000000001111",
        "0000000000001111",
        "0000111111111111",
        "1111111111111111",
        "1111111000000111",
        "1111000000001111",
        "1111000000001111",
        "1111000000001111",
        "1111000000001111",
        "0111111111111110",
        "0011111111111000");
        
    
    constant CNTER_ROM_7: counter_type:= (
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111000000000000",
        "0111100000000000",
        "0011110000000000",
        "0001111000000000",
        "0000111100000000",
        "0000011110000000",
        "0000001111000000",
        "0000000111100000",
        "0000000011110000",
        "0000000001111000",
        "0000000000111100",
        "0000000000011110",
        "0000000000001111");

    -- signals to store the row and column indexes of the current cnter rom
    signal rom_addr_cnter, rom_col_cnter: unsigned(3 downto 0);
    -- signals to store the row data and the rom_bit
    signal rom_data_cnter: std_logic_vector(15 downto 0);
    signal rom_bit_cnter: std_logic;
    -- signal to indicate if scan coord is within the square area of
    --- the counter
    signal sq_hit_cnter_on: std_logic;
    -- signals to indicate if the image of current cnter value is
    --- displayed
    signal hit_cnter_cur_val_on: std_logic;
    -- hit cnter value color
    signal hit_cnter_rgb:std_logic_vector(2 downto 0);
    -- signals that store unsigned values of the square counter boundaries
    signal hit_cnt_y_t_u: unsigned(9 downto 0);
    signal hit_cnt_x_l_u: unsigned(9 downto 0);
    begin
    pix_x <= unsigned(pixel_x);
    pix_y <= unsigned(pixel_y);
    hit_cnter <= unsigned(hit_cnt);
    -- Write your VHDL code below:
    -- Assert ‘sq_hit_cnter_on’ by checking if the pixel is within the area
    --- of the square hit_counter;
    -- Note: the square area is a fixed area shared by 8 counter values

    sq_hit_cnter_on <= '1' when (pix_x >= HIT_CNT_X_L) and 
                               (pix_x <= HIT_CNT_X_R ) and 
                               (pix_y >= HIT_CNT_Y_T) and
                               (pix_y <= HIT_CNT_Y_B ) else '0';



    --- Write your VHDL code: complete “with select” statement below:
    --- Here we use a signal ‘cnter_rom_current’ to store the actual
    --- ROM image to be displayed which depends on the current cnter value.
    -- Assign the corresponding ROM image constant to ‘cnter_rom_current’
    --- depending on the value of ‘hit_cnter’
    with to_integer(hit_cnter) select
        cnter_rom_current <= CNTER_ROM_0 when 0,
                            CNTER_ROM_1 when 1,
                            CNTER_ROM_2 when 2,
                            CNTER_ROM_3 when 3,
                            CNTER_ROM_4 when 4,
                            CNTER_ROM_5 when 5,
                            CNTER_ROM_6 when 6,
                            CNTER_ROM_7 when others;
                                    

    --- Complete the above “with-select” statement
   
    -- type conversion to unsigned values    
    hit_cnt_y_t_u <= to_unsigned(HIT_CNT_Y_T, 10);
    hit_cnt_x_l_u <= to_unsigned(HIT_CNT_X_L, 10);
    -- Obtain row and col indexes
    rom_addr_cnter <= pix_y(3 downto 0) - hit_cnt_y_t_u(3 downto 0);
    rom_col_cnter <= pix_x(3 downto 0) - hit_cnt_x_l_u(3 downto 0);
    -- map scan coord to rom_bit using addr/col for current cnter value;
    rom_data_cnter <= cnter_rom_current(to_integer(rom_addr_cnter));
    rom_bit_cnter <= rom_data_cnter(to_integer(rom_col_cnter));
    --- Write your VHDL code below:
    -- assert ‘hit_cnter_cur_val_on’ by checking
    --- ‘sq_hit_cnter_on’ and ‘rom_bit_cnter’
    hit_cnter_cur_val_on <= '1' when (  sq_hit_cnter_on = '1' ) and 
                                    ( rom_bit_cnter = '1') else '0';


    -- set the cnter value color
    hit_cnter_rgb <= "100";
    --- Write your VHDL code below:

    graph_rgb <= hit_cnter_rgb when hit_cnter_cur_val_on = '1' else "110";

    -- process (hit_cnter_cur_val_on)
    --     begin
    --     if (hit_cnter_cur_val_on = '1') then
    --         graph_rgb <= hit_cnter_rgb;
    --     else
    --         graph_rgb <= "110"; -- yellow bkgnd
    --     end if;
    -- end process;


    -- set graph_rgb
    
    -- assign output sq_hit_cnter_on_output
    sq_hit_cnter_on_output <= sq_hit_cnter_on;
end Behavioral;

    


    
