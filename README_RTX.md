# Vulkan RTX Project

## How To Run

Use Windows with an RTX-capable NVIDIA GPU and a current NVIDIA driver.

Check Vulkan ray tracing extension support:

```powershell
vulkaninfo | Select-String "VK_KHR_ray_tracing_pipeline|VK_KHR_acceleration_structure|VK_KHR_buffer_device_address|VK_KHR_deferred_host_operations"
```

Build the ray tracing shaders from the project root:

```powershell
cd \Vulkan
.\glslangValidator.exe --target-env vulkan1.2 -V raygen.rgen -o raygen.spv
.\glslangValidator.exe --target-env vulkan1.2 -V miss.rmiss -o miss.spv
.\glslangValidator.exe --target-env vulkan1.2 -V closesthit.rchit -o closesthit.spv
```

Build and run the project with the x64 configuration:

```powershell
cd \Vulkan
msbuild Sample.sln /p:Configuration=Debug /p:Platform=x64
.\x64\Debug\Sample.exe
```

Run from the project root because the program loads shader and texture files by relative path. Do not use `Win32` or `x86`; the bundled Vulkan and GLFW binaries are x64.

Controls:

- Mouse: look around
- `W`, `A`, `S`, `D`: move camera
- `1`, `2`, `3`, `4`: select which point light to control
- Arrow keys: move selected point light on X/Z
- `,` / `.`: move selected point light down/up
- `P`: turn point lights on/off
- `R`: toggle molecule auto-rotation
- `Q` or `Esc`: quit

## Project Pipeline

1. GLFW creates the window and Vulkan surface.
2. Vulkan creates the instance, selects a physical device, and creates the logical device.
3. The device requests Vulkan ray tracing extensions:
   - `VK_KHR_acceleration_structure`
   - `VK_KHR_ray_tracing_pipeline`
   - `VK_KHR_deferred_host_operations`
   - `VK_KHR_buffer_device_address`
4. The project creates uniform buffers for scene, object, molecule atoms, and the ray tracing camera/light state.
5. `vkuSphere.cpp` generates a triangle sphere mesh.
6. The RTX path builds a BLAS from the sphere triangle buffer.
7. The RTX path builds a TLAS with one raised instance per atom plus one extra reflective sphere.
8. The ray tracing descriptor set binds:
   - output storage image
   - TLAS
   - atom buffer
   - camera/light buffer
9. The ray tracing pipeline loads:
   - `raygen.spv`
   - `miss.spv`
   - `closesthit.spv`
10. The shader binding table is created from the raygen, miss, and hit shader groups.
11. Each frame updates camera/light state, orbits the four glowing point lights around the molecule/reflection sphere area, optionally rebuilds the TLAS for `R` auto-rotation, reflects scene content on the bright floor tiles, calls `vkCmdTraceRaysKHR`, and copies the RTX output image into the swapchain image for presentation.

## Handout-To-Code Map

| Handout topic | Corresponding code |
| --- | --- |
| Multi-pass / render-to-image idea | `RenderRayTracedScene()` writes to `RayOutputImage`, then copies it into `PresentImages[nextImageIndex]`. |
| Vulkan ray tracing setup | `Init04LogicalDeviceAndQueue()` requests ray tracing extensions and features. `Init15LoadRayTracingFunctions()` loads KHR function pointers. |
| Ray/triangle intersection | The project uses triangle geometry from `vkuSphere.cpp`; Vulkan performs hardware triangle intersection in the BLAS. |
| Ray tracing pipeline | `Init15RayTracingPipeline()` creates raygen, miss, and closest-hit shader groups. |
| Acceleration structures | `Init15AccelerationStructures()` builds `BottomLevelAS` from the sphere mesh and `TopLevelAS` from molecule/reflection-sphere instances. |
| Shader binding table | `Init15ShaderBindingTable()` calls `vkGetRayTracingShaderGroupHandlesKHR()` and fills `RayShaderBindingTable`. |
| Firing rays | `RenderRayTracedScene()` binds the RTX pipeline and calls `vkCmdTraceRaysKHR()`. |
| Ray generation shader | `raygen.rgen` creates camera rays, draws the blue sky and floor, and traces into the TLAS. |
| Miss shader | `miss.rmiss` returns the sky color when no geometry is hit. |
| Closest-hit shader | `closesthit.rchit` shades atoms, uses the moving point light, and handles the reflective sphere. |

## References

- Multi-pass rendering: https://web.engr.oregonstate.edu/~mjb/vulkan/Handouts/MultiPass.1pp.pdf
- Vulkan ray tracing overview: https://web.engr.oregonstate.edu/~mjb/vulkan/Handouts/VulkanRayTracing.1pp.pdf
- Ray/triangle intersection: https://web.engr.oregonstate.edu/~mjb/vulkan/Handouts/RayTriangleIntersection.1pp.pdf
- Ray tracing pipeline: https://web.engr.oregonstate.edu/~mjb/vulkan/Handouts/RayTracePipeline.1pp.pdf
- Acceleration structures: https://web.engr.oregonstate.edu/~mjb/vulkan/Handouts/AccelerationStructures.1pp.pdf
- Firing rays: https://web.engr.oregonstate.edu/~mjb/vulkan/Handouts/FiringRays.1pp.pdf
