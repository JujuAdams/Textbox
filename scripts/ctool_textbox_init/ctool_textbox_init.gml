/// ctool_textbox_init(font, width, height, hashNewline)

function ctool_textbox_init()
{
    textbox_font         = argument0;
    textbox_width        = argument1;
    textbox_height       = argument2;
    textbox_hash_newline = argument3;

    textbox_scroll_x = 0;
    textbox_scroll_y = 0;

    textbox_content           = "";
    textbox_content_width     = 0;
    textbox_content_height    = 0;
    textbox_character_array   = array_create(0);
    textbox_line_colour_array = array_create(0);

    textbox_colour_background = $262626;
    textbox_colour_border     = c_white;
    textbox_colour_text       = c_white;
    textbox_border_thickness  = 2;
    textbox_padding           = 3;

    textbox_update_callback          = -1;
    textbox_focus_on_cursor_callback = -1;

    textbox_cursor_pos      = -1;
    textbox_highlight_start = -1;
    textbox_highlight_end   = -1;

    textbox_mouse_over       = false;
    textbox_mouse_pressed    = false;
    textbox_mouse_released   = false;
    textbox_mouse_down       = false;

    textbox_key_held         = undefined;
    textbox_key_repeat       = false;
    textbox_key_pressed_time = -1;
    textbox_backspace        = false;

    draw_set_font(textbox_font);
    textbox_line_height = string_height(chr(13));
    draw_set_font(-1);

    ctool_textbox_update();

    enum COOLTOOL_CHARACTER
    {
        CHAR,
        X,
        Y,
        WIDTH,
        LINE,
        __SIZE
    }
}