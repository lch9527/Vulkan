#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <ctype.h>

#ifndef VERTEX_H
#define VERTEX_H
struct vertex
{
        glm::vec3       position;
        glm::vec3       normal;
        glm::vec3       color;
        glm::vec2       texCoord;
};
#endif


#ifndef F_PI
#define F_PI		((float)(M_PI))
#define F_2_PI		((float)(2.f*F_PI))
#define F_PI_2		((float)(F_PI/2.f))
#endif

inline
void
DrawLatLng( struct vertex *vp, float radius, float lat, float lng )
{
	// lat is in radians between -F_PI_2 and +F_PI_2
	// lng is in radians between -F_PI and +F_PI
	float xz =  cosf(lat);
	float x = xz * sinf(lng);
	float y = sinf(lat);
	float z = xz * cosf(lng);
	float nx = x;		// for a *sphere only*, the normal is the unitized position
	float ny = y;		// for a *sphere only*, the normal is the unitized position
	float nz = z;		// for a *sphere only*, the normal is the unitized position
	float s = ( lng + F_PI )   / F_2_PI;
	float t = ( lat + F_PI_2 ) / F_PI;
	vp->position = glm::vec3( x*radius, y*radius, z*radius );
	vp->normal   = glm::vec3( nx, ny, nz );
	vp->texCoord = glm::vec2( s, t );
	vp->color    = glm::vec3( 1.f, 0.5f, 0.f );
}


MyBuffer
vkuSphere( float radius, int slices, int stacks )
{
	// sanity check:
	radius = (float)fabs(radius);
	if( slices < 8 )		slices = 8;
	if( stacks < 8 )		stacks = 8;


	// allocate the correct sized vulkan buffer for an array of struct vertex [numVertices]
	
	//                 south:       north:      in between:
	int numVertices = 3*slices  +  3*slices + 6*slices*(stacks-2);
	MyBuffer		myVertexDataBuffer;
	Init05MyVertexDataBuffer(  numVertices*sizeof(struct vertex), OUT &myVertexDataBuffer );

	struct vertex * pVertex;
	vkMapMemory( LogicalDevice, IN myVertexDataBuffer.vdm, 0, VK_WHOLE_SIZE, 0, OUT (void **)&pVertex );

	// south pole:
	{
		int istack = 0;
		float north = -F_PI_2 + F_PI * (float)(istack + 1) / (float)stacks;
		float south = -F_PI_2 + F_PI * (float)(istack + 0) / (float)stacks;
		for (int islice = 0; islice < slices; islice++)
		{
			float west = -F_PI + F_2_PI * (float)(islice + 0) / (float)slices;
			float east = -F_PI + F_2_PI * (float)(islice + 1) / (float)slices;

			DrawLatLng(pVertex, radius, south, .5f * (east + west));	pVertex++;
			DrawLatLng(pVertex, radius, north, east);					pVertex++;
			DrawLatLng(pVertex, radius, north, west);					pVertex++;
		}
	}

	// north pole:
	{
		int istack = stacks - 1;
		float north = -F_PI_2 + F_PI * (float)(istack + 1) / (float)stacks;
		float south = -F_PI_2 + F_PI * (float)(istack + 0) / (float)stacks;
		for (int islice = 0; islice < slices; islice++)
		{
			float west = -F_PI + F_2_PI * (float)(islice + 0) / (float)slices;
			float east = -F_PI + F_2_PI * (float)(islice + 1) / (float)slices;

			DrawLatLng(pVertex, radius, north, .5f*(east + west));		pVertex++;
			DrawLatLng(pVertex, radius, south, west);					pVertex++;
			DrawLatLng(pVertex, radius, south, east);					pVertex++;
		}
	}

	// all the bands in between:
	for (int istack = 1; istack < stacks-1; istack++)
	{
		float north = -F_PI_2 + F_PI * (float)(istack + 1) / (float)stacks;
		float south = -F_PI_2 + F_PI * (float)(istack + 0) / (float)stacks;
		for (int islice = 0; islice < slices; islice++)
		{
			float west = -F_PI + F_2_PI * (float)(islice + 0) / (float)slices;
			float east = -F_PI + F_2_PI * (float)(islice + 1) / (float)slices;

			DrawLatLng(pVertex, radius, north, west);					pVertex++;
			DrawLatLng(pVertex, radius, south, west);					pVertex++;
			DrawLatLng(pVertex, radius, north, east);					pVertex++;

			DrawLatLng(pVertex, radius, north, east);					pVertex++;
			DrawLatLng(pVertex, radius, south, west);					pVertex++;
			DrawLatLng(pVertex, radius, south, east);					pVertex++;
		}
	}

	vkUnmapMemory( LogicalDevice, IN myVertexDataBuffer.vdm );
	return myVertexDataBuffer;
}
