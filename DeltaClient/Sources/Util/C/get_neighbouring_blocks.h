//
//  get_neighbouring_blocks.h
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/4/21.
//

#ifndef get_neighbouring_blocks_h
#define get_neighbouring_blocks_h

struct NeighbouringBlocks;

struct NeighbouringBlock {
  long chunk_num;
  long index;
};

struct NeighbouringBlocks {
  struct NeighbouringBlock neighbours[6];
};

struct NeighbouringBlocks get_neighbouring_blocks(long index);

#endif /* get_neighbouring_blocks_h */
