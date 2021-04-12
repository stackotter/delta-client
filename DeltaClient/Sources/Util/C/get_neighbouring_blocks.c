//
//  get_neighbouring_blocks.c
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/4/21.
//

#include "get_neighbouring_blocks.h"

enum FaceDirection {Up, Down, North, South, East, West};
enum ChunkNumber {CurrentChunk, NorthChunk, EastChunk, SouthChunk, WestChunk};

const int CHUNK_WIDTH = 16;
const int CHUNK_DEPTH = 16;
const int CHUNK_HEIGHT = 256;

const int BLOCKS_PER_LAYER = CHUNK_WIDTH * CHUNK_DEPTH;
const int BLOCKS_PER_CHUNK = BLOCKS_PER_LAYER * CHUNK_HEIGHT;

struct NeighbouringBlocks get_neighbouring_blocks(int index) {
  int current_row = index / CHUNK_WIDTH;
  int current_layer = index / BLOCKS_PER_LAYER;
  
  int west_block_index = index - 1;
  int east_block_index = index + 1;
  
  int north_block_index = index - CHUNK_WIDTH;
  int south_block_index = index + CHUNK_WIDTH;
  
  int down_block_index = index - BLOCKS_PER_LAYER;
  int up_block_index = index + BLOCKS_PER_LAYER;
  
  struct NeighbouringBlocks neighbouring_blocks;
  
  // get west neighbour
  struct NeighbouringBlock west_neighbour;
  if (west_block_index >= current_row * CHUNK_WIDTH) {
    west_neighbour.index = west_block_index;
    west_neighbour.chunk_num = CurrentChunk;
  } else {
    west_neighbour.index = west_block_index + CHUNK_WIDTH;
    west_neighbour.chunk_num = WestChunk;
  }
  neighbouring_blocks.neighbours[West] = west_neighbour;
  
  // get east neighbour
  struct NeighbouringBlock east_neighbour;
  if (east_block_index < (current_row + 1) * CHUNK_WIDTH) {
    east_neighbour.index = east_block_index;
    east_neighbour.chunk_num = CurrentChunk;
  } else {
    east_neighbour.index = east_block_index - CHUNK_WIDTH;
    east_neighbour.chunk_num = EastChunk;
  }
  neighbouring_blocks.neighbours[East] = east_neighbour;
  
  // get north neighbour
  struct NeighbouringBlock north_neighbour;
  if (north_block_index >= current_layer * BLOCKS_PER_LAYER) {
    north_neighbour.index = north_block_index;
    north_neighbour.chunk_num = CurrentChunk;
  } else {
    north_neighbour.index = north_block_index + BLOCKS_PER_LAYER;
    north_neighbour.chunk_num = NorthChunk;
  }
  neighbouring_blocks.neighbours[North] = north_neighbour;
  
  // get south neighbour
  struct NeighbouringBlock south_neighbour;
  if (south_block_index < (current_layer + 1) * 256) {
    south_neighbour.index = south_block_index;
    south_neighbour.chunk_num = CurrentChunk;
  } else {
    south_neighbour.index = south_block_index - BLOCKS_PER_LAYER;
    south_neighbour.chunk_num = SouthChunk;
  }
  neighbouring_blocks.neighbours[South] = south_neighbour;
  
  // get neighbour below
  struct NeighbouringBlock down_neighbour;
  if (down_block_index >= 0) {
    down_neighbour.index = down_block_index;
    down_neighbour.chunk_num = CurrentChunk;
  } else {
    down_neighbour.chunk_num = -1;
  }
  neighbouring_blocks.neighbours[Down] = down_neighbour;
  
  // get neighbour above
  struct NeighbouringBlock up_neighbour;
  if (up_block_index <= BLOCKS_PER_CHUNK) {
    up_neighbour.index = up_block_index;
    up_neighbour.chunk_num = CurrentChunk;
  } else {
    up_neighbour.chunk_num = -1;
  }
  neighbouring_blocks.neighbours[Up] = up_neighbour;
  
  return neighbouring_blocks;
}
