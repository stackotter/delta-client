//
//  unpack_long_array.c
//  DeltaCore
//
//  Created by Rohan van Klinken on 1/3/21.
//

#include <stdio.h>
#include <time.h>
#include "unpack_long_array.h"

void unpack_long_array(unsigned long long longs[], int num_longs, int bitsPerBlock, unsigned short * blocks) {
  unsigned short state;
  
  int index;
  int offset;
  
  unsigned short mask = (1 << bitsPerBlock) - 1;
  int blockNumber = 0;
  
  // TODO: check number of longs is enough
  
  int blocksPerLong = 64 / bitsPerBlock;
  for (int y = 0; y < 16; y++) {
    for (int z = 0; z < 16; z++) {
      for (int x = 0; x < 16; x++) {
        index = blockNumber / blocksPerLong;
        offset = (blockNumber % blocksPerLong) * bitsPerBlock;
        
        state = (unsigned short)(longs[index] >> offset);
        state &= mask;
        blocks[blockNumber] = state;
        blockNumber++;
      }
    }
  }
}

