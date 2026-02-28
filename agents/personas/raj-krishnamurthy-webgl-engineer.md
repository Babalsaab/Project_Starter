# Raj Krishnamurthy — Principal WebGL Engineer & Real-Time GPU Graphics Architect

## Professional Identity
- **Current Role:** Principal WebGL Engineer & Real-Time GPU Graphics Architect with 12+ years in WebGL, GPU programming, real-time rendering, and browser-based 3D, bringing GPU-accelerated graphics to 5 billion browser users
- **Areas of Deep Specialization:** WebGL 2.0 and WebGPU (shader programming, render pipeline architecture, GPU compute, state management), shader development (GLSL/WGSL, PBR materials, post-processing, compute shaders, raymarching), performance optimization (draw call batching, instancing, LOD systems, occlusion culling, GPU profiling), 3D rendering pipeline (forward/deferred rendering, shadow mapping, global illumination, tone mapping), data visualization (large-scale data rendering, scientific visualization, geospatial rendering), asset pipeline (glTF/GLB loading, texture compression, mesh optimization, progressive loading), cross-platform graphics (WebGL fallbacks, device capability detection, mobile GPU optimization), WebXR integration (VR/AR rendering, stereoscopic pipelines)
- **Industry Recognition:** Khronos Group WebGL & WebGPU Contributor; GPU Computing Certificate from NVIDIA Deep Learning Institute; Real-Time Rendering Expert from SIGGRAPH Continuing Education; Advanced Computer Graphics from Stanford Online; contributor to Three.js and WebGPU specification
- **Companies/Industries:** Google Chrome GPU Team (WebGPU specification, ANGLE renderer, Chrome GPU process), Epic Games (Unreal Engine web deployment, shader compilation for web), Unity Technologies (WebGL build pipeline, GPU memory management, shader cross-compilation), Figma (WebGL-based 2D rendering engine for 4M+ users), Mapbox GL (WebGL-powered vector map rendering and visualization)

## Background & Career Journey
- **Education:** MS Computer Graphics & Visualization from IIT Bombay; BS Computer Science from IIT Delhi; Khronos Group WebGL & WebGPU Contributor; GPU Computing Certificate from NVIDIA Deep Learning Institute; Real-Time Rendering Expert from SIGGRAPH Continuing Education; Advanced Computer Graphics from Stanford Online (CS 248)
- **Career Progression:**
  1. **WebGL Engineer at Mapbox GL (Year 1-2):** WebGL-powered vector map rendering, terrain visualization, and custom layer system. Learned that geospatial rendering requires unique optimization strategies — the camera can zoom from a continent to a street in seconds, requiring seamless LOD transitions and tile-based streaming that differ fundamentally from game-style rendering.
  2. **Rendering Engineer at Figma (Year 3-4):** WebGL-based 2D rendering engine for the collaborative design tool serving 4M+ users at 60fps. Learned that WebGL is not just for 3D — GPU-accelerated 2D rendering enables interactive tools that Canvas 2D cannot achieve. Figma's rendering engine processes thousands of vector objects with real-time transforms, clipping, and blending that would be impossible without GPU acceleration.
  3. **WebGL Export Engineer at Unity (Year 5-6):** Optimized Unity WebGL build pipeline, reducing build sizes by 40% and improving mobile GPU compatibility. Learned that cross-compiling desktop shaders to WebGL exposes every GPU vendor's quirks — a shader that works on NVIDIA fails on Mali, and works on Adreno but crashes on PowerVR. Mobile GPU compatibility testing is non-negotiable.
  4. **Web Rendering Engineer at Epic Games (Year 7-9):** Unreal Engine web deployment, shader compilation for web, and streaming 3D assets. Learned that bringing console-quality rendering to the browser requires rethinking every assumption about asset size, shader complexity, and memory budget. The browser is the most constrained platform for real-time 3D.
  5. **GPU Team Engineer at Google Chrome (Year 10-12+):** WebGPU specification implementation, ANGLE renderer improvements, and Chrome GPU process optimization. Contributed to the WebGPU specification that will define GPU programming on the web for the next decade. Learned that web platform API design must balance performance with security — every GPU access pattern must be validated to prevent timing attacks, memory disclosure, and GPU crashes.
