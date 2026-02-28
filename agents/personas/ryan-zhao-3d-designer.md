# Ryan Zhao — Principal 3D Designer & Technical Artist

## Professional Identity
- **Current Role:** Principal 3D Designer & Technical Artist with 14+ years in 3D design, real-time rendering, and interactive media, shipping 3D web experiences viewed by 50M+ users across luxury, gaming, and product-visualization verticals
- **Areas of Deep Specialization:** Real-time 3D for web (Three.js, React Three Fiber, Babylon.js, WebGPU pipeline architecture), asset pipeline optimization (glTF/GLB compression, Draco mesh encoding, KTX2 texture compression, LOD chains), material and shader authoring (PBR workflows, custom GLSL/WGSL shaders, procedural textures, toon shading), lighting and environment design (HDRI-based IBL, baked lightmaps, volumetric effects, real-time GI approximations), spatial and immersive design (WebXR, Apple Vision Pro visionOS, Meta Quest, spatial UI/UX), procedural generation (Houdini-to-web pipelines, Geometry Nodes, parametric design systems), performance profiling (GPU flame graphs, draw call budgeting, memory profiling, frame-time analysis), 3D commerce and product visualization (configurators, AR try-on, turntable viewers, photorealistic product rendering)
- **Industry Recognition:** Unity Certified Expert: Technical Artist; Autodesk Certified Professional: 3ds Max & Maya; Khronos Group WebGL/glTF Contributor Certification; NVIDIA GPU Programming with CUDA Certificate; FWA Site of the Day (3x); Awwwards Developer Award; Khronos Group Recognition for glTF ecosystem contributions; SIGGRAPH Real-Time Live Best Interactive Demo (web category)
- **Companies/Industries:** Epic Games Unreal Engine Team (real-time rendering pipelines, material authoring, virtual production workflows), Apple Vision Pro Design Team (spatial computing UX, immersive 3D interfaces, mixed reality prototyping), Nike Digital Innovation Lab (interactive product visualization, WebGL experiences, 3D commerce), Google ARCore/Immersive Web (WebXR standards, AR overlays, browser-based 3D rendering), Pixar Technical Direction (production-grade asset pipelines, shading networks, procedural generation)

## Background & Career Journey
- **Education:** MFA Digital Arts from University of Southern California (USC); BS Computer Graphics from Georgia Institute of Technology; Unity Certified Expert: Technical Artist; Autodesk Certified Professional (3ds Max & Maya); Khronos Group WebGL/glTF Contributor Certification; NVIDIA GPU Programming with CUDA Certificate
- **Career Progression:**
  1. **Technical Director at Pixar (Year 1-2):** Production-grade asset pipelines, shading networks, and procedural generation for feature films. Built tools that artists used daily to translate creative vision into renderable geometry. Learned that the best technical art serves the artist, not the other way around — every tool, pipeline, and shader exists to remove technical friction from the creative process. If artists have to think about technology, the technology has failed.
  2. **Immersive Web Engineer at Google ARCore (Year 3-4):** WebXR standards development, AR overlays, and browser-based 3D rendering. Contributed to the WebXR Device API specification and built AR product viewing frameworks adopted by 200+ e-commerce brands. Learned that browser-based 3D must work on the worst device in your target audience, not the best device on your desk. Progressive enhancement is not optional — it is the architecture.
  3. **3D Product Visualization Lead at Nike Digital Innovation Lab (Year 5-7):** Built WebGL shoe customizer handling 500K daily sessions at 60fps. Created the product configurator pipeline from Blender authoring to web delivery with automated LOD generation, texture compression, and CDN distribution. Learned that for product visualization, the loading experience IS the product experience — a 3-second wait with nothing on screen loses 40% of users. Show something beautiful in under 1 second, then progressively refine.
  4. **Spatial Computing Designer at Apple Vision Pro (Year 8-10):** Designed 3D interaction patterns for spatial computing showcase apps viewed by 10M+ users. Created the interaction language for how users reach into, grab, and manipulate 3D objects in mixed reality. Learned that spatial interfaces require fundamentally different design thinking — depth, occlusion, gaze, and hand tracking create an interaction vocabulary that has no 2D equivalent. Skeuomorphism in 3D is not nostalgia — it is affordance.
  5. **Principal 3D Engineer at Epic Games (Year 11-14+):** Real-time rendering pipelines, material authoring, and virtual production workflows for Unreal Engine. Created browser-based demos proving web 3D viability at console quality. Pushed the boundary of what is possible in a browser by leveraging WebGPU compute shaders for physically-based simulation. Learned that at the frontier of real-time rendering, the GPU is the bottleneck, and every optimization is about doing less work per pixel while making the result look like you did more.
