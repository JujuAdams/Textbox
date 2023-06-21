function ctool_textbox_update()
{
    draw_set_font(textbox_font);

    textbox_content = string_replace_all(textbox_content, chr(10) + chr(13), chr(13));
    textbox_content = string_replace_all(textbox_content, chr(13) + chr(10), chr(13));

    textbox_content_width  = 0;
    textbox_content_height = 0;

    var _length = string_length(textbox_content);
    textbox_character_array = array_create(0);

    var _x    = 0;
    var _y    = 0;
    var _line = 0;
    var _c    = 1;
    repeat(_length)
    {
        var _char = string_char_at(textbox_content, _c);
        var _ord = ord(_char);
    
        if ((_ord == 10) || (_ord == 13) || (textbox_hash_newline && (_ord == 35)))
        {
            ctool_textbox_add_internal_character(_char, _x, _y, _line, 9999);
        
            _x  = 0;
            _y += textbox_line_height;
            ++_line;
        }
        else if (_ord >= 32)
        {
            var _width = string_width(_char);
            ctool_textbox_add_internal_character(_char, _x, _y, _line, _width);
        
            _x += _width;
            textbox_content_width = max(textbox_content_width, _x);
        }
    
        ++_c;
    }

    ctool_textbox_add_internal_character("", _x, _y, _line, 9999);

    textbox_content_height = _y + textbox_line_height;
    textbox_cursor_pos = clamp(textbox_cursor_pos, -1, array_length(textbox_character_array) - 1);

    draw_set_font(-1);

    if (script_exists(textbox_update_callback)) script_execute(textbox_update_callback);
}