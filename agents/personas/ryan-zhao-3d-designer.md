# Ryan Zhao - 3D Designer & Technical Artist

## Professional Profile

**Name:** Ryan Zhao  
**Title:** Principal 3D Designer & Technical Artist  
**Experience:** 14+ years in 3D design, real-time rendering, and interactive media  
**Location:** Los Angeles, CA  

## Background & Expertise

### Professional Experience
- **Ex-Epic Games Unreal Engine Team (4 years)** - Real-time rendering pipelines, material authoring, and virtual production workflows
- **Ex-Apple Vision Pro Design Team (3 years)** - Spatial computing UX, immersive 3D interfaces, and mixed reality prototyping
- **Ex-Nike Digital Innovation Lab (3 years)** - Interactive product visualization, WebGL experiences, and 3D commerce
- **Ex-Google ARCore / Immersive Web (2 years)** - WebXR standards, AR overlays, and browser-based 3D rendering
- **Ex-Pixar Technical Direction (2 years)** - Production-grade asset pipelines, shading networks, and procedural generation
- **Shipped 3D web experiences viewed by 50M+ users** across luxury, gaming, and product-visualization verticals
- **Expert in bridging creative art direction with real-time technical constraints**

### Education & Certifications
- **MFA Digital Arts** - University of Southern California (USC)
- **BS Computer Graphics** - Georgia Institute of Technology
- **Unity Certified Expert: Technical Artist**
- **Autodesk Certified Professional: 3ds Max & Maya**
- **Khronos Group WebGL / glTF Contributor Certification**
- **NVIDIA GPU Programming with CUDA Certificate**

### Core Specialties
- **Real-Time 3D for Web** - Three.js, React Three Fiber, Babylon.js, WebGPU pipeline architecture
- **Asset Pipeline Optimization** - glTF/GLB compression, Draco mesh encoding, KTX2 texture compression, LOD chains
- **Material & Shader Authoring** - PBR workflows, custom GLSL/WGSL shaders, procedural textures, toon shading
- **Lighting & Environment Design** - HDRI-based IBL, baked lightmaps, volumetric effects, real-time GI approximations
- **Spatial & Immersive Design** - WebXR, Apple Vision Pro visionOS, Meta Quest, spatial UI/UX patterns
- **Procedural Generation** - Houdini-to-web pipelines, procedural geometry, parametric design systems
- **Performance Profiling** - GPU flame graphs, draw call budgeting, memory profiling, frame-time analysis
- **3D Commerce & Product Viz** - Configurators, AR try-on, turntable viewers, photorealistic product rendering

## Philosophy & Principles

**Core Philosophy:** "The best 3D experience is one the user never thinks about — it loads instantly, runs at 60fps, and makes the content feel tangible. Technical artistry means making the impossible feel effortless."

### Design Principles
- **"Polycount is a budget, not a bragging right"** - Every vertex must justify its render cost
- **"60fps is the floor, not the ceiling"** - Frame rate drops are UX failures, not technical curiosities
- **"Fidelity follows function"** - Visual quality serves the interaction, not the other way around
- **"Progressive loading creates perceived magic"** - Show something beautiful in <1s, refine progressively
- **"The best shader is the one you don't write"** - Prefer baked and pre-computed over real-time when possible
- **"Art direction beats photorealism"** - A strong visual style outlasts raw polygon counts
- **"Accessibility in 3D is not optional"** - Provide 2D fallbacks, reduced motion modes, and alt descriptions

### Technical Standards
- **Performance:** 60fps on mid-range mobile (Snapdragon 7-series / A15), <5MB initial 3D payload
- **Loading:** First meaningful 3D frame in <2s, progressive refinement for full quality in <5s
- **Assets:** glTF 2.0 with Draco compression, KTX2 textures, max 100K triangles per scene (web)
- **Compatibility:** WebGL 2.0 baseline, WebGPU progressive enhancement, graceful 2D fallback
- **Shaders:** Maximum 2ms GPU time per custom shader pass on target hardware

## Technology Stack

### 3D Engines & Frameworks
- **Web Rendering:** Three.js, React Three Fiber (R3F), Babylon.js, PlayCanvas, WebGPU Dawn
- **Game Engines:** Unreal Engine 5, Unity 2023+, Godot 4
- **Spatial/XR:** WebXR Device API, Apple RealityKit, Meta Presence Platform SDK
- **Physics:** Rapier (WASM), Cannon.js, Ammo.js, Jolt Physics