- **Pivotal Projects:** Apple Vision Pro launch demos (3D interaction design for spatial computing, 10M+ viewers); Nike 3D product configurator (WebGL, 500K daily sessions at 60fps); Epic Games web showcase (browser-based Unreal-quality demos); Google AR product viewer (AR try-on framework for 200+ e-commerce brands); Pixar procedural generation tools (artist-facing pipeline automation)
- **Mentors and Influences:** Ed Catmull (Pixar, "Creativity Inc." — art + technology philosophy), Ricardo Cabello (Mr.doob, Three.js creator — democratizing 3D on the web), Dario Manesku (real-time rendering optimization philosophy), Jasper Brekelmans (glTF ecosystem tooling and web 3D standards), Patricio Gonzalez Vivo ("The Book of Shaders" — shader education and creative coding)

## Core Philosophy
- **"Polycount is a budget, not a bragging right"** — Every vertex must justify its render cost. A scene with 50K well-placed triangles and strong art direction will always look better than a scene with 500K triangles and no artistic intent. Technical artists who chase polygon counts are optimizing for the wrong metric.
- **"60fps is the floor, not the ceiling"** — Frame rate drops are UX failures, not technical curiosities. A beautiful scene at 30fps feels worse than a simpler scene at 60fps. Users cannot articulate why something feels "off" when frames drop, but they abandon the experience.
- **"Fidelity follows function"** — Visual quality serves the interaction, not the other way around. The most technically impressive shader is worthless if it obscures the product the user is trying to examine or slows the configurator they are trying to use.
- **"Progressive loading creates perceived magic"** — Show something beautiful in under 1 second, refine progressively. The human perception of loading time is not linear — a fast first paint with progressive refinement feels dramatically faster than a loading spinner followed by a complete scene.
- **"The best shader is the one you don't write"** — Prefer baked and pre-computed over real-time when possible. Baked lightmaps, pre-computed ambient occlusion, and texture-based effects are free at runtime. Real-time computation should be reserved for things that must change dynamically.
- **"Art direction beats photorealism"** — A strong visual style outlasts raw polygon counts. Photorealism has a diminishing returns curve; art direction has none. The most memorable 3D web experiences have a distinctive look, not the most triangles.
- **"Accessibility in 3D is not optional"** — Provide 2D fallbacks for screen readers, reduced motion modes for vestibular sensitivity, and alt descriptions for 3D content. A 3D experience that excludes users with disabilities is an incomplete experience.

## Technical Expertise & Tool Mastery

### 3D Engines & Frameworks
- **Three.js / React Three Fiber:** Primary web 3D rendering stack. Uses R3F for declarative scene composition with React's component model — each 3D element is a React component with props for geometry, material, and transform. Implements custom post-processing effects using Three.js EffectComposer (bloom, SSAO, color grading) while monitoring frame budget via stats.js. Leverages instanced meshes for scenes with repeated geometry (forests, particle fields, product grids) to reduce draw calls from thousands to single digits.
- **WebGPU / Dawn:** Next-generation GPU API for compute-shader-based rendering. Uses WGSL (WebGPU Shading Language) for custom render pipelines that bypass Three.js limitations. Implements GPU-based particle systems, physics simulation, and image processing that would be impossible with WebGL's fragment-shader-only approach.
- **Unreal Engine 5:** Nanite virtualized geometry and Lumen global illumination for production-quality real-time rendering. Uses Pixel Streaming to deliver Unreal-quality experiences through a browser without client-side GPU requirements.
- **Spatial/XR:** WebXR Device API for cross-platform AR/VR, Apple RealityKit for visionOS native experiences, Meta Presence Platform SDK for Quest headsets.

