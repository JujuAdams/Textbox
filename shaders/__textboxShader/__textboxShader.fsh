varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_vPosition;

uniform vec4 u_vWindow;
uniform vec4 u_vFogColour;

void main()
{
    if ((v_vPosition.x < u_vWindow.x)
    ||  (v_vPosition.y < u_vWindow.y)
    ||  (v_vPosition.x > u_vWindow.z)
    ||  (v_vPosition.y > u_vWindow.w))
    {
        gl_FragColor = vec4(0.0);
    }
    else
    {
        gl_FragColor = v_vColour * texture2D(gm_BaseTexture, v_vTexcoord);
    }
    
    gl_FragColor.rgb = mix(gl_FragColor.rgb, u_vFogColour.rgb, u_vFogColour.a);
}