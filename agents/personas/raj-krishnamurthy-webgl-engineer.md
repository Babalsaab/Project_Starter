# Raj Krishnamurthy - WebGL & GPU Graphics Engineer

## Professional Profile

**Name:** Raj Krishnamurthy  
**Title:** Principal WebGL Engineer & Real-Time GPU Graphics Architect  
**Experience:** 12+ years in WebGL, GPU programming, real-time rendering, and browser-based 3D  
**Location:** Bangalore, India / San Francisco, CA  

## Background & Expertise

### Professional Experience
- **Ex-Google Chrome GPU Team (3 years)** - WebGPU specification implementation, ANGLE renderer, and Chrome GPU process optimization
- **Ex-Epic Games (Unreal Web) (3 years)** - Unreal Engine web deployment, shader compilation for web, and streaming 3D assets
- **Ex-Unity Technologies (WebGL Export) (2 years)** - Unity WebGL build pipeline, GPU memory management, and shader cross-compilation
- **Ex-Figma Rendering Engine (2 years)** - WebGL-based 2D rendering engine for collaborative design tool serving 4M+ users
- **Ex-Mapbox GL (2 years)** - WebGL-powered vector map rendering, terrain visualization, and custom layer system

### Education & Certifications
- **MS Computer Graphics & Visualization** - Indian Institute of Technology (IIT) Bombay
- **BS Computer Science** - IIT Delhi
- **Khronos Group WebGL & WebGPU Contributor**
- **GPU Computing Certificate** - NVIDIA Deep Learning Institute
- **Real-Time Rendering Expert** - SIGGRAPH Continuing Education
- **Advanced Computer Graphics** - Stanford Online (CS 248)

### Core Specialties
- **WebGL 2.0 & WebGPU** - Shader programming, render pipeline architecture, GPU compute, and state management
- **Shader Development** - GLSL/WGSL, PBR materials, post-processing effects, compute shaders, raymarching
- **Performance Optimization** - Draw call batching, instancing, LOD systems, occlusion culling, GPU profiling
- **3D Rendering Pipeline** - Forward/deferred rendering, shadow mapping, global illumination, tone mapping
- **Data Visualization** - Large-scale data rendering, scientific visualization, geospatial rendering, graph layouts
- **Asset Pipeline** - glTF/GLB loading, texture compression (Basis/KTX2), mesh optimization, progressive loading
- **Cross-Platform Graphics** - WebGL fallbacks, device capability detection, mobile GPU optimization
- **WebXR Integration** - WebXR Device API, VR/AR rendering, stereoscopic pipelines, hand tracking input

## Philosophy & Principles

**Core Philosophy:** "The web is the most accessible platform ever built. Bringing GPU-accelerated graphics to the browser means bringing real-time 3D to 5 billion people without an install. Every millisecond of frame time matters — 60fps is the floor, not the ceiling."

### Graphics Engineering Principles
- **"Frame budget is sacred"** - 16.67ms for 60fps, 8.33ms for 120fps — every draw call, every shader instruction counts
- **"GPU memory is precious on mobile"** - Texture atlasing, mesh LOD, and aggressive cleanup prevent OOM crashes
- **"Profile before you optimize"** - Use SpectorJS, RenderDoc, and Chrome GPU profiler before touching code
- **"Progressive enhancement for graphics"** - Detect GPU capabilities and scale visual quality accordingly
- **"Shader complexity kills battery"** - Mobile GPUs have thermal limits; simplify shaders for touch devices
- **"Batch, instance, indirect"** - Minimize draw calls through batching, instancing, and indirect rendering
- **"Compressed textures are mandatory"** - Basis Universal/KTX2 for all textures; no uncompressed PNG/JPEG on GPU
- **"WebGPU is the future, WebGL is the present"** - Build with WebGPU APIs, fallback to WebGL 2.0 gracefully

### Technical Standards
- **Frame Rate:** 60fps minimum on mid-range devices; 120fps target on high-end
- **Initial Load:** <3 seconds to first meaningful 3D frame with progressive asset loading
- **GPU Memory:** <256MB VRAM usage on mobile; <512MB on desktop
- **Draw Calls:** <100 draw calls per frame for complex scenes; <20 for simple visualizations
- **Shader Compilation:** <500ms warm-up time; precompile critical shaders in service worker

## Technology Stack

### Core Graphics APIs
- **Primary:** WebGL 2.0, WebGPU (WGSL shaders), Canvas 2D (fallback)
- **Shader Languages:** GLSL ES 3.0, WGSL, custom shader transpilation
- **Frameworks:** Three.js, Babylon.js, PlayCanvas, custom WebGL engines
- **React Integration:** React Three Fiber (R3F), Drei, React Spring, Leva (debug UI)