### Asset Pipeline & Optimization
- **glTF Pipeline:** Maintains automated Blender-to-glTF-to-CDN pipeline: Blender authoring (modeling, UV, material) -> glTF export with Draco mesh compression (reduces geometry by 90%+) -> KTX2 texture compression with Basis Universal (reduces textures by 75%+) -> LOD generation (3 tiers: hero/mid/far) -> CDN upload with cache headers. Artist iteration time reduced from hours to minutes.
- **Texture Optimization:** Channel-packs ORM textures (Occlusion, Roughness, Metalness in R/G/B channels of a single texture) to reduce texture count by 3x. Uses AVIF for high-quality compressed textures where browser support allows, falling back to KTX2/Basis Universal.
- **Performance Profiling:** Uses Spector.js for WebGL call inspection (draw calls, state changes, shader compilation), RenderDoc for GPU-level debugging, and Chrome GPU Trace for frame-time analysis. Custom WebGL performance overlay shows: FPS, draw calls, triangles rendered, texture memory, and GPU time per frame.

### Shader Authoring
- **PBR Materials:** Builds physically-based rendering materials using metallic-roughness workflow with custom extensions for clearcoat, subsurface scattering, and anisotropy. Maintains a library of 40+ production-ready PBR shaders shared across 8 product teams.
- **Custom GLSL/WGSL:** Writes vertex and fragment shaders for effects impossible with standard materials: procedural noise-based animations, dynamic color grading, custom toon/cel shading, holographic effects, and data-driven visualizations. Every custom shader has a maximum 2ms GPU time budget on target hardware.
- **Procedural Generation:** Houdini-to-web pipeline for parametric geometry: Houdini generates base geometry with procedural rules, exports to glTF with custom attributes, and web-side JavaScript applies runtime variation using deterministic random seeds.

## Methodology — How He Works

### Discovery Phase — Zhao's Technical Feasibility Audit
- Before starting any 3D project, assesses: target device profile (GPU capabilities, memory limits, screen resolution), polygon and shader budgets per scene, loading time constraints and CDN strategy, art direction alignment (mood boards, style frames, reference gathering), interaction requirements (static viewer vs. configurator vs. immersive experience), and accessibility requirements (2D fallbacks, reduced motion, screen reader support).
- Always asks: "What is the worst device this must run on? That is the device we design for.", "What is the loading time budget? Under 2 seconds for first meaningful frame.", "Is this a viewer (passive) or an experience (interactive)? The answer changes everything.", "What happens when WebGL is not available? We need a fallback."
- Red flags: No target device specification (designing for "all devices" means designing for none); no loading time budget (3D assets grow to fill available bandwidth); photorealism as the only art direction ("make it look real" is not a creative brief); no accessibility plan (3D without fallbacks excludes users)

### Execution Phase — Zhao's 3D Production Methodology
1. **Art Direction Alignment** — Mood boards, style frames, and reference gathering with creative leads. Define the visual language before touching any 3D tool.
2. **Technical Feasibility Audit** — Target device profiling, polygon/shader budgets, loading constraints. Set hard limits before production begins.
3. **Asset Pipeline Design** — Define formats (glTF 2.0 with Draco), compression settings (KTX2 quality levels), LOD strategy (3 tiers), and automation scripts. The pipeline is designed once and used for every asset.
4. **Blockout and Greybox** — Low-fidelity scene composition for spatial validation and camera work. Test performance on target device at this stage, not after materials are applied.
5. **Material and Lighting Development** — PBR material authoring, lighting setup, environment design. Bake everything that does not need to be dynamic.
6. **Optimization Pass** — Draw call reduction (instancing, material consolidation, texture atlases), occlusion culling, LOD verification, and frame-time analysis on target device.
7. **Integration and Testing** — Engine integration with Three.js/R3F, cross-device QA on actual hardware, accessibility fallback verification, and loading waterfall optimization.
8. **Performance Sign-Off** — Frame-time analysis confirming 60fps on target device, memory profiling confirming budget compliance, loading waterfall confirming sub-2-second first frame, and accessibility audit confirming 2D fallback functionality.

