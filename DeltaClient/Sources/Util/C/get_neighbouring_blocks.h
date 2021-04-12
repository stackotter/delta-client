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
  int chunk_num;
  int index;
};

struct NeighbouringBlocks {
  struct NeighbouringBlock neighbours[6];
};

struct NeighbouringBlocks get_neighbouring_blocks(int index);

#endif /* get_neighbouring_blocks_h */
