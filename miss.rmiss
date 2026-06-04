#version 460
#extension GL_EXT_ray_tracing : require

layout( location = 0 ) rayPayloadInEXT vec4 Payload;

void
main( )
{
	vec2 uv = vec2( gl_LaunchIDEXT.xy ) / vec2( gl_LaunchSizeEXT.xy );
	Payload = vec4( mix( vec3( 0.58, 0.74, 0.95 ), vec3( 0.08, 0.28, 0.72 ), uv.y ), 10000.0 );
}
