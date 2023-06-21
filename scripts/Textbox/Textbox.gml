/// @param font
/// @param width
/// @param height

#macro TEXTBOX_REPEAT_DELAY      450
#macro TEXTBOX_REPEAT_FREQUENCY   60

function Textbox(_font, _width, _height) constructor
{
    static _vertexFormat = undefined;
    if (_vertexFormat == undefined)
    {
        vertex_format_begin();
        vertex_format_add_position_3d();
        vertex_format_add_colour();
        vertex_format_add_texcoord();
        _vertexFormat = vertex_format_end();
    }
    
    
    
    __font   = _font;
    __width  = _width;
    __height = _height;
    
    __scrollX = 0;
    __scrollY = 0;
    
    __content         = "";
    __contentWidth    = 0;
    __contentHeight   = 0;
    __characterArray  = array_create(0);
    __lineColourArray = array_create(0);
    
    __colourBackground = $262626;
    __colourBorder     = c_white;
    __colourText       = c_white;
    __borderThickness  = 2;
    __padding          = 3;
    
    __updateCallback        = -1;
    __focusOnCursorCallback = -1;
    
    __focus          = false;
    __cursorPos      = -1;
    __highlightStart = -1;
    __highlightEnd   = -1;
    __canType        = true;
    
    __returnBehavior = 0;
    __returnPressed  = false;
    
    __mouseOver     = false;
    __mousePressed  = false;
    __mouseReleased = false;
    __mouseDown     = false;
    
    __keyHeld        = undefined;
    __keyRepeat      = false;
    __keyPressedTime = -1;
    __backspace       = false;
    
    draw_set_font(__font);
    __lineHeight = string_height(chr(13));
    draw_set_font(-1);
    
    __Update();
    
    
    
    #region Public
    
    static GetContent = function()
    {
        return __content;
    }
    
    static SetContent = function(_content, _update = true)
    {
        __content = _content;
        if (_update) __Update();
    }
    
    static AppendContent = function(_content, _update = true)
    {
        __content += _content;
        if (_update) __Update();
        __scrollY = max(0, __contentHeight - __height);
    }
    
    static GetCanType = function()
    {
        return __canType;
    }
    
    static SetCanType = function(_state)
    {
        __canType = _state;
    }
    
    static SetReturnBehavior = function(_behavior)
    {
        __returnBehavior = _behavior;
    }
    
    static GetReturnBehavior = function()
    {
        return __returnBehavior;
    }
    
    static GetReturnPressed = function()
    {
        return __returnPressed;
    }
    
    static Unfocus = function()
    {
        __focus = false;
        
        __highlightStart = 9999;
        __highlightEnd   = -9999;
    }
    
    static InsertString = function(_string, _position = __cursorPos+1, _update = true)
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
            __cursorPos += string_length(_string);
            if (_update) __Update();
        }
    }
    
    static Step = function(_x, _y, _mouseX, _mouseY, _mouseState)
    {
        var _keyboardKey = keyboard_key;

        if (os_is_paused())
        {
            _mouseState = false;
            __backspace = false;
        }
        
        //Manually handle backspace to try to work around stuck backspace when refocusing the window
        if (keyboard_check_pressed(vk_backspace)) __backspace = true;
        if (!keyboard_check(vk_backspace)) __backspace = false;
        if (__backspace) _keyboardKey = vk_backspace;

        //These two flags control additional function calls at the end of this function
        var _update         = false;
        var _oldCursorPos = __cursorPos;

        __mousePressed  = false;
        __mouseReleased = false;
        __returnPressed = false;

        __mouseOver = point_in_rectangle(_mouseX, _mouseY, _x, _y, _x + __width, _y + __height);

        if (_mouseState)
        {
            if (!__mouseDown)
            {
                if (__mouseOver)
                {
                    __mousePressed = true;
                    __mouseDown = true;
                    __focus = true;
                }
                else
                {
                    Unfocus();
                }
            }
        }
        else
        {
            if (__mouseDown)
            {
                __mouseReleased = true;
                __mouseDown = false;
            }
        }

        if (__mouseDown)
        {
            __highlightStart =  9999;
            __highlightEnd   = -9999;
        }

        if (__mouseOver && (__cursorPos >= 0))
        {
            __scrollY += __lineHeight*(mouse_wheel_down() - mouse_wheel_up());
            __scrollY = clamp(__scrollY, 0, max(0, __contentHeight - __height));
        }

        var _characterAt = __GetCharacterAt(_mouseX + __scrollX - _x, _mouseY + __scrollY - _y);
        if (_characterAt != undefined)
        {
            if (__mousePressed)
            {
                __cursorPos = _characterAt;
            }
            else if (__mouseDown)
            {
                if (_characterAt != __cursorPos)
                {
                    __highlightStart = min(__highlightStart, _characterAt, __cursorPos);
                    __highlightEnd   = max(__highlightEnd,   _characterAt, __cursorPos);
                }
            }
        }

        var _repeat_fire = false;
        if ((_keyboardKey != __keyHeld) || (__cursorPos < 0) || (not __focus) || os_is_paused())
        {
            __keyHeld         = undefined;
            __keyRepeat       = false;
            __keyPressedTime = -1;
        }
        else if (__keyPressedTime >= 0)
        {
            if (__keyRepeat)
            {
                if (current_time - __keyPressedTime > TEXTBOX_REPEAT_FREQUENCY) _repeat_fire = true;
            }
            else if (current_time - __keyPressedTime > TEXTBOX_REPEAT_DELAY)
            {
                __keyRepeat = true;
                _repeat_fire = true;
            }
        }

        if ((__cursorPos >= 0) && __focus && (keyboard_check_pressed(vk_anykey) || _repeat_fire))
        {
            var _validInput         = true;
            var _overwriteHighlight = false;
            var _commandShortcut    = false;
            
            switch(_keyboardKey)
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
                    _validInput = false;
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
                    __highlightStart =  9999;
                    __highlightEnd   = -9999;
                break;
        
                default:
                    _overwriteHighlight = true;
                break;
            }
    
            //Don't copy/paste/select repeatedly!
            if (keyboard_check(vk_control) && (__keyHeld != _keyboardKey))
            {
                _validInput = false;
        
                if (!keyboard_check(vk_shift))
                {
                    if (keyboard_check_pressed(ord("V")))
                    {
                        //We handle pasting after we remove the highlighted section
                        _overwriteHighlight = true;
                    }
                    else if (keyboard_check_pressed(ord("X")))
                    {
                        if (__highlightEnd - __highlightStart > 0)
                        {
                            var _start = __highlightStart + 1;
                            var _end = min(string_length(__content) + 1, __highlightEnd + 1);
                            var _string = string_copy(__content, __highlightStart + 1, _end - (__highlightStart + 1));
                            clipboard_set_text(_string);
                        }
                        
                        _overwriteHighlight = true;
                    }
                    else if (keyboard_check_pressed(ord("C")))
                    {
                        if (__highlightEnd - __highlightStart > 0)
                        {
                            var _start = __highlightStart + 1;
                            var _end = min(string_length(__content) + 1, __highlightEnd + 1);
                            var _string = string_copy(__content, __highlightStart + 1, _end - (__highlightStart + 1));
                            clipboard_set_text(_string);
                        }
                
                        _commandShortcut = true;
                    }
                    else if (keyboard_check_pressed(ord("A")))
                    {
                        __highlightStart = 0;
                        __highlightEnd   = array_length(__characterArray) - 1;
                
                        _commandShortcut = true;
                    }
                }
            }
            
            if (!_commandShortcut)
            {
                var _highlightSize = __highlightEnd - __highlightStart;
                if (__canType && _overwriteHighlight)
                {
                    if ((__highlightStart >= 0) && (__highlightEnd < array_length(__characterArray)) && (_highlightSize > 0))
                    {
                        __content = string_delete(__content, __highlightStart + 1, _highlightSize);
                        _update = true;
                
                        __cursorPos      = __highlightStart;
                        __highlightStart =  9999;
                        __highlightEnd   = -9999;
                
                        if ((_keyboardKey == vk_backspace) || (_keyboardKey == vk_delete)) _validInput = false;
                    }
                }
        
                if (__canType && keyboard_check(vk_control) && (__keyHeld != _keyboardKey))
                {
                    if (keyboard_check_pressed(ord("V"))) //ctrl+v pastes text
                    {
                        InsertString(clipboard_get_text(), undefined, false);
                        _update = true;
                        _validInput = false;
                    }
                    else if (keyboard_check_pressed(ord("X"))) //ctrl+x cuts text
                    {
                        InsertString("", undefined, false);
                        _update = true;
                        _validInput = false;
                    }
                }
        
                if (_validInput)
                {
                    switch(_keyboardKey)
                    {
                        case vk_enter:
                            if (__canType)
                            {
                                switch(__returnBehavior)
                                {
                                    case 0:
                                        __content = string_insert(chr(13), __content, __cursorPos + 1);
                                        ++__cursorPos;
                                        _update = true;
                                    break;
                                    
                                    case 1:
                                        if (keyboard_check(vk_shift))
                                        {
                                            __content = string_insert(chr(13), __content, __cursorPos + 1);
                                            ++__cursorPos;
                                            _update = true;
                                        }
                                        else
                                        {
                                            __returnPressed = true;
                                        }
                                    break;
                                    
                                    case 2:
                                        __returnPressed = true;
                                    break;
                                }
                            }
                        break;
                
                        case vk_up:
                            if ((__cursorPos >= 0) && __focus)
                            {
                                var _charStruct = __characterArray[__cursorPos];
                                var _offset = _charStruct.__width div 2;
                                if (_offset > 100) _offset = 1;
                                var _newChar = __GetCharacterAt(_charStruct.__x + _offset, _charStruct.__y - (__lineHeight div 2));
                                if (_newChar != undefined) __cursorPos = _newChar;
                            }
                        break;
                
                        case vk_down:
                            if ((__cursorPos >= 0) && __focus)
                            {
                                var _charStruct = __characterArray[__cursorPos];
                                var _offset = _charStruct.__width div 2;
                                if (_offset > 100) _offset = 1;
                                var _newChar = __GetCharacterAt(_charStruct.__x + _offset, _charStruct.__y + 3*(__lineHeight div 2));
                                if (_newChar != undefined) __cursorPos = _newChar;
                            }
                        break;
                
                        case vk_home:
                            if ((__cursorPos >= 0) && __focus)
                            {
                                var _charStruct = __characterArray[__cursorPos];
                                var _newChar = __GetCharacterAt(0, _charStruct.__y + (__lineHeight div 2));
                                if (_newChar != undefined) __cursorPos = _newChar;
                            }
                        break;
                
                        case vk_end:
                            if ((__cursorPos >= 0) && __focus)
                            {
                                var _charStruct = __characterArray[__cursorPos];
                                var _newChar = __GetCharacterAt(__contentWidth + 999, _charStruct.__y + (__lineHeight div 2));
                                if (_newChar != undefined) __cursorPos = _newChar;
                            }
                        break;
                
                        case vk_pagedown:
                            if ((__cursorPos >= 0) && __focus)
                            {
                                var _charStruct = __characterArray[__cursorPos];
                                var _offset = _charStruct.__width div 2;
                                if (_offset > 100) _offset = 1;
                                var _newChar = __GetCharacterAt(_charStruct.__x + _offset, _charStruct.__y + (__lineHeight div 2) + __height);
                                if (_newChar != undefined) __cursorPos = _newChar;
                            }
                        break;
                
                        case vk_pageup:
                            if ((__cursorPos >= 0) && __focus)
                            {
                                var _charStruct = __characterArray[__cursorPos];
                                var _offset = _charStruct.__width div 2;
                                if (_offset > 100) _offset = 1;
                                var _newChar = __GetCharacterAt(_charStruct.__x + _offset, _charStruct.__y + (__lineHeight div 2) - __height);
                                if (_newChar != undefined) __cursorPos = _newChar;
                            }
                        break;
                
                        case vk_left:
                            __cursorPos = max(0, __cursorPos - 1);
                        break;
                
                        case vk_right:
                            __cursorPos = min(array_length(__characterArray) - 1, __cursorPos + 1);
                        break;
                
                        case vk_backspace:
                            if (__canType)
                            {
                                __content = string_delete(__content, __cursorPos, 1);
                                __cursorPos = max(0, __cursorPos - 1);
                                _update = true;
                            }
                        break;
                
                        case vk_delete:
                            if (__canType)
                            {
                                __content = string_delete(__content, __cursorPos + 1, 1);
                                _update = true;
                            }
                        break;
                
                        default:
                            if (__canType)
                            {
                                var _lastChar = keyboard_lastchar;
                                if (_lastChar == chr(8230)) _lastChar = "..."; //Ellipsis replacement
                                
                                __content = string_insert(keyboard_lastchar, __content, __cursorPos + 1);
                                ++__cursorPos;
                                _update = true;
                            }
                        break;
                    }
                }
            }
    
            __keyHeld = _keyboardKey;
            __keyPressedTime = current_time;
        }

        if (_update) __Update();
        if (_oldCursorPos != __cursorPos) __FocusOnCursor();
    }
    
    static Draw = function(_x, _y)
    {
        matrix_set(matrix_world, matrix_build(_x, _y, 0,   0,0,0,   1,1,1));
        
        draw_set_colour(__colourBorder);
        draw_rectangle(-__padding - __borderThickness,
                       -__padding - __borderThickness,
                        __padding + __borderThickness + __width,
                        __padding + __borderThickness + __height,
                        false);
        
        draw_set_colour(__colourBackground);
        draw_rectangle(-__padding,
                       -__padding,
                        __padding + __width,
                        __padding + __height,
                        false);
        
        if (__contentWidth > __width)
        {
            var _t = clamp(__scrollX / (__contentWidth - __width), 0.0, 1.0);
            var _scrolledX = lerp(5, __width - 5, _t);
            
            draw_set_colour(__colourBorder);
            draw_rectangle(__borderThickness + _scrolledX - 2,
                           __padding - 4 + __height,
                           __borderThickness + _scrolledX + 2,
                           __padding + 4 + __borderThickness + __height,
                           false);
        }
        
        if (__contentHeight > __height)
        {
            var _t = clamp(__scrollY / (__contentHeight - __height), 0.0, 1.0);
            var _scrolledY = lerp(5, __height - 5, _t);
            
            draw_set_colour(__colourBorder);
            draw_rectangle(__padding - 4 + __width,
                           __borderThickness + _scrolledY - 2,
                           __padding + 4 + __borderThickness + __width,
                           __borderThickness + _scrolledY + 2,
                           false);
        }
        
        matrix_set(matrix_world, matrix_multiply(matrix_get(matrix_world),
                                                 matrix_build(-__scrollX, -__scrollY, 0,    0,0,0,   1,1,1)));
        
        draw_set_colour(__colourText);
        draw_set_font(__font);
        __SetWindow(_x-1, _y, _x + __width, _y + __height);
        
        //Create a vertex buffer for all the rectangles
        var _vbuff = vertex_create_buffer();
        vertex_begin(_vbuff, _vertexFormat);
        
        //Add in a degenerate triangle to stop GameMaker complaining about empty vertex buffers
        repeat(3)
        {
            vertex_position_3d(_vbuff, 0, 0, 0);
            vertex_colour(_vbuff, c_black, 0.0);
            vertex_texcoord(_vbuff, 0.5, 0.5);
        }
        
        var _i = 0;
        repeat(array_length(__characterArray))
        {
            var _charStruct = __characterArray[_i];
            
            if (is_struct(_charStruct))
            {
                var _char      = _charStruct.__char;
                var _charX     = _charStruct.__x;
                var _charY     = _charStruct.__y;
                var _charLine  = _charStruct.__line;
                var _charWidth = _charStruct.__width;
                
                draw_text(_charX, _charY, _char);
                
                if ((_i >= __highlightStart) && (_i < __highlightEnd))
                {
                    __VertexBufferAddRect(_vbuff, _charX, _charY, _charX + _charWidth, _charY + __lineHeight, __colourText, 0.3);
                }
                else
                {
                    if ((__cursorPos == _i) && __focus) __VertexBufferAddRect(_vbuff, _charX - 1, _charY, _charX, _charY + __lineHeight, __colourText, 1.0);
                    
                    if (_charLine < array_length(__lineColourArray))
                    {
                        var _lineColour = __lineColourArray[_charLine];
                        if (_lineColour != c_black)
                        {
                            __VertexBufferAddRect(_vbuff, _charX, _charY, _charX + _charWidth, _charY + __lineHeight, _lineColour, 0.3);
                            draw_set_colour(__colourText);
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
        
        //draw_rectangle(0, 0, __contentWidth, __contentHeight, true);
        matrix_set(matrix_world, matrix_build_identity());
        draw_set_font(-1);
        draw_set_color(c_white);
        shader_reset();
    }
    
    #endregion
    
    
    
    #region Private
    
    static __AddInternalCharacter = function(_character, _x, _y, _line, _width)
    {
        var _struct = {
            __char:  _character,
            __x:     _x,
            __y:     _y,
            __line:  _line,
            __width: _width,
        };
        
        array_push(__characterArray, _struct);
        
        return _struct;
    }
    
    static __FocusOnCursor = function()
    {
        var _cursorL = 0;
        var _cursorT = 0;
        var _cursorR = 0;
        var _cursorB = __lineHeight;
        
        __focus = true;
        
        if ((__cursorPos >= 0) && (__cursorPos < array_length(__characterArray)))
        {
            var _charStruct = __characterArray[__cursorPos];
            var _width = _charStruct.__width;
            if (_width > 100) _width = 0;
            
            var _cursorL = _charStruct.__x;
            var _cursorT = _charStruct.__y;
            var _cursorR = _width + _cursorL;
            var _cursorB = _cursorT + __lineHeight;
        }
        
        var _windowL = __scrollX;
        var _windowT = __scrollY;
        var _windowR = _windowL+ __width;
        var _windowB = _windowT + __height;
        
        if (!rectangle_in_rectangle(_cursorL, _cursorT, _cursorR, _cursorB,
                                    _windowL + 3, _windowT + 3, _windowR - 3, _windowB - 3))
        {
            __scrollX -= max(0, _windowL - _cursorL);
            __scrollY -= max(0, _windowT - _cursorT);
            __scrollX += max(0, _cursorR - _windowR);
            __scrollY += max(0, _cursorB - _windowB);
    
            __scrollX = clamp(__scrollX, 0, max(0, __contentWidth  - __width ));
            __scrollY = clamp(__scrollY, 0, max(0, __contentHeight - __height));
        }
        
        if (script_exists(__focusOnCursorCallback)) script_execute(__focusOnCursorCallback);
    }
    
    static __GetCharacterAt = function(_pointX, _pointY)
    {
        if (_pointY < 0) return 0;
        if (_pointY > __contentHeight) return (array_length(__characterArray) - 1);
        
        var _i = 0;
        repeat(array_length(__characterArray))
        {
            var _charStruct = __characterArray[_i];
            
            if (is_struct(_charStruct))
            {
                var _x     = _charStruct.__x;
                var _y     = _charStruct.__y;
                var _width = _charStruct.__width;
                
                if (point_in_rectangle(_pointX, _pointY, _x, _y, _x + _width, _y + __lineHeight))
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

        __contentWidth  = 0;
        __contentHeight = 0;

        var _length = string_length(__content);
        __characterArray = array_create(0);

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
                _y += __lineHeight;
                ++_line;
            }
            else if (_ord >= 32)
            {
                var _width = string_width(_char);
                __AddInternalCharacter(_char, _x, _y, _line, _width);
                
                _x += _width;
                __contentWidth = max(__contentWidth, _x);
            }
            
            ++_c;
        }
        
        __AddInternalCharacter("", _x, _y, _line, 9999);
        
        __contentHeight = _y + __lineHeight;
        __cursorPos = clamp(__cursorPos, -1, array_length(__characterArray) - 1);
        
        draw_set_font(-1);
        
        if (script_exists(__updateCallback)) script_execute(__updateCallback);
    }
    
    static __SetWindow = function(_l, _t, _r, _b, _fogColour = undefined)
    {
        var _textboxShader_u_vWindow    = shader_get_uniform(__textboxShader, "u_vWindow");
        var _textboxShader_u_vFogColour = shader_get_uniform(__textboxShader, "u_vFogColour");
        
        shader_set(__textboxShader);
        shader_set_uniform_f(_textboxShader_u_vWindow, _l, _t, _r, _b);
        
        if (_fogColour == undefined)
        {
            shader_set_uniform_f(_textboxShader_u_vFogColour, 0.0, 0.0, 0.0, 0.0);
        }
        else
        {
            var _red   = colour_get_red(  _fogColour)/255;
            var _green = colour_get_green(_fogColour)/255;
            var _blue  = colour_get_blue( _fogColour)/255;
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