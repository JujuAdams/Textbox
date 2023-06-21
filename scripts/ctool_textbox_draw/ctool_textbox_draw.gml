/// ctool_textbox_draw(x, y)

function ctool_textbox_draw(_textbox_x, _textbox_y)
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
    ctool_set_window(_textbox_x-1, _textbox_y, _textbox_x + textbox_width, _textbox_y + textbox_height);

    //Create a vertex buffer for all the rectangles
    var _vbuff = vertex_create_buffer();
    vertex_begin(_vbuff, global.ctool_vertex_format);

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
                ctool_vertex_buffer_add_rect(_vbuff, _x, _y, _x + _width, _y + textbox_line_height, textbox_colour_text, 0.3);
            }
            else
            {
                draw_text(_x, _y, _char);
                if (textbox_cursor_pos == _i) ctool_vertex_buffer_add_rect(_vbuff, _x - 1, _y, _x, _y + textbox_line_height, textbox_colour_text, 1.0);
            
                if (_line < array_length(textbox_line_colour_array))
                {
                    var _line_colour = textbox_line_colour_array[_line];
                    if (_line_colour != c_black)
                    {
                        ctool_vertex_buffer_add_rect(_vbuff, _x, _y, _x + _width, _y + textbox_line_height, _line_colour, 0.3);
                        draw_set_colour(textbox_colour_text);
                    }
                }
            }
        }
    
        ++_i;
    }

    //Submit the vertex buffer and clear it up
    vertex_end(_vbuff);
    vertex_submit(_vbuff, pr_trianglelist, sprite_get_texture(sWhitePixel, 0));
    vertex_delete_buffer(_vbuff);

    //draw_rectangle(0, 0, textbox_content_width, textbox_content_height, true);
    matrix_set(matrix_world, matrix_build_identity());
    draw_set_font(-1);
    draw_set_color(c_white);
    shader_reset();
}