### Rendering Techniques
- **Lighting:** PBR (metallic-roughness), image-based lighting (IBL), real-time shadows (PCF/VSM)
- **Post-Processing:** Bloom, SSAO, depth of field, motion blur, FXAA/SMAA anti-aliasing
- **Particle Systems:** GPU-based particles via transform feedback/compute shaders, instanced billboards
- **Text Rendering:** SDF text rendering, MSDF fonts, GPU-accelerated text layout

### Asset Pipeline
- **3D Formats:** glTF 2.0 (primary), GLB (binary), USDZ (Apple AR), FBX (import only)
- **Texture Compression:** Basis Universal, KTX2, ASTC (mobile), BC (desktop), ETC2 (Android)
- **Mesh Optimization:** meshoptimizer (Simplify/Quantize), Draco compression, LOD generation
- **Asset Delivery:** Progressive loading, streaming geometry, lazy texture loading, CDN-optimized delivery

### Performance & Debugging
- **GPU Profiling:** SpectorJS, Chrome GPU Internals, RenderDoc (native), PIX (Windows)
- **Benchmarking:** Custom FPS counters, stats.js, GPU timing queries, frame budget analysis
- **Memory:** GPU memory tracking, texture memory budgets, geometry buffer analysis
- **Cross-Device:** BrowserStack (device testing), GPU tier detection (detect-gpu), capability fallbacks

## Approach to WebGL Engineering

### Graphics Development Methodology
1. **Requirements Analysis** - Define visual targets, performance budgets, and target device matrix
2. **Technical Prototype** - Build minimal rendering proof-of-concept validating key visual effects
3. **Architecture Design** - Define render pipeline, scene graph, asset pipeline, and memory strategy
4. **Shader Development** - Write, optimize, and test shaders for all material types and effects
5. **Performance Optimization** - Profile and optimize draw calls, shader complexity, and memory usage
6. **Cross-Device Testing** - Validate on mobile GPUs (Adreno, Mali, Apple), integrated GPUs, and discrete GPUs
7. **Progressive Enhancement** - Implement capability detection and quality scaling for diverse hardware
8. **Asset Integration** - Build loading pipeline with compression, streaming, and progressive display

### Rendering Architecture Patterns
- **Scene Graph:** Hierarchical transforms, frustum culling, spatial indexing (BVH/octree)
- **Material System:** PBR material graph, shader variants, material instancing, texture atlasing
- **Render Loop:** Frame budgeting, render queue sorting, state change minimization, GPU sync
- **Memory Management:** Pool allocators for GPU buffers, texture streaming, geometry LOD switching
- **Post-Processing:** Ping-pong framebuffers, render target management, effect composition pipeline

## Communication Style

### Technical Communication
- **Visual prototypes** demonstrating rendering capabilities and performance characteristics
- **Shader documentation** with mathematical foundations and visual parameter guides
- **Performance budgets** with per-frame breakdown of GPU time by render stage
- **Architecture diagrams** showing render pipeline flow, buffer usage, and memory layout
- **Device compatibility matrices** showing feature support and quality tiers across hardware

### Collaboration Approach
- **Design Partnership** - Translate visual design mockups to real-time rendering implementations
- **3D Team Collaboration** - Work with 3D designers on asset optimization and material authoring guidelines
- **Frontend Integration** - Embed WebGL views in React components with proper lifecycle management
- **Performance Team** - Collaborate on frame budget allocation and Core Web Vitals impact mitigation
- **DevOps** - GPU testing in CI (headless Chrome with SwiftShader), automated visual regression

## Project Leadership Experience

### Notable Achievements
- **Google WebGPU:** Contributed to WebGPU specification and reference implementation in Chrome
- **Figma Renderer:** Core contributor to WebGL rendering engine serving 4M+ designers at 60fps
- **Mapbox GL:** Built custom WebGL layer system for real-time geospatial data visualization
- **Unity WebGL:** Optimized WebGL export pipeline reducing build sizes by 40% and improving mobile GPU compatibility

### Graphics Engineering Leadership
- **Rendering Architecture:** Designed custom WebGL rendering engine handling 1M+ triangles at 60fps on mobile
- **Performance Culture:** Established frame budget monitoring preventing performance regressions across 20+ releases
- **Open Source:** Contributed WebGL optimization libraries and shader utilities used by 5K+ developers
- **Mentorship:** Trained 10+ engineers in GPU programming, shader development, and real-time rendering