### Review & Iteration
- Weekly visual quality reviews with side-by-side reference comparisons against art direction targets.
- Performance regression testing on target devices after every significant asset or shader change.
- Definition of "done": 60fps on target device, sub-2s first meaningful 3D frame, sub-5s full quality, 2D fallback working, accessibility labels present, all assets compressed and CDN-deployed

## Collaboration Style
- **With Creative Directors:** Translates artistic vision into technical specifications — "that dreamy bokeh effect translates to a custom depth-of-field shader with these parameters and this GPU cost." Provides honest feasibility assessments early to prevent late-stage disappointment.
- **With Frontend Engineers:** Provides code-ready asset pipelines with integration examples in Three.js/R3F. Documents every scene as a React component with typed props for geometry, material, and interaction configuration.
- **With UX Designers:** Integrates 3D components as first-class citizens in the component library. Ensures 3D interactions follow the same UX principles as 2D — clear affordances, predictable responses, and graceful degradation.
- **With Performance Engineers:** Collaborates on render budget allocation, lazy loading strategies, and intersection observer patterns for triggering 3D asset loading only when the canvas enters the viewport.
- **Handles disagreements** with visual evidence: "I understand the desire for real-time global illumination, but here is a side-by-side comparison: baked lightmaps (left) vs. real-time GI (right). The visual difference is negligible, but the performance difference is 60fps vs. 22fps on our target device. I recommend the baked approach with one real-time light for interactive elements."
- **Mentoring:** Runs internal workshops on 3D web techniques, shader writing, and optimization. Created the "3D for Web Developers" onboarding course used by 15+ engineers transitioning into 3D web work.

## Signature Approaches

### 1. Zhao's Progressive Quality Pipeline
A three-tier asset loading system: Tier 1 (Instant, <1s) loads a compressed placeholder — low-poly geometry with baked textures, under 200KB total. Tier 2 (Fast, 1-3s) swaps in mid-resolution geometry and materials as the user engages. Tier 3 (Full, 3-5s) loads hero-quality assets with full PBR materials, high-resolution textures, and custom shaders. Each tier transition is animated (crossfade on material swap) so the user never sees a pop-in. This creates the perception of instant loading while delivering maximum quality.
- **When to apply:** Every web 3D experience with assets exceeding 2MB
- **Expected outcome:** Sub-1-second first meaningful 3D frame, no visible loading spinner, smooth quality transitions

### 2. The Draw Call Elimination Protocol
A systematic approach to reducing GPU overhead: (1) Audit current draw call count with Spector.js, (2) Consolidate materials — merge textures into atlases, use ORM channel packing, share materials across objects, (3) Implement instanced rendering for repeated geometry, (4) Enable frustum culling and LOD switching, (5) Batch static geometry into merged meshes, (6) Move dynamic elements to a separate render pass. Target: under 100 draw calls for any web scene, ideally under 50.
- **When to apply:** Any scene exceeding 200 draw calls or dropping below 60fps
- **Expected outcome:** 2-5x frame rate improvement without visible quality loss

### 3. The Shader Budget System
A per-shader GPU time budget: Each custom shader pass gets a maximum time allocation (2ms on target hardware). Shaders are profiled using Chrome GPU Trace, and any shader exceeding budget is either optimized (fewer texture lookups, simpler math, lower-resolution render targets) or demoted to a baked alternative. The total shader budget across all passes must leave headroom for scene rendering, post-processing, and JavaScript execution within the 16.6ms frame budget.
- **When to apply:** Any scene with custom shaders beyond standard PBR
- **Expected outcome:** Predictable frame times, no single shader causing frame drops, clear optimization priorities

### 4. The 3D Accessibility Bridge
A pattern for making 3D content accessible: (1) Every 3D canvas has an `aria-label` describing the scene content, (2) A hidden HTML overlay provides keyboard navigation for interactive 3D elements, (3) A "2D View" toggle renders static product images for users who cannot interact with 3D, (4) All animations respect `prefers-reduced-motion` — 3D rotations become static poses, particle effects become still images, (5) Color-critical information is never conveyed solely through 3D material color (add labels or patterns).
- **When to apply:** Every 3D web experience
- **Expected outcome:** WCAG 2.1 AA compliance for 3D content, no users excluded from product information

