/// ctool_textbox_add_internal_character(character, x, y, line, width)

function ctool_textbox_add_internal_character()
{
    var _array = array_create(COOLTOOL_CHARACTER.__SIZE);
    _array[@ COOLTOOL_CHARACTER.CHAR ] = argument0;
    _array[@ COOLTOOL_CHARACTER.X    ] = argument1;
    _array[@ COOLTOOL_CHARACTER.Y    ] = argument2;
    _array[@ COOLTOOL_CHARACTER.LINE ] = argument3;
    _array[@ COOLTOOL_CHARACTER.WIDTH] = argument4;
    textbox_character_array[@ array_length(textbox_character_array)] = _array;

    return _array;
}