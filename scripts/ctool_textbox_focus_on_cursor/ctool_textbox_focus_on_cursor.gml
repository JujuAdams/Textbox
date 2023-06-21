/// ctool_textbox_focus_on_cursor()

function ctool_textbox_focus_on_cursor()
{
    var _cursor_l = 0;
    var _cursor_t = 0;
    var _cursor_r = 0;
    var _cursor_b = textbox_line_height;

    if ((textbox_cursor_pos >= 0) && (textbox_cursor_pos < array_length(textbox_character_array)))
    {
        var _char_array = textbox_character_array[textbox_cursor_pos];
        var _width = _char_array[COOLTOOL_CHARACTER.WIDTH];
        if (_width > 100) _width = 0;
    
        var _cursor_l = _char_array[COOLTOOL_CHARACTER.X];
        var _cursor_t = _char_array[COOLTOOL_CHARACTER.Y];
        var _cursor_r = _width + _cursor_l;
        var _cursor_b = _cursor_t + textbox_line_height;
    }

    var _window_l = textbox_scroll_x;
    var _window_t = textbox_scroll_y;
    var _window_r = _window_l + textbox_width;
    var _window_b = _window_t + textbox_height;

    if (!rectangle_in_rectangle(_cursor_l, _cursor_t, _cursor_r, _cursor_b,
                                _window_l + 3, _window_t + 3, _window_r - 3, _window_b - 3))
    {
        textbox_scroll_x -= max(0, _window_l - _cursor_l);
        textbox_scroll_y -= max(0, _window_t - _cursor_t);
        textbox_scroll_x += max(0, _cursor_r - _window_r);
        textbox_scroll_y += max(0, _cursor_b - _window_b);
    
        textbox_scroll_x = clamp(textbox_scroll_x, 0, max(0, textbox_content_width  - textbox_width ));
        textbox_scroll_y = clamp(textbox_scroll_y, 0, max(0, textbox_content_height - textbox_height));
    }

    if (script_exists(textbox_focus_on_cursor_callback)) script_execute(textbox_focus_on_cursor_callback);
}