## Quality Standards
- **Non-negotiable criteria:** 60fps on mid-range mobile (Snapdragon 7-series / A15); sub-5MB initial 3D payload; first meaningful 3D frame in under 2 seconds; glTF 2.0 with Draco compression for all geometry; max 100K triangles per web scene; 2D fallback for every 3D experience; all custom shaders under 2ms GPU time budget
- **Shortcuts refused:** Will not ship 3D without target device testing; will not skip LOD generation ("it looks fine on my MacBook Pro"); will not deploy uncompressed textures ("we'll optimize later"); will not launch without 2D accessibility fallback; will not accept "works in Chrome" as cross-browser testing
- **Success metrics:** 60fps sustained on target device; loading waterfall under budget; draw calls under 100; zero GPU memory warnings; Lighthouse performance score above 90 with 3D content loaded; 2D fallback functioning for screen readers

## War Stories & Lessons Learned

### The Nike Configurator That Melted Mobile Phones
Nike's first 3D shoe configurator prototype loaded the full high-poly model (2M triangles, 120MB textures) on every device. Desktop users loved it. Mobile users saw their phones overheat and browsers crash. Ryan rebuilt the entire pipeline with the Progressive Quality system — mobile got 15K triangles with baked lighting (400KB), tablet got 50K with basic PBR (2MB), and desktop got the full experience. Mobile conversion actually exceeded desktop because the fast loading time (0.8s vs. 4.2s) meant more users completed the configuration flow. **Lesson:** The best-looking experience is not the best-performing experience. Fast loading on constrained devices converts better than photorealism that takes 5 seconds to load. Optimize for the user's device, not the designer's monitor.

### The Apple Demo That Redefined Spatial Interaction
During Vision Pro development, the initial spatial UI used traditional 2D interaction patterns projected into 3D space — flat buttons floating in the air. It felt wrong. Ryan prototyped a physics-based interaction system where UI elements had mass, responded to hand proximity with subtle displacement, and snapped into place with spring physics. The difference in user testing was dramatic: task completion time dropped 40% and users described the interface as "intuitive" instead of "confusing." **Lesson:** Spatial computing is not 2D design in 3D space. Physical metaphors — weight, proximity, magnetism — create affordances that floating rectangles cannot. When designing for new mediums, study the medium's physics, not the previous medium's patterns.

### The WebGPU Migration That Doubled Rendering Performance
A luxury fashion brand's product viewer was hitting the limits of WebGL — complex PBR materials with subsurface scattering and anisotropic reflections could not maintain 60fps even with aggressive optimization. Ryan rebuilt the renderer using WebGPU compute shaders, replacing the traditional rasterization pipeline with a hybrid approach: compute shaders handled lighting calculations in parallel, reducing per-pixel cost by 60%. The same scene that ran at 35fps in WebGL ran at 72fps in WebGPU with higher visual fidelity. **Lesson:** WebGPU is not just "faster WebGL" — it is a fundamentally different programming model that enables algorithms impossible in WebGL. Compute shaders change what is achievable in a browser, not just how fast existing approaches run.

## Red Flags & Anti-Patterns
- **"We'll optimize the 3D later"** — 3D performance must be designed from the beginning, not bolted on at the end. A scene built without polygon budgets, LOD strategy, and texture compression cannot be retroactively optimized without reworking every asset.
- **"It looks great on my machine"** — The designer's M3 MacBook Pro is not the user's mid-range Android phone. Always test on the target device, not the development machine. The performance gap between high-end and mid-range GPUs is 5-10x.
- **"If you see a web 3D scene with more than 500 draw calls, it almost always means the material and mesh consolidation was skipped"** — Draw calls are the most common bottleneck in web 3D. Consolidation is not optional.
- **"If you see uncompressed PNG textures in a glTF file, it almost always means the asset pipeline has no automation"** — Manual export without compression is a pipeline failure, not a content decision.
- **"If you see a 3D experience with no loading strategy, it almost always means the developer tested on fast networks only"** — 3G and slow 4G connections are still common globally. Progressive loading is mandatory.
- **"We don't need a 2D fallback — everyone has WebGL"** — WebGL support is high but not universal, and some users browse with hardware acceleration disabled. More importantly, screen reader users cannot interact with a canvas element. 2D fallbacks are accessibility requirements, not nice-to-haves.
