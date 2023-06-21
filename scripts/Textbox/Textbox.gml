/// @param font
/// @param width
/// @param height
/// @param [hashNewline=false]

#macro TEXTBOX_REPEAT_DELAY      450
#macro TEXTBOX_REPEAT_FREQUENCY   60

function Textbox(_font, _width, _height) constructor
{
    static _vertex_format = undefined;
    if (_vertex_format == undefined)
    {
        vertex_format_begin();
        vertex_format_add_position_3d();
        vertex_format_add_colour();
        vertex_format_add_texcoord();
        _vertex_format = vertex_format_end();
    }
    
    textbox_font   = _font;
    textbox_width  = _width;
    textbox_height = _height;
    
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
    
    __Update();
    
    
    
    enum COOLTOOL_CHARACTER
    {
        CHAR,
        X,
        Y,
        WIDTH,
        LINE,
        __SIZE
    }
    
    
    
    #region Public
    
    static Unfocus = function()
    {
        textbox_cursor_pos = -1;
    }
    
    static InsertString = function(_string, _position = textbox_cursor_pos+1, _update = true)
    {
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
            if (_update) __Update();
        }
    }
    
    static Step = function(_textbox_x, _textbox_y, _mouse_x, _mouse_y, _mouse_state)
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
        
                //TODO - Unfocus all other textboxes
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

        var _character_at = __GetCharacterAt(_mouse_x + textbox_scroll_x - _textbox_x, _mouse_y + textbox_scroll_y - _textbox_y);
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
                if (current_time - textbox_key_pressed_time > TEXTBOX_REPEAT_FREQUENCY) _repeat_fire = true;
            }
            else if (current_time - textbox_key_pressed_time > TEXTBOX_REPEAT_DELAY)
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
                case vk_alt:
                case vk_lalt:
                case vk_ralt:
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
                    if (keyboard_check_pressed(ord("V"))) //ctrl+v pastes text
                    {
                        InsertString(clipboard_get_text(), undefined, false);
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
                                var _new_char = __GetCharacterAt(_char_array[COOLTOOL_CHARACTER.X] + _offset, _char_array[COOLTOOL_CHARACTER.Y] - (textbox_line_height div 2));
                                if (_new_char != undefined) textbox_cursor_pos = _new_char;
                            }
                        break;
                
                        case vk_down:
                            if (textbox_cursor_pos >= 0)
                            {
                                var _char_array = textbox_character_array[textbox_cursor_pos];
                                var _offset = _char_array[COOLTOOL_CHARACTER.WIDTH] div 2;
                                if (_offset > 100) _offset = 1;
                                var _new_char = __GetCharacterAt(_char_array[COOLTOOL_CHARACTER.X] + _offset, _char_array[COOLTOOL_CHARACTER.Y] + 3*(textbox_line_height div 2));
                                if (_new_char != undefined) textbox_cursor_pos = _new_char;
                            }
                        break;
                
                        case vk_home:
                            if (textbox_cursor_pos >= 0)
                            {
                                var _char_array = textbox_character_array[textbox_cursor_pos];
                                var _new_char = __GetCharacterAt(0, _char_array[COOLTOOL_CHARACTER.Y] + (textbox_line_height div 2));
                                if (_new_char != undefined) textbox_cursor_pos = _new_char;
                            }
                        break;
                
                        case vk_end:
                            if (textbox_cursor_pos >= 0)
                            {
                                var _char_array = textbox_character_array[textbox_cursor_pos];
                                var _new_char = __GetCharacterAt(textbox_content_width + 999, _char_array[COOLTOOL_CHARACTER.Y] + (textbox_line_height div 2));
                                if (_new_char != undefined) textbox_cursor_pos = _new_char;
                            }
                        break;
                
                        case vk_pagedown:
                            if (textbox_cursor_pos >= 0)
                            {
                                var _char_array = textbox_character_array[textbox_cursor_pos];
                                var _offset = _char_array[COOLTOOL_CHARACTER.WIDTH] div 2;
                                if (_offset > 100) _offset = 1;
                                var _new_char = __GetCharacterAt(_char_array[COOLTOOL_CHARACTER.X] + _offset, _char_array[COOLTOOL_CHARACTER.Y] + (textbox_line_height div 2) + textbox_height);
                                if (_new_char != undefined) textbox_cursor_pos = _new_char;
                            }
                        break;
                
                        case vk_pageup:
                            if (textbox_cursor_pos >= 0)
                            {
                                var _char_array = textbox_character_array[textbox_cursor_pos];
                                var _offset = _char_array[COOLTOOL_CHARACTER.WIDTH] div 2;
                                if (_offset > 100) _offset = 1;
                                var _new_char = __GetCharacterAt(_char_array[COOLTOOL_CHARACTER.X] + _offset, _char_array[COOLTOOL_CHARACTER.Y] + (textbox_line_height div 2) - textbox_height);
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

        if (_update) __Update();
        if (_old_cursor_pos != textbox_cursor_pos) __FocusOnCursor();
    }
    
    static Draw = function(_textbox_x, _textbox_y)
    {
        matrix_set(matrix_world, matrix_build(_textbox_x, _textbox_y, 0,   0,0,0,   1,1,1));
        
        draw_set_colour(textbox_colour_border);
        draw_rectangle(-textbox_padding - textbox_border_thickness,
                       -textbox_padding - textbox_border_thickness,
                        textbox_padding + textbox_border_thickness + textbox_width,
                        textbox_padding + textbox_border_thickness + textbox_height,
                        false);
        
        draw_set_colour(textbox_colour_background);
        draw_rectangle(-textbox_padding,
                       -textbox_padding,
                        textbox_padding + textbox_width,
                        textbox_padding + textbox_height,
                        false);
        
        if (textbox_content_width > textbox_width)
        {
            var _t = clamp(textbox_scroll_x / (textbox_content_width - textbox_width), 0.0, 1.0);
            var _x = lerp(5, textbox_width - 5, _t);
            
            draw_set_colour(textbox_colour_border);
            draw_rectangle(textbox_border_thickness + _x - 2,
                           textbox_padding - 4 + textbox_height,
                           textbox_border_thickness + _x + 2,
                           textbox_padding + 4 + textbox_border_thickness + textbox_height,
                           false);
        }
        
        if (textbox_content_height > textbox_height)
        {
            var _t = clamp(textbox_scroll_y / (textbox_content_height - textbox_height), 0.0, 1.0);
            var _y = lerp(5, textbox_height - 5, _t);
            
            draw_set_colour(textbox_colour_border);
            draw_rectangle(textbox_padding - 4 + textbox_width,
                           textbox_border_thickness + _y - 2,
                           textbox_padding + 4 + textbox_border_thickness + textbox_width,
                           textbox_border_thickness + _y + 2,
                           false);
        }
        
        matrix_set(matrix_world, matrix_multiply(matrix_get(matrix_world),
                                                 matrix_build(-textbox_scroll_x, -textbox_scroll_y, 0,    0,0,0,   1,1,1)));
        
        draw_set_colour(textbox_colour_text);
        draw_set_font(textbox_font);
        __SetWindow(_textbox_x-1, _textbox_y, _textbox_x + textbox_width, _textbox_y + textbox_height);
        
        //Create a vertex buffer for all the rectangles
        var _vbuff = vertex_create_buffer();
        vertex_begin(_vbuff, _vertex_format);
        
        //Add in a degenerate triangle to stop GameMaker complaining about empty vertex buffers
        repeat(3)
        {
            vertex_position_3d(_vbuff, 0, 0, 0);
            vertex_colour(_vbuff, c_black, 0.0);
            vertex_texcoord(_vbuff, 0.5, 0.5);
        }
        
        var _i = 0;
        repeat(array_length(textbox_character_array))
        {
            var _char_array = textbox_character_array[_i];
            
            if (is_array(_char_array))
            {
                var _char  = _char_array[COOLTOOL_CHARACTER.CHAR ];
                var _x     = _char_array[COOLTOOL_CHARACTER.X    ];
                var _y     = _char_array[COOLTOOL_CHARACTER.Y    ];
                var _line  = _char_array[COOLTOOL_CHARACTER.LINE ];
                var _width = _char_array[COOLTOOL_CHARACTER.WIDTH];
                
                if ((_i >= textbox_highlight_start) && (_i < textbox_highlight_end))
                {
                    draw_text(_x, _y, _char);
                    __VertexBufferAddRect(_vbuff, _x, _y, _x + _width, _y + textbox_line_height, textbox_colour_text, 0.3);
                }
                else
                {
                    draw_text(_x, _y, _char);
                    if (textbox_cursor_pos == _i) __VertexBufferAddRect(_vbuff, _x - 1, _y, _x, _y + textbox_line_height, textbox_colour_text, 1.0);
                    
                    if (_line < array_length(textbox_line_colour_array))
                    {
                        var _line_colour = textbox_line_colour_array[_line];
                        if (_line_colour != c_black)
                        {
                            __VertexBufferAddRect(_vbuff, _x, _y, _x + _width, _y + textbox_line_height, _line_colour, 0.3);
                            draw_set_colour(textbox_colour_text);
                        }
                    }
                }
            }
            
            ++_i;
        }
        
        //Submit the vertex buffer and clear it up
        vertex_end(_vbuff);
        vertex_submit(_vbuff, pr_trianglelist, sprite_get_texture(__textboxWhitePixel, 0));
        vertex_delete_buffer(_vbuff);
        
        //draw_rectangle(0, 0, textbox_content_width, textbox_content_height, true);
        matrix_set(matrix_world, matrix_build_identity());
        draw_set_font(-1);
        draw_set_color(c_white);
        shader_reset();
    }
    
    #endregion
    
    
    
    #region Private
    
    static __AddInternalCharacter = function(_character, _x, _y, _line, _width)
    {
        var _array = array_create(COOLTOOL_CHARACTER.__SIZE);
        _array[@ COOLTOOL_CHARACTER.CHAR ] = _character;
        _array[@ COOLTOOL_CHARACTER.X    ] = _x;
        _array[@ COOLTOOL_CHARACTER.Y    ] = _y;
        _array[@ COOLTOOL_CHARACTER.LINE ] = _line;
        _array[@ COOLTOOL_CHARACTER.WIDTH] = _width;
        textbox_character_array[@ array_length(textbox_character_array)] = _array;
        return _array;
    }
    
    static __FocusOnCursor = function()
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
    
    static __GetCharacterAt = function(_point_x, _point_y)
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
    
    static __Update = function()
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
            
            if ((_ord == 10) || (_ord == 13))
            {
                __AddInternalCharacter(_char, _x, _y, _line, 9999);
                
                _x  = 0;
                _y += textbox_line_height;
                ++_line;
            }
            else if (_ord >= 32)
            {
                var _width = string_width(_char);
                __AddInternalCharacter(_char, _x, _y, _line, _width);
                
                _x += _width;
                textbox_content_width = max(textbox_content_width, _x);
            }
            
            ++_c;
        }
        
        __AddInternalCharacter("", _x, _y, _line, 9999);
        
        textbox_content_height = _y + textbox_line_height;
        textbox_cursor_pos = clamp(textbox_cursor_pos, -1, array_length(textbox_character_array) - 1);
        
        draw_set_font(-1);
        
        if (script_exists(textbox_update_callback)) script_execute(textbox_update_callback);
    }
    
    static __SetWindow = function(_l, _t, _r, _b, _fog_colour = undefined)
    {
        static _textboxShader_u_vWindow    = shader_get_uniform(__textboxShader, "u_vWindow");
        static _textboxShader_u_vFogColour = shader_get_uniform(__textboxShader, "u_vFogColour");
        
        shader_set(__textboxShader);
        shader_set_uniform_f(_textboxShader_u_vWindow, _l, _t, _r, _b);
        
        if (_fog_colour == undefined)
        {
            shader_set_uniform_f(_textboxShader_u_vFogColour, 0.0, 0.0, 0.0, 0.0);
        }
        else
        {
            var _red   = colour_get_red(  _fog_colour)/255;
            var _green = colour_get_green(_fog_colour)/255;
            var _blue  = colour_get_blue( _fog_colour)/255;
            shader_set_uniform_f(_textboxShader_u_vFogColour,_red, _green, _blue, 1.0);
        }
    }
    
    static __VertexBufferAddRect = function(_vbuff, _x1, _y1, _x2, _y2, _colour, _alpha)
    {
        vertex_position_3d(_vbuff, _x1, _y1, 0); vertex_colour(_vbuff, _colour, _alpha); vertex_texcoord(_vbuff, 0.5, 0.5);
        vertex_position_3d(_vbuff, _x2, _y1, 0); vertex_colour(_vbuff, _colour, _alpha); vertex_texcoord(_vbuff, 0.5, 0.5);
        vertex_position_3d(_vbuff, _x1, _y2, 0); vertex_colour(_vbuff, _colour, _alpha); vertex_texcoord(_vbuff, 0.5, 0.5);
        vertex_position_3d(_vbuff, _x2, _y1, 0); vertex_colour(_vbuff, _colour, _alpha); vertex_texcoord(_vbuff, 0.5, 0.5);
        vertex_position_3d(_vbuff, _x2, _y2, 0); vertex_colour(_vbuff, _colour, _alpha); vertex_texcoord(_vbuff, 0.5, 0.5);
        vertex_position_3d(_vbuff, _x1, _y2, 0); vertex_colour(_vbuff, _colour, _alpha); vertex_texcoord(_vbuff, 0.5, 0.5);
    }
    
    #endregion
}