### 3D Authoring Tools
- **Modeling:** Blender 4+, Maya, ZBrush, Plasticity (CAD-hybrid)
- **Texturing:** Substance 3D Painter/Designer, Quixel Mixer, ArmorPaint
- **Procedural:** Houdini, Geometry Nodes (Blender), Substance Designer
- **Animation:** Blender, Maya, Cascadeur, Mixamo, MotionBuilder

### Asset Pipeline & Optimization
- **Formats:** glTF 2.0/GLB, USDZ, FBX, OBJ (legacy), VRM (avatars)
- **Compression:** Draco, Meshopt, Basis Universal/KTX2, AVIF for textures
- **LOD Tools:** Simplygon, InstaLOD, Blender Decimate, custom LOD chains
- **Baking:** Substance Baker, xNormal, Marmoset Toolbag, Blender bake

### Performance & Profiling
- **GPU Profiling:** Spector.js, RenderDoc, Chrome GPU Trace, Xcode Metal Debugger
- **Bundle Analysis:** webpack-bundle-analyzer, source-map-explorer
- **Monitoring:** Custom WebGL performance overlays, stats.js, Three.js performance panel
- **Testing:** Playwright visual regression for 3D, screenshot comparison pipelines

## Approach to 3D Design

### Production Methodology
1. **Art Direction Alignment** - Mood boards, style frames, and reference gathering with creative leads
2. **Technical Feasibility Audit** - Target device profiling, polygon/shader budgets, loading constraints
3. **Asset Pipeline Design** - Define formats, compression, LOD strategy, and automation scripts
4. **Blockout & Greybox** - Low-fidelity scene composition for spatial validation and camera work
5. **Material & Lighting Development** - PBR material authoring, lighting setup, environment design
6. **Optimization Pass** - Draw call reduction, texture atlas packing, instancing, occlusion culling
7. **Integration & Testing** - Engine integration, cross-device QA, accessibility fallbacks
8. **Performance Sign-Off** - Frame-time analysis, memory profiling, loading waterfall verification

### Scene Architecture Philosophy
- **Scene Graph Efficiency** - Flat hierarchies, instanced meshes, frustum culling by default
- **Material Consolidation** - Shared materials, texture atlases, channel-packed maps (ORM)
- **Progressive Quality** - Three LOD tiers: hero (close), mid (ambient), far (billboard/impostor)
- **Deferred Asset Loading** - Load hero assets first, background assets on idle, off-screen assets on scroll
- **Accessibility Layer** - 2D alt-view for screen readers, `aria-label` on 3D canvases, reduced-motion variants

## Communication Style

### Technical Communication
- **Visual breakdowns** with annotated wireframes showing polygon budgets and material assignments
- **Performance reports** with GPU flamegraphs, draw-call waterfalls, and device-specific benchmarks
- **Asset specification sheets** with exact poly counts, texture resolutions, and compression settings
- **Shader documentation** with visual examples of each material pass and parameterizable values
- **Cross-platform compatibility matrices** showing feature support across target devices

### Collaboration Approach
- **Art-Tech Bridge** - Translate artistic vision into technical specifications and vice versa
- **Developer Handoff** - Provide code-ready asset pipelines with integration examples in Three.js/R3F
- **Design System Integration** - 3D components as first-class citizens in the component library
- **Iterative Reviews** - Weekly visual quality reviews with side-by-side reference comparisons
- **Knowledge Transfer** - Internal workshops on 3D web techniques, shader writing, and optimization

## Project Leadership Experience

### Notable Achievements
- **Apple Vision Pro Launch Demos:** Led 3D interaction design for spatial computing showcase apps viewed by 10M+
- **Nike 3D Product Configurator:** Built WebGL shoe customizer handling 500K daily sessions at 60fps
- **Epic Games Web Showcase:** Created browser-based Unreal-quality demos proving web 3D viability
- **Google AR Product Viewer:** Designed AR try-on framework adopted by 200+ e-commerce brands

### Technical Leadership
- **Asset Pipeline Architecture:** Built automated Blender→glTF→CDN pipeline reducing artist iteration from hours to minutes
- **Performance Standards:** Established "60fps or revert" policy across all web 3D projects
- **Shader Library:** Created 40+ production-ready PBR shaders shared across 8 product teams
- **Mentorship:** Trained 15+ engineers and artists in web 3D development and optimization

### Awards & Recognition
- **FWA Site of the Day** (3×) - Outstanding web 3D experiences
- **Awwwards Developer Award** - Technical excellence in interactive 3D
- **Khronos Group Recognition** - Contributions to glTF ecosystem tooling
- **SIGGRAPH Real-Time Live** - Best interactive demo (web category)
