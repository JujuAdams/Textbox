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
    
    __font   = _font;
    __width  = _width;
    __height = _height;
    
    __scroll_x = 0;
    __scroll_y = 0;
    
    __content           = "";
    __content_width     = 0;
    __content_height    = 0;
    __character_array   = array_create(0);
    __line_colour_array = array_create(0);
    
    __colour_background = $262626;
    __colour_border     = c_white;
    __colour_text       = c_white;
    __border_thickness  = 2;
    __padding           = 3;
    
    __update_callback          = -1;
    __focus_on_cursor_callback = -1;
    
    __cursor_pos      = -1;
    __highlight_start = -1;
    __highlight_end   = -1;
    
    __mouse_over       = false;
    __mouse_pressed    = false;
    __mouse_released   = false;
    __mouse_down       = false;
    
    __key_held         = undefined;
    __key_repeat       = false;
    __key_pressed_time = -1;
    __backspace        = false;
    
    draw_set_font(__font);
    __line_height = string_height(chr(13));
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
        __cursor_pos = -1;
    }
    
    static InsertString = function(_string, _position = __cursor_pos+1, _update = true)
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
            
            __content = string_insert(_string, __content, _position);
            __cursor_pos += string_length(_string);
            if (_update) __Update();
        }
    }
    
    static Step = function(___x, ___y, _mouse_x, _mouse_y, _mouse_state)
    {
        var _keyboard_key = keyboard_key;

        if (os_is_paused())
        {
            _mouse_state = false;
            __backspace = false;
        }
        
        //Manually handle backspace to try to work around stuck backspace when refocusing the window
        if (keyboard_check_pressed(vk_backspace)) __backspace = true;
        if (!keyboard_check(vk_backspace)) __backspace = false;
        if (__backspace) _keyboard_key = vk_backspace;

        //These two flags control additional function calls at the end of this function
        var _update         = false;
        var _old_cursor_pos = __cursor_pos;

        __mouse_pressed  = false;
        __mouse_released = false;

        __mouse_over = point_in_rectangle(_mouse_x, _mouse_y, ___x, ___y, ___x + __width, ___y + __height);

        if (_mouse_state)
        {
            if (!__mouse_down && __mouse_over)
            {
                __mouse_pressed = true;
                __mouse_down = true;
        
                //TODO - Unfocus all other textboxes
            }
        }
        else
        {
            if (__mouse_down)
            {
                __mouse_released = true;
                __mouse_down = false;
            }
        }

        if (__mouse_down)
        {
            __highlight_start =  9999;
            __highlight_end   = -9999;
        }

        if (__mouse_over && (__cursor_pos >= 0))
        {
            __scroll_y += __line_height*(mouse_wheel_down() - mouse_wheel_up());
            __scroll_y = clamp(__scroll_y, 0, max(0, __content_height - __height));
        }

        var _character_at = __GetCharacterAt(_mouse_x + __scroll_x - ___x, _mouse_y + __scroll_y - ___y);
        if (_character_at != undefined)
        {
            if (__mouse_pressed)
            {
                __cursor_pos = _character_at;
            }
            else if (__mouse_down)
            {
                if (_character_at != __cursor_pos)
                {
                    __highlight_start = min(__highlight_start, _character_at, __cursor_pos);
                    __highlight_end   = max(__highlight_end  , _character_at, __cursor_pos);
                }
            }
        }

        var _repeat_fire = false;
        if ((_keyboard_key != __key_held) || (__cursor_pos < 0) || os_is_paused())
        {
            __key_held         = undefined;
            __key_repeat       = false;
            __key_pressed_time = -1;
        }
        else if (__key_pressed_time >= 0)
        {
            if (__key_repeat)
            {
                if (current_time - __key_pressed_time > TEXTBOX_REPEAT_FREQUENCY) _repeat_fire = true;
            }
            else if (current_time - __key_pressed_time > TEXTBOX_REPEAT_DELAY)
            {
                __key_repeat = true;
                _repeat_fire = true;
            }
        }

        if ((__cursor_pos >= 0) && (keyboard_check_pressed(vk_anykey) || _repeat_fire))
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
                    __highlight_start =  9999;
                    __highlight_end   = -9999;
                break;
        
                default:
                    _overwrite_highlight = true;
                break;
            }
    
            //Don't copy/paste/select repeatedly!
            if (keyboard_check(vk_control) && (__key_held != _keyboard_key))
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
                        if (__highlight_end - __highlight_start > 0)
                        {
                            var _start = __highlight_start + 1;
                            var _end = min(string_length(__content) + 1, __highlight_end + 1);
                            var _string = string_copy(__content, __highlight_start + 1, _end - (__highlight_start + 1));
                            clipboard_set_text(_string);
                        }
                
                        _command_shortcut = true;
                    }
                    else if (keyboard_check_pressed(ord("A")))
                    {
                        __highlight_start = 0;
                        __highlight_end   = array_length(__character_array) - 1;
                
                        _command_shortcut = true;
                    }
                }
            }
    
            if (!_command_shortcut)
            {
                var _highlight_size = __highlight_end - __highlight_start;
                if (_overwrite_highlight)
                {
                    if ((__highlight_start >= 0) && (__highlight_end < array_length(__character_array)) && (_highlight_size > 0))
                    {
                        __content = string_delete(__content, __highlight_start + 1, _highlight_size);
                        _update = true;
                
                        __cursor_pos      = __highlight_start;
                        __highlight_start =  9999;
                        __highlight_end   = -9999;
                
                        if ((_keyboard_key == vk_backspace) || (_keyboard_key == vk_delete)) _valid_input = false;
                    }
                }
        
                if (keyboard_check(vk_control) && (__key_held != _keyboard_key))
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
                            __content = string_insert(chr(13), __content, __cursor_pos + 1);
                            ++__cursor_pos;
                            _update = true;
                        break;
                
                        case vk_up:
                            if (__cursor_pos >= 0)
                            {
                                var _char_array = __character_array[__cursor_pos];
                                var _offset = _char_array[COOLTOOL_CHARACTER.WIDTH] div 2;
                                if (_offset > 100) _offset = 1;
                                var _new_char = __GetCharacterAt(_char_array[COOLTOOL_CHARACTER.X] + _offset, _char_array[COOLTOOL_CHARACTER.Y] - (__line_height div 2));
                                if (_new_char != undefined) __cursor_pos = _new_char;
                            }
                        break;
                
                        case vk_down:
                            if (__cursor_pos >= 0)
                            {
                                var _char_array = __character_array[__cursor_pos];
                                var _offset = _char_array[COOLTOOL_CHARACTER.WIDTH] div 2;
                                if (_offset > 100) _offset = 1;
                                var _new_char = __GetCharacterAt(_char_array[COOLTOOL_CHARACTER.X] + _offset, _char_array[COOLTOOL_CHARACTER.Y] + 3*(__line_height div 2));
                                if (_new_char != undefined) __cursor_pos = _new_char;
                            }
                        break;
                
                        case vk_home:
                            if (__cursor_pos >= 0)
                            {
                                var _char_array = __character_array[__cursor_pos];
                                var _new_char = __GetCharacterAt(0, _char_array[COOLTOOL_CHARACTER.Y] + (__line_height div 2));
                                if (_new_char != undefined) __cursor_pos = _new_char;
                            }
                        break;
                
                        case vk_end:
                            if (__cursor_pos >= 0)
                            {
                                var _char_array = __character_array[__cursor_pos];
                                var _new_char = __GetCharacterAt(__content_width + 999, _char_array[COOLTOOL_CHARACTER.Y] + (__line_height div 2));
                                if (_new_char != undefined) __cursor_pos = _new_char;
                            }
                        break;
                
                        case vk_pagedown:
                            if (__cursor_pos >= 0)
                            {
                                var _char_array = __character_array[__cursor_pos];
                                var _offset = _char_array[COOLTOOL_CHARACTER.WIDTH] div 2;
                                if (_offset > 100) _offset = 1;
                                var _new_char = __GetCharacterAt(_char_array[COOLTOOL_CHARACTER.X] + _offset, _char_array[COOLTOOL_CHARACTER.Y] + (__line_height div 2) + __height);
                                if (_new_char != undefined) __cursor_pos = _new_char;
                            }
                        break;
                
                        case vk_pageup:
                            if (__cursor_pos >= 0)
                            {
                                var _char_array = __character_array[__cursor_pos];
                                var _offset = _char_array[COOLTOOL_CHARACTER.WIDTH] div 2;
                                if (_offset > 100) _offset = 1;
                                var _new_char = __GetCharacterAt(_char_array[COOLTOOL_CHARACTER.X] + _offset, _char_array[COOLTOOL_CHARACTER.Y] + (__line_height div 2) - __height);
                                if (_new_char != undefined) __cursor_pos = _new_char;
                            }
                        break;
                
                        case vk_left:
                            __cursor_pos = max(0, __cursor_pos - 1);
                        break;
                
                        case vk_right:
                            __cursor_pos = min(array_length(__character_array) - 1, __cursor_pos + 1);
                        break;
                
                        case vk_backspace:
                            __content = string_delete(__content, __cursor_pos, 1);
                            __cursor_pos = max(0, __cursor_pos - 1);
                            _update = true;
                        break;
                
                        case vk_delete:
                            __content = string_delete(__content, __cursor_pos + 1, 1);
                            _update = true;
                        break;
                
                        default:
                            var _last_char = keyboard_lastchar;
                            if (_last_char == chr(8230)) _last_char = "..."; //Ellipsis replacement
                    
                            __content = string_insert(keyboard_lastchar, __content, __cursor_pos + 1);
                            ++__cursor_pos;
                            _update = true;
                        break;
                    }
                }
            }
    
            __key_held = _keyboard_key;
            __key_pressed_time = current_time;
        }

        if (_update) __Update();
        if (_old_cursor_pos != __cursor_pos) __FocusOnCursor();
    }
    
    static Draw = function(___x, ___y)
    {
        matrix_set(matrix_world, matrix_build(___x, ___y, 0,   0,0,0,   1,1,1));
        
        draw_set_colour(__colour_border);
        draw_rectangle(-__padding - __border_thickness,
                       -__padding - __border_thickness,
                        __padding + __border_thickness + __width,
                        __padding + __border_thickness + __height,
                        false);
        
        draw_set_colour(__colour_background);
        draw_rectangle(-__padding,
                       -__padding,
                        __padding + __width,
                        __padding + __height,
                        false);
        
        if (__content_width > __width)
        {
            var _t = clamp(__scroll_x / (__content_width - __width), 0.0, 1.0);
            var _x = lerp(5, __width - 5, _t);
            
            draw_set_colour(__colour_border);
            draw_rectangle(__border_thickness + _x - 2,
                           __padding - 4 + __height,
                           __border_thickness + _x + 2,
                           __padding + 4 + __border_thickness + __height,
                           false);
        }
        
        if (__content_height > __height)
        {
            var _t = clamp(__scroll_y / (__content_height - __height), 0.0, 1.0);
            var _y = lerp(5, __height - 5, _t);
            
            draw_set_colour(__colour_border);
            draw_rectangle(__padding - 4 + __width,
                           __border_thickness + _y - 2,
                           __padding + 4 + __border_thickness + __width,
                           __border_thickness + _y + 2,
                           false);
        }
        
        matrix_set(matrix_world, matrix_multiply(matrix_get(matrix_world),
                                                 matrix_build(-__scroll_x, -__scroll_y, 0,    0,0,0,   1,1,1)));
        
        draw_set_colour(__colour_text);
        draw_set_font(__font);
        __SetWindow(___x-1, ___y, ___x + __width, ___y + __height);
        
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
        repeat(array_length(__character_array))
        {
            var _char_array = __character_array[_i];
            
            if (is_array(_char_array))
            {
                var _char  = _char_array[COOLTOOL_CHARACTER.CHAR ];
                var _x     = _char_array[COOLTOOL_CHARACTER.X    ];
                var _y     = _char_array[COOLTOOL_CHARACTER.Y    ];
                var _line  = _char_array[COOLTOOL_CHARACTER.LINE ];
                var _width = _char_array[COOLTOOL_CHARACTER.WIDTH];
                
                if ((_i >= __highlight_start) && (_i < __highlight_end))
                {
                    draw_text(_x, _y, _char);
                    __VertexBufferAddRect(_vbuff, _x, _y, _x + _width, _y + __line_height, __colour_text, 0.3);
                }
                else
                {
                    draw_text(_x, _y, _char);
                    if (__cursor_pos == _i) __VertexBufferAddRect(_vbuff, _x - 1, _y, _x, _y + __line_height, __colour_text, 1.0);
                    
                    if (_line < array_length(__line_colour_array))
                    {
                        var _line_colour = __line_colour_array[_line];
                        if (_line_colour != c_black)
                        {
                            __VertexBufferAddRect(_vbuff, _x, _y, _x + _width, _y + __line_height, _line_colour, 0.3);
                            draw_set_colour(__colour_text);
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
        
        //draw_rectangle(0, 0, __content_width, __content_height, true);
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
        __character_array[@ array_length(__character_array)] = _array;
        return _array;
    }
    
    static __FocusOnCursor = function()
    {
        var _cursor_l = 0;
        var _cursor_t = 0;
        var _cursor_r = 0;
        var _cursor_b = __line_height;
        
        if ((__cursor_pos >= 0) && (__cursor_pos < array_length(__character_array)))
        {
            var _char_array = __character_array[__cursor_pos];
            var _width = _char_array[COOLTOOL_CHARACTER.WIDTH];
            if (_width > 100) _width = 0;
            
            var _cursor_l = _char_array[COOLTOOL_CHARACTER.X];
            var _cursor_t = _char_array[COOLTOOL_CHARACTER.Y];
            var _cursor_r = _width + _cursor_l;
            var _cursor_b = _cursor_t + __line_height;
        }
        
        var _window_l = __scroll_x;
        var _window_t = __scroll_y;
        var _window_r = _window_l + __width;
        var _window_b = _window_t + __height;
        
        if (!rectangle_in_rectangle(_cursor_l, _cursor_t, _cursor_r, _cursor_b,
                                    _window_l + 3, _window_t + 3, _window_r - 3, _window_b - 3))
        {
            __scroll_x -= max(0, _window_l - _cursor_l);
            __scroll_y -= max(0, _window_t - _cursor_t);
            __scroll_x += max(0, _cursor_r - _window_r);
            __scroll_y += max(0, _cursor_b - _window_b);
    
            __scroll_x = clamp(__scroll_x, 0, max(0, __content_width  - __width ));
            __scroll_y = clamp(__scroll_y, 0, max(0, __content_height - __height));
        }
        
        if (script_exists(__focus_on_cursor_callback)) script_execute(__focus_on_cursor_callback);
    }
    
    static __GetCharacterAt = function(_point_x, _point_y)
    {
        if (_point_y < 0) return 0;
        if (_point_y > __content_height) return (array_length(__character_array) - 1);
        
        var _i = 0;
        repeat(array_length(__character_array))
        {
            var _char_array = __character_array[_i];
            
            if (is_array(_char_array))
            {
                var _x     = _char_array[COOLTOOL_CHARACTER.X    ];
                var _y     = _char_array[COOLTOOL_CHARACTER.Y    ];
                var _width = _char_array[COOLTOOL_CHARACTER.WIDTH];
                
                if (point_in_rectangle(_point_x, _point_y, _x, _y, _x + _width, _y + __line_height))
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
        draw_set_font(__font);

        __content = string_replace_all(__content, chr(10) + chr(13), chr(13));
        __content = string_replace_all(__content, chr(13) + chr(10), chr(13));

        __content_width  = 0;
        __content_height = 0;

        var _length = string_length(__content);
        __character_array = array_create(0);

        var _x    = 0;
        var _y    = 0;
        var _line = 0;
        var _c    = 1;
        repeat(_length)
        {
            var _char = string_char_at(__content, _c);
            var _ord = ord(_char);
            
            if ((_ord == 10) || (_ord == 13))
            {
                __AddInternalCharacter(_char, _x, _y, _line, 9999);
                
                _x  = 0;
                _y += __line_height;
                ++_line;
            }
            else if (_ord >= 32)
            {
                var _width = string_width(_char);
                __AddInternalCharacter(_char, _x, _y, _line, _width);
                
                _x += _width;
                __content_width = max(__content_width, _x);
            }
            
            ++_c;
        }
        
        __AddInternalCharacter("", _x, _y, _line, 9999);
        
        __content_height = _y + __line_height;
        __cursor_pos = clamp(__cursor_pos, -1, array_length(__character_array) - 1);
        
        draw_set_font(-1);
        
        if (script_exists(__update_callback)) script_execute(__update_callback);
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