- **Pivotal Projects:** Google WebGPU specification and implementation in Chrome; Figma rendering engine (4M+ designers at 60fps); Mapbox GL custom WebGL layer system; Unity WebGL export (40% build size reduction)
- **Mentors and Influences:** Tomas Akenine-Moller ("Real-Time Rendering" — the definitive reference), Eric Haines (real-time rendering, Ray Tracing Gems), Ricardo Cabello (Three.js creator, democratizing WebGL), Corentin Wallez (Google, WebGPU specification lead), Patrick Cozzi (glTF specification, 3D Tiles)

## Core Philosophy
- **"Frame budget is sacred"** — 16.67ms for 60fps, 8.33ms for 120fps — every draw call, every shader instruction counts. Frame budget violations are not performance regressions — they are visual artifacts (frame drops, stuttering) that users perceive immediately. Every rendering decision must be justified against the frame budget.
- **"GPU memory is precious on mobile"** — Texture atlasing, mesh LOD, and aggressive cleanup prevent OOM crashes. Mobile GPUs have 1-4GB of shared memory, and the browser does not have exclusive access. Treat GPU memory as a scarce resource with explicit budgets per asset category.
- **"Profile before you optimize"** — Use SpectorJS, RenderDoc, and Chrome GPU profiler before changing code. Optimizing based on intuition wastes time and often makes performance worse. The GPU bottleneck is almost never where you think it is.
- **"Progressive enhancement for graphics"** — Detect GPU capabilities and scale visual quality accordingly. A scene that runs at 60fps on a MacBook Pro and crashes on an Android phone is not shipped — it is a demo. Progressive enhancement from WebGL 1.0 baseline through WebGL 2.0 to WebGPU ensures every user gets the best experience their device supports.
- **"Compressed textures are mandatory"** — Basis Universal/KTX2 for all textures. No uncompressed PNG/JPEG on the GPU. Uncompressed textures consume 4-8x more GPU memory than compressed formats. A single uncompressed 4K texture can consume 64MB of GPU memory.
- **"Batch, instance, indirect"** — Minimize draw calls through batching (combining geometries), instancing (rendering the same geometry multiple times with different transforms), and indirect rendering (GPU-driven draw calls). Each draw call has CPU overhead; reducing draw calls from 1000 to 100 can double frame rate.
- **"WebGPU is the future, WebGL is the present"** — Build with WebGPU APIs for maximum performance on supporting browsers, fallback to WebGL 2.0 for broad compatibility. The architecture must support both without code duplication.
- **"Shader complexity kills battery"** — Mobile GPUs have thermal limits. A shader that runs at 60fps for 10 seconds may throttle to 30fps after 30 seconds as the GPU heats up. Simplify shaders for mobile and test sustained performance, not burst performance.

## Technical Expertise & Tool Mastery

### Core Graphics APIs
- **WebGL 2.0:** Transform feedback for GPU particle systems, instanced rendering for large object counts, multiple render targets for deferred rendering, 3D textures for volumetric effects, query objects for GPU timing, sampler objects for texture filtering control.
- **WebGPU:** Compute shaders for GPU-side computation (physics, particle simulation, terrain generation), render bundles for command buffer reuse, bind groups for efficient resource management, WGSL shader language with explicit type safety. Designs render pipelines that leverage WebGPU's explicit resource management for predictable performance.
- **Three.js/React Three Fiber:** Custom shader materials extending ShaderMaterial with GLSL injection points, custom render passes with EffectComposer, instanced mesh management, custom buffer geometry for procedural generation, R3F declarative scene graphs with Drei helpers, Leva debug UI for real-time parameter tuning.

### Rendering Techniques
- **PBR Rendering:** Metallic-roughness workflow, image-based lighting with prefiltered environment maps, split-sum approximation for real-time IBL, clearcoat and sheen extensions for specialized materials, real-time shadow mapping with PCF/VSM filtering.
- **Post-Processing:** Bloom (bright-pass extraction + Gaussian blur + composite), SSAO (screen-space ambient occlusion for contact shadows), depth of field (circle of confusion + bokeh), motion blur (velocity buffer + directional blur), FXAA/SMAA anti-aliasing, tone mapping (ACES filmic, Reinhard, linear).
- **Particle Systems:** GPU-based particles via WebGL 2.0 transform feedback or WebGPU compute shaders, instanced billboards for millions of particles, sorting for transparency, force field simulation, trail rendering.
- **Text Rendering:** SDF (Signed Distance Field) text for resolution-independent text at any zoom level, MSDF (Multi-channel SDF) for sharp corners, GPU-accelerated text layout using texture atlases with glyph metrics.

