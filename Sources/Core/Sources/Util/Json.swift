//
// Created by infrandomness on 22/06/22.
//

import Foundation

#if os(macOS)
  import ZippyJSON
  public typealias CustomJSONDecoder = ZippyJSONDecoder
#else
  public typealias CustomJSONDecoder = JSONDecoder
#endif
