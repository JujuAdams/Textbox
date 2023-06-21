/// ctool_set_window(l, t, r, b, [fogColour])

function ctool_set_window()
{
    var _l          = argument[0];
    var _t          = argument[1];
    var _r          = argument[2];
    var _b          = argument[3];
    var _fog_colour = undefined;

    if (argument_count > 4) _fog_colour = argument[4];

    shader_set(shd_ctool_window);
    shader_set_uniform_f(shader_get_uniform(shd_ctool_window, "u_vWindow"),
                         _l, _t, _r, _b);

    if (_fog_colour == undefined)
    {
        shader_set_uniform_f(shader_get_uniform(shd_ctool_window, "u_vFogColour"),
                             0.0, 0.0, 0.0, 0.0);
    }
    else
    {
        var _red   = colour_get_red(  _fog_colour)/255;
        var _green = colour_get_green(_fog_colour)/255;
        var _blue  = colour_get_blue( _fog_colour)/255;
    
        shader_set_uniform_f(shader_get_uniform(shd_ctool_window, "u_vFogColour"),
                             _red, _green, _blue, 1.0);
    }
}