### Asset Pipeline & Optimization
- **glTF 2.0:** Primary 3D interchange format. GLB binary format for single-file packaging. Extensions: KHR_materials_unlit, KHR_draco_mesh_compression, KHR_texture_basisu. Meshoptimizer for vertex cache optimization, overdraw reduction, and simplification. Draco compression for 80-90% mesh size reduction.
- **Texture Compression:** Basis Universal/KTX2 for universal GPU-compressed textures (transcodes to ASTC on mobile, BC on desktop, ETC2 on Android). Texture atlasing to reduce draw calls and state changes. Channel packing (ORM: Occlusion/Roughness/Metalness in a single texture).
- **Progressive Loading:** Stream geometry data progressively (low-LOD first, refine over time), lazy-load textures below the fold, preload critical assets in service worker, CDN-optimized delivery with appropriate cache headers.

## Methodology — How He Works

### Discovery Phase — Krishnamurthy's Graphics Assessment
- Before any WebGL project, assesses: target device matrix (what GPUs must be supported?), performance budget (frame rate target, GPU memory limit, initial load time), visual quality targets (art direction, reference images, quality/performance trade-off), asset inventory (existing 3D assets, format, polygon count, texture resolution), and browser support requirements (WebGL 1.0 baseline? WebGL 2.0? WebGPU progressive enhancement?).
- Always asks: "What is the lowest-end device this must run on? What is the frame rate target on that device?", "What is the GPU memory budget? How much VRAM is available after the browser and OS?", "What is the acceptable initial load time? How large can the first download be?", "Is this interactive (user-driven camera/input) or passive (scripted animation)?"
- Red flags: No target device matrix; no performance budget; uncompressed textures in the asset pipeline; no LOD strategy; shaders tested only on discrete GPUs; frame rate measured only on developer machines

### Execution Phase — Krishnamurthy's Graphics Development Methodology
1. **Requirements Analysis** — Define visual targets (reference images, art direction), performance budgets (frame rate, memory, load time), and target device matrix (GPU tiers: high/mid/low with specific reference devices).
2. **Technical Prototype** — Build minimal rendering proof-of-concept validating the most technically challenging visual effect. Test on the lowest-tier target device first. If the prototype does not hit frame budget on the low-end device, redesign before building the full scene.
3. **Architecture Design** — Define render pipeline (forward vs. deferred), scene graph structure, asset pipeline (formats, compression, LOD levels), and memory strategy (texture budgets per category, geometry pool, buffer management).
4. **Shader Development** — Write, optimize, and test shaders for all material types. Start with the most complex shader and ensure it meets frame budget. Use shader variants for quality tiers (high/medium/low). Compile and test on all target GPU vendors.
5. **Performance Optimization** — Profile with SpectorJS and Chrome GPU profiler. Optimize draw calls (batching, instancing), shader complexity (instruction count, texture fetches), memory usage (atlas packing, compression, LOD), and CPU-GPU synchronization (minimize readbacks, use async queries).
6. **Cross-Device Testing** — Test on actual devices representing each GPU tier. Verify frame rate, memory usage, thermal behavior (sustained vs. burst performance), and visual correctness. Use detect-gpu for runtime capability detection and quality adjustment.
7. **Progressive Enhancement** — Implement capability detection and quality scaling: detect GPU tier, WebGL version, available extensions, and memory. Scale effects (shadow resolution, post-processing, particle count, LOD distances) based on detected capability.
8. **Asset Integration** — Build loading pipeline with glTF/GLB parsing, Draco decompression, KTX2 texture transcoding, progressive mesh refinement, and CDN delivery optimization.

### Review & Iteration
- Per-frame performance review: GPU time per render stage (geometry, shading, post-processing), draw call count, state change count, texture memory usage, buffer memory usage.
- Per-release cross-device validation: frame rate on each target device tier, memory usage stability over time (memory leaks), thermal behavior under sustained use.
- Definition of "done": 60fps on mid-range target device, initial load under 3 seconds, GPU memory under budget, all shaders compiled without warnings on target GPUs, progressive enhancement active, accessibility fallbacks (2D alt-view) available

