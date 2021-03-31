//
//  chunkunpack.h
//  DeltaClient
//
//  Created by Rohan van Klinken on 1/3/21.
//

#ifndef chunkunpack_h
#define chunkunpack_h

void unpack_chunk(unsigned long long longs[], int num_longs, int bitsPerBlock, unsigned short * blocks);

#endif /* chunkunpack_h */
