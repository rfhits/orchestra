# REAPER MCP Feature TODO (Research-Based)

This list focuses on practical music-production workflows that are still missing in the current MCP layer.
For each item: **What it is** and **Why it matters**.

## P0 (Most Important)

### 1) Routing / Sends / Receives / Hardware Outputs
- What:
  - Create/remove sends.
  - List sends/receives.
  - Set send gain/pan/mute and key routing flags.
- Why:
  - Real-world mixes rely on buses, parallel processing, and sidechain.
  - Without routing APIs, projects cannot be structured like actual production sessions.

### 2) FX Chain Management (Track FX + Take FX)
- What:
  - Add/remove FX by name.
  - List FX chain.
  - Enable/disable FX.
  - Read/write key FX parameters (normalized).
- Why:
  - Plugin control is a core DAW operation.
  - Necessary for automatic cleanup chains, vocal chains, stem processing, and A/B comparison.

### 3) Automation Envelope Editing
- What:
  - Get envelope by name (volume/pan/FX parameter).
  - Insert/update/delete envelope points.
  - Batch edit and sort points safely.
- Why:
  - Mix quality depends on automation (volume rides, transitions, FX movement).
  - Essential for dynamic edits that cannot be done with static values.

## P1 (High Value)

### 4) Region Workflow + Region Render Matrix
- What:
  - Create/list/update/delete regions.
  - Assign track-region render matrix for batch exports.
- Why:
  - Common in delivery workflows (per-section bounces, per-stem renders, album pipelines).
  - Makes structured export reproducible and fast.

### 5) Recording Prep Controls
- What:
  - Set/get rec-arm.
  - Set/get monitoring mode.
  - Set/get record input and record mode.
- Why:
  - Critical for real recording sessions (vocals/instruments).
  - Prevents setup errors and makes AI-assisted recording practical.

### 6) Item Micro-Editing Parameters
- What:
  - Item gain, fade-in/out, auto-fade.
  - Take playrate and pitch.
- Why:
  - Daily editing tasks depend on these parameters.
  - Needed for cleanup, transitions, timing fixes, and creative sound design.

## P2 (Advanced but Very Useful)

### 7) Fixed Lanes / Comping Helpers
- What:
  - Read/set fixed-lane related track/item properties.
  - Basic lane play-state controls for comp workflows.
- Why:
  - Modern REAPER editing heavily uses lanes for multi-take vocals/instruments.
  - Improves take selection and comp speed.

### 8) Razor Edit Helpers
- What:
  - Read/write razor edit definitions.
  - Use razor ranges for precise batch operations.
- Why:
  - Fastest way to perform precise timeline+lane scoped edits in REAPER.
  - Enables surgical AI edits with low collateral changes.

## Suggested Delivery Order
1. Routing / Sends
2. FX Chain Management
3. Automation Envelopes
4. Regions + Render Matrix
5. Recording Prep
6. Item Micro-Editing
7. Fixed Lanes
8. Razor Edit Helpers

