/// @param vertexBuffer
/// @param x1
/// @param y1
/// @param x2
/// @param y2
/// @param colour
/// @param alpha

function ctool_vertex_buffer_add_rect()
{
    var _vbuff  = argument0;
    var _x1     = argument1;
    var _y1     = argument2;
    var _x2     = argument3;
    var _y2     = argument4;
    var _colour = argument5;
    var _alpha  = argument6;

    var _z = 0;

    vertex_position_3d(_vbuff, _x1, _y1, _z); vertex_colour(_vbuff, _colour, _alpha); vertex_texcoord(_vbuff, 0.5, 0.5);
    vertex_position_3d(_vbuff, _x2, _y1, _z); vertex_colour(_vbuff, _colour, _alpha); vertex_texcoord(_vbuff, 0.5, 0.5);
    vertex_position_3d(_vbuff, _x1, _y2, _z); vertex_colour(_vbuff, _colour, _alpha); vertex_texcoord(_vbuff, 0.5, 0.5);
    vertex_position_3d(_vbuff, _x2, _y1, _z); vertex_colour(_vbuff, _colour, _alpha); vertex_texcoord(_vbuff, 0.5, 0.5);
    vertex_position_3d(_vbuff, _x2, _y2, _z); vertex_colour(_vbuff, _colour, _alpha); vertex_texcoord(_vbuff, 0.5, 0.5);
    vertex_position_3d(_vbuff, _x1, _y2, _z); vertex_colour(_vbuff, _colour, _alpha); vertex_texcoord(_vbuff, 0.5, 0.5);
}