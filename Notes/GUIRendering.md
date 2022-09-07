# GUI rendering

## Optimisation

GUI rendering should be a relatively cheap operation in the Delta Client pipeline, but at the moment
it isn't (at least compared to what it should be). It takes close to 4ms per frame on my Intel
MacBook Air (on a superflat world on low render distance that's 8 times higher than world rendering).

If GUI rendering were put on a scale of optimisability, it would probably be pretty high because
most GUI elements don't change from frame to frame.

The main source of slow downs is that no mesh buffers are being reused at all. A new
buffer is created for each mesh each frame.

### Avoid updating uniforms unless they have changed

This made almost no difference to CPU or GPU time, but it's good practice.

### Combine meshes that use the same array texture where possible

The only measurement that is affected by this improvement is `gui.encode`. The differences in other
measurements are just due to external factors. Overall it seems to be a pretty fair comparison: some
measurements that should be constant are slightly more and some are slightly less by they seem to be
relatively consistent.

This improvement gave a 2.36x reduction in encode time which is pretty great.

This improvement isn't foolproof, it should be conservative to always retain ordering when required,
but it doesn't seem to always combine meshes when they can be combined. This can be worked around by
refactoring mesh generation to group by array texture when possible. I had to do this with
`GUIList`'s row background generation (by putting all the backgrounds first) and it worked a charm.
I don't quite know why it doesn't manage to combine the meshes in these cases, the text is probably
overlapping in the transparent parts or something. This could be investigated by adding a mesh
bounding box rendering feature to the GUI.

```
waitForRenderPassDescriptor 8.21971ms
updateCamera                0.01754ms
createRenderCommandEncoder  0.07330ms
world                       0.53691ms
entities                    0.06140ms
gui                         3.30120ms
  updateUniforms 0.03868ms
  updateContent  0.52186ms
  createMeshes   1.07536ms
  encode         1.63316ms
commitToGPU                 0.07620ms
```
Figure 1: *before*

```
=== Start profiler summary ===
waitForRenderPassDescriptor 13.06693ms
updateCamera                0.02092ms
createRenderCommandEncoder  0.07628ms
world                       0.60788ms
entities                    0.03953ms
gui                         2.37221ms
  updateUniforms 0.03809ms
  updateContent  0.64521ms
  createMeshes   0.95568ms
  encode         0.69374ms
commitToGPU                 0.05965ms
===  End profiler summary  ===
```
Figure 2: *after*

### Reuse vertex buffers

This was implemented simply by keeping an array of previous meshes and then when rendering a mesh,
use the previous mesh at the same index if one exists. This means that in general a mesh will mostly
reuse itself meaning that the size should be similar and the creation of a new vertex buffer can be
avoided. This also means that as long as there aren't more meshes than there were in a previous
frame (true most of the time), no uniforms buffers need to be created.

Vertex buffers are created with enough head room to fit 20 more quads which reduced the number of
new buffers created by my repeatable GUI test from 91 to 17 (the minimum possible being 10 which is
the number of meshes the GUI uses with chat open, the number of items in the hotbar of the account I
was using and the debug overlay activated).

This cut down the `gui.encode` measurement by 2.5x (for a total 6x improvement so far).

```
=== Start profiler summary ===
waitForRenderPassDescriptor 13.51036ms
updateCamera                0.01717ms
createRenderCommandEncoder  0.07296ms
world                       0.57931ms
entities                    0.04536ms
gui                         2.22940ms
  updateUniforms 0.04108ms
  updateContent  0.81972ms
  createMeshes   1.07331ms
  encode         0.27231ms
commitToGPU                 0.06338ms
===  End profiler summary  ===
```
Figure 3: *after*


