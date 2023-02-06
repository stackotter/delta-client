# Chunk preparation optimisation

Chunk mesh preparation is one of the prime areas of focus for optimisation efforts. Fast chunk loading is extremely important for that snappy feeling. There a few ideas for optimising chunk preparation that I have and here they are;

## Initial benchmarks

I have created a swiftpm executable that can download specified chunks from a server and then save them to allow repeated consistent tests. This is what I will be evaluating performance gains with. I have gathered data on the time spent in each of the main high level tasks required when meshing each block and ordered them by which requires more attention (which ones take the longest). Initial measurements were of delta-core commit c9f0d1c6dab773802fd69bedf3675d0255fadf13. The chunk section being prepared is section -20 0 -14 in seed -6243685378508790499.

1. getCullingNeighbours: 0.0178ms, the longest task by far
2. getBlockModels: 0.0026ms, this one is surprising given it's just a quick lookup, perhaps this is why getCullingNeighbours is so slow
3. getNeighbourLightLevels: 0.0025ms
4. adding the block models to the mesh: 0.0010ms

Total time: 102.8528ms

## Improving getCullingNeighbours

getBlockModels was the main issue in this case, accessing the resources of a resource pack was super slow because of the use of a computed property called `vanillaResources` that took a stupidly large amount of time. First I tried changing the block models storage to use an array instead of a dictionary but there was no noticable performance difference. Fixing this issue made getCullingNeighbours 5x faster.

1. getCullingNeighbours: 0.0038ms, still the longest task
2. getNeighbourLightLevels: 0.0026ms
3. adding the block models to the mesh: 0.0011ms
4. getBlockModels: 0.0002ms, that's more like it

New total time: 28.0777ms (3.7x faster than original)

## Improving getNeighbourLightLevels and getCullingNeighbours

The second biggest bottleneck was calculating neighbour indices, lots of branching could be eliminated from this function I think but it would greatly complicate the logic of the function and make it massive. So instead of optimising the function I just calculate neighbour indices once instead of twice and pass them to both functions that require them.

1. getCullingNeighbours: 0.0025ms
2. getNeighbourLightLevels: 0.0016ms
3. getNeighbourIndices: 0.0012ms
4. add block models: 0.0010ms

New total time: 22.8666ms (4.5x faster than original)

## Improving getNeighbourIndices

Reserve capacity was the big winner here. Reserving a capacity of 6 won 0.0007ms (more than 2x faster). I also tried wrapping arithmetic (unchecked), but that didn't seem to make a noticable difference. Probably because the function is mostly bottlenecked by branching and collection operations.

1. getCullingNeighbours: 0.00253ms
2. getNeighbourLightLevels: 0.00160ms
3. getNeighbourIndices: 0.00055ms (more than 2x faster)
4. add block models: 0.00092ms

## Improving getNeighbourLightLevels

I tried reserve capacity for this getting light levels and culling faces too and it made light levels more than 2x faster as well! Not such a big gain for getCullingNeighbours, but still like a 20% reduction.

1. getCullingNeighbours: 0.00208ms
2. add block models: 0.00096ms
3. getNeighbourLightLevels: 0.00084ms
4. getNeighbourIndices: 0.00053ms

New total time: 15.8036 (6.5x faster than original, 1.45x faster than previous total time measurement)

## Improving getNeighbourBlockStates and adding block models

I also added reserve capacity to getNeighbourBlockStates which made getCullingNeighbours 1.6x faster. I then fixed the way texture info was accessed (same issue as getting block models had before). This made adding block models 1.8x faster.

1. getCullingNeighbours: 0.00129ms, 1.6x faster than before
2. getNeighbourLightLevels: 0.00080ms
3. add block models: 0.00051ms, 1.8x faster than before
4. getNeighbourIndices: 0.00049ms

New total time: 11.6262 (8.8x faster than original, 1.35x faster than previous)

## Improving everything

I moved some work from mesh preparation to resource pack loading time, just flattened some information and added a list of cullable and noncullable faces too. This information also makes it easier to detect that a block isn't visible earlier. I also now only do light level lookups for required faces

From now on times will be as total time spent in that task over the course of preparing the whole section because the flow of what tasks are done for each block is more complex now. There will be discrepancies between the sum of the measurements and the 'New total time' because the timer has some overhead.

1. calculate face visibility: 7.65150ms
2. get block models: 1.37812ms
3. get neighbour indices: 1.01480ms
4. add block models: 0.46374ms

New total time: 7.5382ms (13.4x faster than original, 1.54x faster than previous)

## Improving face visibility calculation

I added two ifs to early exit the calculation for most blocks, and use arrays and iteration instead of a dictionary for neighbour indices.

1. get culling neighbours: 4.48527ms
2. get block models: 1.41321ms
3. calculate face visibility: 0.98564ms
4. get neighbour indices: 0.86533ms

New total time: 5.7885ms

## Improving block model getting

I now store block models in an array instead of a dictionary because dictionaries are slow.

1. get culling neighbours: 4.12294ms
2. calculate face visibility: 1.03458ms
3. get neighbour indices: 0.96912ms
4. get block models: 0.87172ms
5. add block models: 0.49894ms

New total time: 4.9672ms

It now takes 8-9 seconds to prepare all chunks within 10 render distance.

## Replacing Set<Direction> with DirectionSet (a bitset-based implementation)

This is just overall a much better data structure for the situation. It also ended up improving the
block model cache loading time by a bit over 20% because the data structure is much better suited to
binary caching (fixed size and just a single integer).

Original total time: 6.03ms (not sure whether my computer was slower or the mesh builder slowly got
slower)

New total time: 3.35ms (1.8x faster than with Set<Direction>)
