shader_type canvas_item;
uniform float strength = 0.22;
void fragment(){
 vec2 uv=UV; float vignette=smoothstep(0.22,0.78,length((uv-0.5)*vec2(1.1,1.0)));
 float grain=fract(sin(dot(uv+fract(TIME)*0.001,vec2(12.9898,78.233)))*43758.5453);
 COLOR=vec4(vec3(0.005,0.01,0.015),clamp(vignette*strength+grain*0.025,0.0,0.6));
}
