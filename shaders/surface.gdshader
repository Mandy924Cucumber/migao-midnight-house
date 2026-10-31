shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.2,0.15,0.1,1.0);
uniform vec4 second_color : source_color = vec4(0.1,0.075,0.055,1.0);
uniform float pattern = 0.0;
uniform float surface_roughness = 0.75;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex(){ world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 vec2 p=world_pos.xz;
 float n=noise(p*35.0);
 vec3 col=base_color.rgb;
 if(pattern < 0.5){
  float row=floor(p.x*2.5); vec2 q=vec2(p.x*2.5,p.y*0.65+mod(row,2.0)*0.5);
  vec2 f=fract(q); float edge=step(0.017,f.x)*step(0.015,f.y);
  float grain=noise(vec2(p.x*26.0,p.y*1.2));
  col=mix(second_color.rgb,base_color.rgb,0.35+0.5*hash(floor(q)));
  col*=0.88+grain*0.14; col*=mix(0.3,1.0,edge);
 } else if(pattern<1.5){
  p=vec2(world_pos.x+world_pos.z,world_pos.y)*2.5;
  p.x+=mod(floor(p.y),2.0)*0.5; vec2 f=fract(p);
  float brick=step(0.035,f.x)*step(0.055,f.y);
  col=mix(second_color.rgb,base_color.rgb*(0.8+hash(floor(p))*0.3),brick);
  col*=0.86+noise(world_pos.xy*50.0)*0.24;
 } else {
  col=mix(second_color.rgb,base_color.rgb,noise(world_pos.xz*3.0+world_pos.xy*2.0)*0.6+0.3);
 }
 ALBEDO=col*(0.95+n*0.1); ROUGHNESS=surface_roughness;
}
