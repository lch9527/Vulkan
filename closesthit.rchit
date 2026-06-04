#version 460
#extension GL_EXT_ray_tracing : require

struct atom
{
	vec3 position;
	int atomicNumber;
};

layout( set = 0, binding = 2, std140 ) uniform moleculeBuf
{
	atom atoms[24];
};

layout( set = 0, binding = 3, std140 ) uniform raySceneBuf
{
	vec4 uCameraPos;
	vec4 uCameraForward;
	vec4 uCameraRight;
	vec4 uCameraUp;
	vec4 uLightPos[4];
	vec4 uLightColor[4];
	vec4 uLightControl;
	vec4 uMolecule;
} Scene;

layout( location = 0 ) rayPayloadInEXT vec4 Payload;
hitAttributeEXT vec2 Attribs;

const int REFLECTION_SPHERE_INDEX = 24;
const vec3 REFLECTION_SPHERE_CENTER = vec3( 2.8, 0.1, 2.0 );

vec3
RotateY( vec3 p, float angle )
{
	float c = cos( angle );
	float s = sin( angle );
	return vec3( c*p.x + s*p.z, p.y, -s*p.x + c*p.z );
}

vec3
AtomCenter( int atomIndex )
{
	vec3 center = RotateY( atoms[atomIndex].position, Scene.uMolecule.y );
	center.y += Scene.uMolecule.x;
	return center;
}

vec3
AtomColor( int atomicNumber )
{
	if( atomicNumber == 1 )
		return vec3( 0.94, 0.94, 0.90 );
	if( atomicNumber == 6 )
		return vec3( 0.18, 0.18, 0.20 );
	if( atomicNumber == 7 )
		return vec3( 0.12, 0.28, 0.95 );
	if( atomicNumber == 8 )
		return vec3( 0.92, 0.08, 0.05 );
	return vec3( 1.0, 0.0, 1.0 );
}

vec3
SkyColor( vec3 direction )
{
	float t = clamp( direction.y * 0.5 + 0.5, 0.0, 1.0 );
	return mix( vec3( 0.58, 0.74, 0.95 ), vec3( 0.08, 0.28, 0.72 ), t );
}

vec3
FloorColor( vec3 point, vec3 rayOrigin )
{
	float checker = mod( floor( point.x ) + floor( point.z ), 2.0 );
	vec3 base = mix( vec3( 0.42, 0.43, 0.40 ), vec3( 0.74, 0.75, 0.70 ), checker );
	vec3 viewDir = normalize( rayOrigin - point );
	vec3 color = base * 0.18;
	if( Scene.uLightControl.y > 0.5 )
	{
		for( int i = 0; i < 4; i++ )
		{
			vec3 lightVec = Scene.uLightPos[i].xyz - point;
			float dist2 = max( dot( lightVec, lightVec ), 0.25 );
			vec3 lightDir = normalize( lightVec );
			vec3 halfVec = normalize( lightDir + viewDir );
			float diffuse = max( dot( vec3( 0.0, 1.0, 0.0 ), lightDir ), 0.0 );
			float specular = pow( max( dot( vec3( 0.0, 1.0, 0.0 ), halfVec ), 0.0 ), 48.0 );
			color += Scene.uLightColor[i].rgb * ( 16.0 / dist2 ) * ( base * diffuse + vec3( 0.18 ) * specular );
		}
	}
	return color;
}

bool
FloorInside( vec3 point )
{
	vec2 center = vec2( 1.0, 0.8 );
	vec2 halfSize = vec2( 5.3, 5.3 );
	vec2 d = abs( point.xz - center );
	return d.x <= halfSize.x && d.y <= halfSize.y;
}

vec3
LightShading( vec3 point, vec3 normal, vec3 viewDir, vec3 base, float shininess )
{
	vec3 color = base * 0.15;
	if( Scene.uLightControl.y <= 0.5 )
		return color;

	for( int i = 0; i < 4; i++ )
	{
		vec3 lightVec = Scene.uLightPos[i].xyz - point;
		float dist2 = max( dot( lightVec, lightVec ), 0.25 );
		vec3 lightDir = normalize( lightVec );
		vec3 halfVec = normalize( lightDir + viewDir );
		float diffuse = max( dot( normal, lightDir ), 0.0 );
		float specular = pow( max( dot( normal, halfVec ), 0.0 ), shininess );
		float attenuation = 20.0 / dist2;
		color += Scene.uLightColor[i].rgb * attenuation * ( base * diffuse + vec3( 0.45 ) * specular );
	}
	return color;
}

void
main( )
{
	int atomIndex = gl_InstanceCustomIndexEXT;
	vec3 hitPoint = gl_WorldRayOriginEXT + gl_HitTEXT * gl_WorldRayDirectionEXT;
	if( atomIndex == REFLECTION_SPHERE_INDEX )
	{
		vec3 normal = normalize( hitPoint - REFLECTION_SPHERE_CENTER );
		vec3 reflected = reflect( gl_WorldRayDirectionEXT, normal );
		vec3 reflectedColor = SkyColor( reflected );
		if( reflected.y < -0.001 )
		{
			float floorT = ( -0.80 - hitPoint.y ) / reflected.y;
			vec3 floorPoint = hitPoint + floorT * reflected;
			if( floorT > 0.001 && FloorInside( floorPoint ) )
				reflectedColor = FloorColor( floorPoint, hitPoint );
		}
		vec3 sparkle = vec3( 0.0 );
		if( Scene.uLightControl.y > 0.5 )
		{
			for( int i = 0; i < 4; i++ )
			{
				vec3 lightDir = normalize( Scene.uLightPos[i].xyz - hitPoint );
				float s = pow( max( dot( reflect( -lightDir, normal ), normalize( -gl_WorldRayDirectionEXT ) ), 0.0 ), 128.0 );
				sparkle += Scene.uLightColor[i].rgb * s;
			}
		}
		Payload = vec4( reflectedColor * 0.88 + 0.75 * sparkle, gl_HitTEXT );
		return;
	}

	vec3 normal = normalize( hitPoint - AtomCenter( atomIndex ) );
	vec3 viewDir = normalize( -gl_WorldRayDirectionEXT );
	vec3 base = AtomColor( atoms[atomIndex].atomicNumber );
	vec3 color = LightShading( hitPoint, normal, viewDir, base, 64.0 );
	Payload = vec4( color, gl_HitTEXT );
}
