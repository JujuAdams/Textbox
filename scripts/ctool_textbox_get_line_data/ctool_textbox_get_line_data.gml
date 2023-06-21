/// ctool_textbox_get_line_data()

function ctool_textbox_get_line_data()
{
    var _array = array_create(4);
    _array[@ 0] = "";        //line string
    _array[@ 1] = undefined; //line start
    _array[@ 2] = undefined; //line end
    _array[@ 3] = undefined; //character name

    if (textbox_cursor_pos < 0) return _array;

    var _line_start = 1;
    var _line_end   = string_length(textbox_content);

    var _i = textbox_cursor_pos;
    repeat(999)
    {
        if (string_char_at(textbox_content, _i) == chr(13))
        {
            _line_start = _i + 1;
            break;
        }
    
        --_i;
    }

    var _i = textbox_cursor_pos + 1;
    repeat(999)
    {
        if (string_char_at(textbox_content, _i) == chr(13))
        {
            _line_end = _i - 1;
            break;
        }
    
        ++_i;
    }

    _array[@ 1] = _line_start;
    _array[@ 2] = _line_end;

    var _line_string = string_copy(textbox_content, _line_start, 1 + _line_end - _line_start);
    _array[@ 0] = _line_string;

    var _colon_pos = string_pos(":", _line_string);
    if (_colon_pos > 0)
    {
        var _name = string_copy(_line_string, 1, _colon_pos - 1);
        _name = ctool_name_from_alias(_name);
        _name = ctool_name_from_initial(_name);
        _array[@ 3] = _name;
    }

    return _array;
}