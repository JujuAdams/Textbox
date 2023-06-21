/// ctool_textbox_step(x, y, mouseX, mouseY, mouseState)

function ctool_textbox_step(_textbox_x, _textbox_y, _mouse_x, _mouse_y, _mouse_state)
{
    var _keyboard_key = keyboard_key;

    if (os_is_paused())
    {
        _mouse_state = false;
        textbox_backspace = false;
    }

    //Manually handle backspace to try to work around stuck backspace when refocusing the window
    if (keyboard_check_pressed(vk_backspace)) textbox_backspace = true;
    if (!keyboard_check(vk_backspace)) textbox_backspace = false;
    if (textbox_backspace) _keyboard_key = vk_backspace;

    //These two flags control additional function calls at the end of this function
    var _update         = false;
    var _old_cursor_pos = textbox_cursor_pos;

    textbox_mouse_pressed  = false;
    textbox_mouse_released = false;

    textbox_mouse_over = point_in_rectangle(_mouse_x, _mouse_y, _textbox_x, _textbox_y, _textbox_x + textbox_width, _textbox_y + textbox_height);

    if (_mouse_state)
    {
        if (!textbox_mouse_down && textbox_mouse_over)
        {
            textbox_mouse_pressed = true;
            textbox_mouse_down = true;
        
            with(object_index) textbox_cursor_pos = -1;
        }
    }
    else
    {
        if (textbox_mouse_down)
        {
            textbox_mouse_released = true;
            textbox_mouse_down = false;
        }
    }

    if (textbox_mouse_down)
    {
        textbox_highlight_start =  9999;
        textbox_highlight_end   = -9999;
    }

    if (textbox_mouse_over && (textbox_cursor_pos >= 0))
    {
        textbox_scroll_y += textbox_line_height*(mouse_wheel_down() - mouse_wheel_up());
        textbox_scroll_y = clamp(textbox_scroll_y, 0, max(0, textbox_content_height - textbox_height));
    }

    var _character_at = ctool_textbox_get_character_at(_mouse_x + textbox_scroll_x - _textbox_x, _mouse_y + textbox_scroll_y - _textbox_y);
    if (_character_at != undefined)
    {
        if (textbox_mouse_pressed)
        {
            textbox_cursor_pos = _character_at;
        }
        else if (textbox_mouse_down)
        {
            if (_character_at != textbox_cursor_pos)
            {
                textbox_highlight_start = min(textbox_highlight_start, _character_at, textbox_cursor_pos);
                textbox_highlight_end   = max(textbox_highlight_end  , _character_at, textbox_cursor_pos);
            }
        }
    }

    var _repeat_fire = false;
    if ((_keyboard_key != textbox_key_held) || (textbox_cursor_pos < 0) || os_is_paused())
    {
        textbox_key_held         = undefined;
        textbox_key_repeat       = false;
        textbox_key_pressed_time = -1;
    }
    else if (textbox_key_pressed_time >= 0)
    {
        if (textbox_key_repeat)
        {
            if (current_time - textbox_key_pressed_time > global.ctool_repeat_frequency) _repeat_fire = true;
        }
        else if (current_time - textbox_key_pressed_time > global.ctool_repeat_delay)
        {
            textbox_key_repeat = true;
            _repeat_fire = true;
        }
    }

    if ((textbox_cursor_pos >= 0) && (keyboard_check_pressed(vk_anykey) || _repeat_fire))
    {
        var _valid_input         = true;
        var _overwrite_highlight = false;
        var _command_shortcut    = false;
    
        switch(_keyboard_key)
        {
            case vk_tab:
            case vk_shift:
            case 20: //caps lock
            case vk_control:
            case vk_lcontrol:
            case vk_rcontrol:
                //Ignore these characters
                _valid_input = false;
            break;
        
            case vk_up:
            case vk_down:
            case vk_left:
            case vk_right:
            case vk_home:
            case vk_end:
            case vk_pagedown:
            case vk_pageup:
                //Arrow keys disable highlighting
                textbox_highlight_start =  9999;
                textbox_highlight_end   = -9999;
            break;
        
            default:
                _overwrite_highlight = true;
            break;
        }
    
        //Don't copy/paste/select repeatedly!
        if (keyboard_check(vk_control) && (textbox_key_held != _keyboard_key))
        {
            _valid_input = false;
        
            if (!keyboard_check(vk_shift))
            {
                if (keyboard_check_pressed(ord("V")))
                {
                    //We handle pasting after we remove the highlighted section
                    _overwrite_highlight = true;
                }
                else if (keyboard_check_pressed(ord("C")))
                {
                    if (textbox_highlight_end - textbox_highlight_start > 0)
                    {
                        var _start = textbox_highlight_start + 1;
                        var _end = min(string_length(textbox_content) + 1, textbox_highlight_end + 1);
                        var _string = string_copy(textbox_content, textbox_highlight_start + 1, _end - (textbox_highlight_start + 1));
                        clipboard_set_text(_string);
                    }
                
                    _command_shortcut = true;
                }
                else if (keyboard_check_pressed(ord("A")))
                {
                    textbox_highlight_start = 0;
                    textbox_highlight_end   = array_length(textbox_character_array) - 1;
                
                    _command_shortcut = true;
                }
            }
        }
    
        if (!_command_shortcut)
        {
            var _highlight_size = textbox_highlight_end - textbox_highlight_start;
            if (_overwrite_highlight)
            {
                if ((textbox_highlight_start >= 0) && (textbox_highlight_end < array_length(textbox_character_array)) && (_highlight_size > 0))
                {
                    textbox_content = string_delete(textbox_content, textbox_highlight_start + 1, _highlight_size);
                    _update = true;
                
                    textbox_cursor_pos      = textbox_highlight_start;
                    textbox_highlight_start =  9999;
                    textbox_highlight_end   = -9999;
                
                    if ((_keyboard_key == vk_backspace) || (_keyboard_key == vk_delete)) _valid_input = false;
                }
            }
        
            if (keyboard_check(vk_control) && (textbox_key_held != _keyboard_key))
            {
                //ctrl+shift+number/letter writes a portrait tag into the string
                if (keyboard_check(vk_shift))
                {
                    var _i = 48;
                    repeat(1 + 90 - 48)
                    {
                        if ((_i < 58) || (_i >= 65))
                        {
                            if (keyboard_check_pressed(_i)) ctool_portraits_write_to_textbox("\E" + chr(_i));
                        }
                    
                        ++_i;
                    }
                }
                else if (keyboard_check_pressed(ord("V"))) //ctrl+v pastes text
                {
                    ctool_textbox_insert_string(clipboard_get_text(), undefined, false);
                    _update = true;
                    _valid_input = false;
                }
            }
        
            if (_valid_input)
            {
                switch(_keyboard_key)
                {
                    case vk_enter:
                        textbox_content = string_insert(chr(13), textbox_content, textbox_cursor_pos + 1);
                        ++textbox_cursor_pos;
                        _update = true;
                    break;
                
                    case vk_up:
                        if (textbox_cursor_pos >= 0)
                        {
                            var _char_array = textbox_character_array[textbox_cursor_pos];
                            var _offset = _char_array[COOLTOOL_CHARACTER.WIDTH] div 2;
                            if (_offset > 100) _offset = 1;
                            var _new_char = ctool_textbox_get_character_at(_char_array[COOLTOOL_CHARACTER.X] + _offset, _char_array[COOLTOOL_CHARACTER.Y] - (textbox_line_height div 2));
                            if (_new_char != undefined) textbox_cursor_pos = _new_char;
                        }
                    break;
                
                    case vk_down:
                        if (textbox_cursor_pos >= 0)
                        {
                            var _char_array = textbox_character_array[textbox_cursor_pos];
                            var _offset = _char_array[COOLTOOL_CHARACTER.WIDTH] div 2;
                            if (_offset > 100) _offset = 1;
                            var _new_char = ctool_textbox_get_character_at(_char_array[COOLTOOL_CHARACTER.X] + _offset, _char_array[COOLTOOL_CHARACTER.Y] + 3*(textbox_line_height div 2));
                            if (_new_char != undefined) textbox_cursor_pos = _new_char;
                        }
                    break;
                
                    case vk_home:
                        if (textbox_cursor_pos >= 0)
                        {
                            var _char_array = textbox_character_array[textbox_cursor_pos];
                            var _new_char = ctool_textbox_get_character_at(0, _char_array[COOLTOOL_CHARACTER.Y] + (textbox_line_height div 2));
                            if (_new_char != undefined) textbox_cursor_pos = _new_char;
                        }
                    break;
                
                    case vk_end:
                        if (textbox_cursor_pos >= 0)
                        {
                            var _char_array = textbox_character_array[textbox_cursor_pos];
                            var _new_char = ctool_textbox_get_character_at(textbox_content_width + 999, _char_array[COOLTOOL_CHARACTER.Y] + (textbox_line_height div 2));
                            if (_new_char != undefined) textbox_cursor_pos = _new_char;
                        }
                    break;
                
                    case vk_pagedown:
                        if (textbox_cursor_pos >= 0)
                        {
                            var _char_array = textbox_character_array[textbox_cursor_pos];
                            var _offset = _char_array[COOLTOOL_CHARACTER.WIDTH] div 2;
                            if (_offset > 100) _offset = 1;
                            var _new_char = ctool_textbox_get_character_at(_char_array[COOLTOOL_CHARACTER.X] + _offset, _char_array[COOLTOOL_CHARACTER.Y] + (textbox_line_height div 2) + textbox_height);
                            if (_new_char != undefined) textbox_cursor_pos = _new_char;
                        }
                    break;
                
                    case vk_pageup:
                        if (textbox_cursor_pos >= 0)
                        {
                            var _char_array = textbox_character_array[textbox_cursor_pos];
                            var _offset = _char_array[COOLTOOL_CHARACTER.WIDTH] div 2;
                            if (_offset > 100) _offset = 1;
                            var _new_char = ctool_textbox_get_character_at(_char_array[COOLTOOL_CHARACTER.X] + _offset, _char_array[COOLTOOL_CHARACTER.Y] + (textbox_line_height div 2) - textbox_height);
                            if (_new_char != undefined) textbox_cursor_pos = _new_char;
                        }
                    break;
                
                    case vk_left:
                        textbox_cursor_pos = max(0, textbox_cursor_pos - 1);
                    break;
                
                    case vk_right:
                        textbox_cursor_pos = min(array_length(textbox_character_array) - 1, textbox_cursor_pos + 1);
                    break;
                
                    case vk_backspace:
                        textbox_content = string_delete(textbox_content, textbox_cursor_pos, 1);
                        textbox_cursor_pos = max(0, textbox_cursor_pos - 1);
                        _update = true;
                    break;
                
                    case vk_delete:
                        textbox_content = string_delete(textbox_content, textbox_cursor_pos + 1, 1);
                        _update = true;
                    break;
                
                    default:
                        var _last_char = keyboard_lastchar;
                        if (_last_char == chr(8230)) _last_char = "..."; //Ellipsis replacement
                    
                        textbox_content = string_insert(keyboard_lastchar, textbox_content, textbox_cursor_pos + 1);
                        ++textbox_cursor_pos;
                        _update = true;
                    break;
                }
            }
        }
    
        textbox_key_held = _keyboard_key;
        textbox_key_pressed_time = current_time;
    }

    if (_update) ctool_textbox_update();
    if (_old_cursor_pos != textbox_cursor_pos) ctool_textbox_focus_on_cursor();
}