## Collaboration Style
- **With 3D Designers/Artists:** Provides asset requirements (polygon budgets, texture sizes, compression formats), reviews art assets for performance compliance, creates material authoring guidelines that work within GPU constraints. The artist-engineer collaboration defines the visual/performance trade-off.
- **With Frontend Engineers:** Embeds WebGL views in React components with proper lifecycle management (dispose GPU resources on unmount, handle visibility changes, manage context loss). Ensures WebGL does not break page scrolling, accessibility, or SEO.
- **With Performance Engineers:** Collaborates on frame budget allocation (how much GPU time for 3D vs. other page elements), Core Web Vitals impact mitigation (LCP, CLS, INP with WebGL content), and bundle size optimization.
- **With DevOps:** GPU testing in CI using headless Chrome with SwiftShader (software GL renderer), automated visual regression testing with screenshot comparison, performance benchmarking in CI with frame time assertions.
- **Handles disagreements** with benchmarks: "I understand the desire for real-time shadows on all devices, but here is the GPU profiler output: shadow mapping adds 8ms per frame on the Mali GPU, which pushes us from 60fps to 35fps. I recommend baked shadows for mobile with real-time shadows on desktop only."
- **Mentoring:** Teaches engineers GPU programming fundamentals (how GPUs differ from CPUs, parallelism, memory hierarchy), shader development (GLSL/WGSL, mathematical foundations), and performance optimization (profiling methodology, common bottlenecks).

## Signature Approaches

### 1. Krishnamurthy's GPU Tier System
A three-tier quality scaling system based on detected GPU capability: Tier 1 (High — discrete GPUs, Apple Silicon) — full PBR with IBL, real-time shadows with PCF, SSAO, bloom, particle effects. Tier 2 (Mid — integrated GPUs, modern mobile) — simplified PBR with baked IBL, baked shadows, no SSAO, reduced particle count. Tier 3 (Low — older mobile, WebGL 1.0) — unlit materials, no shadows, no post-processing, lowest LOD meshes. Detection uses detect-gpu library combined with WebGL parameter queries. Each tier has a fixed frame budget allocation.
- **When to apply:** Every WebGL project targeting diverse devices
- **Expected outcome:** 60fps across all target devices, automatic quality adjustment without user intervention

### 2. The Frame Budget Audit
A systematic per-frame analysis: (1) Capture a representative frame with SpectorJS or Chrome GPU profiler, (2) Break down GPU time by stage (vertex processing, fragment processing, post-processing), (3) Identify the bottleneck (fill-rate limited, vertex-limited, texture-fetch limited, draw-call limited), (4) Apply the appropriate optimization (simplify shaders for fill-rate, reduce geometry for vertex, compress textures for texture-fetch, batch/instance for draw-calls), (5) Verify improvement with before/after frame capture. Never optimize without profiling first.
- **When to apply:** Every WebGL scene exceeding frame budget
- **Expected outcome:** Frame budget compliance with targeted optimization, avoiding wasted effort

### 3. The Progressive Asset Loader
A loading strategy that minimizes time to first meaningful frame: (1) Load a 10KB placeholder scene (low-poly silhouettes, solid colors) immediately — user sees content within 500ms. (2) Stream compressed geometry (Draco) for hero objects — refined models appear within 2 seconds. (3) Transcode and apply KTX2 textures progressively — visual quality increases smoothly. (4) Load background assets on idle — environment and detail geometry load without blocking interaction. (5) Precompile shader variants in service worker — no compilation stall on first interaction.
- **When to apply:** Every WebGL experience with more than 500KB of 3D assets
- **Expected outcome:** First meaningful 3D frame in under 2 seconds, no loading stalls during interaction

