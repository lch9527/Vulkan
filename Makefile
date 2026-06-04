CXX		?= g++
CXXFLAGS	?= -std=gnu++11 -I.
LDLIBS		?= -lvulkan -lglfw
GLSLANG		?= glslangValidator

Sample:		sample.cpp
			$(CXX) $(CXXFLAGS) sample.cpp -o Sample $(LDLIBS)

sample.o:	sample.cpp
			$(CXX) $(CXXFLAGS) -c sample.cpp

numbers.cpp:		sample.cpp
			rm -f numbers.cpp
			cat -n sample.cpp > numbers.cpp

ALLSHADERS:		sample-vert.spv  sample-frag.spv raygen.spv miss.spv closesthit.spv

sample-vert.spv:	sample-vert.vert
			$(GLSLANG) -V sample-vert.vert  -o sample-vert.spv

sample-frag.spv:	sample-frag.frag
			$(GLSLANG) -V sample-frag.frag  -o sample-frag.spv

raygen.spv:		raygen.rgen
			$(GLSLANG) --target-env vulkan1.2 -V raygen.rgen -o raygen.spv

miss.spv:		miss.rmiss
			$(GLSLANG) --target-env vulkan1.2 -V miss.rmiss -o miss.spv

closesthit.spv:		closesthit.rchit
			$(GLSLANG) --target-env vulkan1.2 -V closesthit.rchit -o closesthit.spv

shaders:		sample-vert.spv  sample-frag.spv raygen.spv miss.spv closesthit.spv

sample-vert-dis.txt:	sample-vert.vert
			rm -f sample-vert-dis.txt
			$(GLSLANG) -H -V sample-vert.vert  > sample-vert-dis.txt

sample-frag-dis.txt:	sample-frag.frag
			rm -f sample-frag-dis.txt
			$(GLSLANG) -H -V sample-frag.frag  > sample-frag-dis.txt

dis:			sample-vert-dis.txt  sample-frag-dis.txt

save:
			cp sample.cpp sample.save.cpp
			cp sample-vert.vert sample-vert.save.vert
			cp sample-frag.frag sample-frag.save.frag

clean:
			rm -f Sample sample.o numbers.cpp sample-vert-dis.txt sample-frag-dis.txt raygen.spv miss.spv closesthit.spv
