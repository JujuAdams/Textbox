/// ctool_textbox_insert_string(string, position, [update])

function ctool_textbox_insert_string()
{
    var _string   = argument[0];
    var _position = textbox_cursor_pos + 1;
    var _update   = true;

    if ((argument_count > 1) && (argument[1] != undefined)) _position = argument[1];
    if ((argument_count > 2) && (argument[2] != undefined)) _update   = argument[2];

    if (_position >= 1)
    {
        _string = string_replace_all(_string, chr(10) + chr(13), chr(13));
        _string = string_replace_all(_string, chr(13) + chr(10), chr(13));
        _string = string_replace_all(_string, chr(8230), "..." ); //"Ellipsis" replacement
        _string = string_replace_all(_string, chr(8211),   "-" ); //"En dash" replacement
        _string = string_replace_all(_string, chr(8212),   "-" ); //"Em dash" replacement
        _string = string_replace_all(_string, chr(8213),   "-" ); //"Horizontal bar" replacement
        _string = string_replace_all(_string, chr(8216),   "'" ); //"Start single quote" replacement
        _string = string_replace_all(_string, chr(8217),   "'" ); //"End single quote" replacement
        _string = string_replace_all(_string, chr(8220),   "\""); //"Start double quote" replacement
        _string = string_replace_all(_string, chr(8221),   "\""); //"End double quote" replacement
        _string = string_replace_all(_string, chr(8222),   "\""); //"Low double quote" replacement
        _string = string_replace_all(_string, chr(8223),   "\""); //"High double quote" replacement
        _string = string_replace_all(_string, chr( 894),   ";" ); //"Greek question mark" replacement
    
        textbox_content = string_insert(_string, textbox_content, _position);
        textbox_cursor_pos += string_length(_string);
        if (_update) ctool_textbox_update();
    }
}