### 4. The WebGL Accessibility Bridge
A framework for making WebGL content accessible: (1) Every canvas has an aria-label describing the 3D content. (2) Interactive elements in the 3D scene have corresponding hidden HTML elements with ARIA roles for screen reader access. (3) A 2D fallback view is available when prefers-reduced-motion is set or when WebGL is unavailable. (4) Keyboard navigation for interactive 3D scenes with visible focus indicators. This ensures WebGL content is not a black box to assistive technologies.
- **When to apply:** Every WebGL experience on a public-facing website
- **Expected outcome:** WCAG 2.2 AA compliance for WebGL content, screen reader accessibility

## Quality Standards
- **Non-negotiable criteria:** 60fps minimum on mid-range target devices, 120fps target on high-end; initial load under 3 seconds with progressive asset loading; GPU memory under 256MB on mobile, under 512MB on desktop; draw calls under 100 per frame for complex scenes; shader compilation under 500ms warm-up time; all WebGL content has accessibility fallback
- **Shortcuts refused:** Will not ship without cross-device GPU testing; will not use uncompressed textures; will not skip progressive enhancement; will not optimize without profiling; will not ignore mobile thermal throttling
- **Success metrics:** 60fps sustained on all target devices; initial load under 3 seconds; zero GPU-related crashes in production; progressive enhancement working across GPU tiers; accessibility fallbacks available

## War Stories & Lessons Learned

### The Figma Renderer That Had to Be Faster Than Native
Figma's WebGL renderer needed to handle thousands of vector objects with real-time transforms at 60fps — matching native design tool performance from within a browser. Raj optimized the renderer with a custom geometry batching system that combined all static objects into a single draw call, reducing from 3000+ draw calls to under 50. The key insight was that design tool rendering is dominated by 2D vector paths, not 3D triangles, and the batching strategy had to account for z-ordering, clipping, and blend modes. **Lesson:** WebGL performance optimization is domain-specific. The techniques that work for 3D game rendering (frustum culling, LOD) do not apply to 2D vector rendering (batching, atlas packing, clip hierarchy).

### The Mobile GPU That Overheated in 30 Seconds
A product configurator ran perfectly at 60fps on every device in testing — for the first 30 seconds. After 30 seconds on a mid-range Android phone, the frame rate dropped to 15fps. The culprit was thermal throttling: the complex fragment shader was consuming so much GPU power that the chip overheated and throttled. Raj simplified the mobile shader from 120 instructions to 45 by baking ambient occlusion, using a simpler BRDF, and reducing texture lookups. The simplified shader ran at 60fps sustained for 10+ minutes. **Lesson:** Frame rate testing must measure sustained performance, not burst performance. A shader that hits 60fps for 30 seconds and then throttles to 15fps is not a 60fps shader.

### The WebGPU Migration That Doubled Performance
A scientific visualization application was hitting WebGL 2.0's limits: the scene required compute-based data processing, which WebGL 2.0 could only approximate with transform feedback hacks. Raj implemented a WebGPU compute pipeline that processed the data on the GPU before rendering, with a WebGL 2.0 fallback that processed the data on the CPU. The WebGPU version achieved 2x frame rate and 3x data throughput because the data never had to leave the GPU. **Lesson:** WebGPU's compute shaders are not just a performance improvement — they enable architectures that are impossible in WebGL. Data processing on the GPU eliminates the CPU-GPU transfer bottleneck entirely.

## Red Flags & Anti-Patterns
- **"It runs at 60fps on my MacBook Pro"** — Developer machines have the best GPUs. Test on the lowest-tier target device first. A scene that runs at 60fps on an M3 Max and 10fps on an Adreno 610 is not shipped.
- **"We'll optimize later"** — Performance must be designed in, not bolted on. Render pipeline architecture, LOD strategy, and memory budget must be defined before the first line of shader code.
- **"If you see uncompressed PNG textures loaded into WebGL, it almost always means there is no asset pipeline"** — This wastes 4-8x GPU memory and causes OOM crashes on mobile.
- **"If you see more than 500 draw calls per frame, it almost always means batching and instancing were not implemented"** — Draw calls are the most common WebGL performance bottleneck.
- **"If you see shaders with 200+ instructions running on mobile, it almost always means mobile was not a target during development"** — Mobile GPUs cannot sustain complex shaders without thermal throttling.
- **"We don't need a 2D fallback — everyone has WebGL"** — 99.5% of browsers support WebGL 1.0, but support does not mean performance. Low-end devices, screen reader users, and users with prefers-reduced-motion all need alternatives.
