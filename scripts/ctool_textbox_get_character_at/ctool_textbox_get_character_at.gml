///ctool_textbox_get_character_at(x, y)

function ctool_textbox_get_character_at(_point_x, _point_y)
{
    if (_point_y < 0) return 0;
    if (_point_y > textbox_content_height) return (array_length(textbox_character_array) - 1);

    var _i = 0;
    repeat(array_length(textbox_character_array))
    {
        var _char_array = textbox_character_array[_i];
    
        if (is_array(_char_array))
        {
            var _x     = _char_array[COOLTOOL_CHARACTER.X    ];
            var _y     = _char_array[COOLTOOL_CHARACTER.Y    ];
            var _width = _char_array[COOLTOOL_CHARACTER.WIDTH];
        
            if (point_in_rectangle(_point_x, _point_y, _x, _y, _x + _width, _y + textbox_line_height))
            {
                return _i;
            }
        }
    
        ++_i;
    }
    
    return undefined;
}