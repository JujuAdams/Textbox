vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_colour();
vertex_format_add_texcoord();
global.ctool_vertex_format = vertex_format_end();

global.ctool_repeat_delay            = 450;
global.ctool_repeat_frequency        = 60;

draw_set_font(fntConsolas);

ctool_textbox_init(fntConsolas, 1100, 500, true);