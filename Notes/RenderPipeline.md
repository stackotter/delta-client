# Render pipeline optimisation

The CPU usage of the render pipeline is currently bottlenecking fps much more than the actual GPU usage. This document will contain my findings as I try to optimise the CPU part of the render pipeline.

All measurements of pipeline performance will be measured at -312 140 -216 with yaw 0 and pitch 90 (looking straight down) in seed -6243685378508790499 with render distance 5. It will always be measured in full screen on my laptop's screen not my monitor's.

## Initial measurements

- WorldRenderer.draw: ~25ms

Just did a bunch of cleanup and now it's a bunch faster somehow;

- WorldRenderer.draw: ~7ms

I don't quite believe that it sped up that much so i probably measured it incorrectly
