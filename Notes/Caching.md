# Caching

Delta Client uses caching to speed up launches by orders of magnitude. The only thing I cache at the moment are block models because these can take up to 30 seconds to load from the JSON model descriptors with my current method (optimisation attempts are very welcome). To decide which serialization technique to use I created a test project and implemented multiple methods of caching the vanilla block model palette. Below is my interpretation of the [results](#the-numbers);

The first implementation was made using [Flatbuffers](https://github.com/google/flatbuffers) and the other was made using [Protobuf](https://github.com/protocolbuffers/protobuf). In release builds, Flatbuffers was faster at deserialization but slower than serialization. In this use case, deserialization performance is really the only thing we care about. To an end user only release build performance matters but when I'm developing the client, debug build performance greatly affects development speed. Interestingly, in debug builds, the fastest at serialization was Flatbuffers (by quite a bit), and Protobuf was over 3 times faster than Flatbuffers at deserialization.

Now that I understood how Flatbuffers worked, I created an implementation that took a similar approach to my neater Protobuf-base implementation. This new Flatbuffers-based implementation was close enough to Protobuf deserialization speed in debug builds, and the serialization speed was pretty much the same as the original Flatbuffers-based implementation. However, in release builds deserialization speeds were now almost twice as slow as Protobuf and serialization speeds were also the slowest out of all three. Somehow, a change that almost doubled debug build performance significantly slowed down release performance?

I have also previously tried out FastBinaryEncoding but it was quite a bit slower at deserialization (more like 2 seconds in release builds). To its credit, it did manage to encode it all into only 13mb which is pretty impressive. But that matters less than performance to me.

## The verdict

For now I will be using Protobufs for caching because they are nicer to use and their performance is more consistent between debug and release builds. They also have the fastest debug build deserialization speed which is what I really care about right now, and the release build serialization speed wasn't too far off the fastest solution in the grand scheme of things. It also has the fastest release build serialization by far. It's only main downfall is that its debug build serialization speed is dismal. Oh, and It also had the smallest serialized size as an added bonus.

## The numbers

### Flatbuffers (with messy code)

Serialized size: 21601644 bytes

| Operation   | Debug   | Release |
| ----------- | ------- | ------- |
| Serialize   | 17676ms | 2185ms  |
| Deserialize | 23190ms | 368ms   |

### Flatbuffers, cleaner code

Serialized size: 21601644 bytes

| Operation   | Debug   | Release |
| ----------- | ------- | ------- |
| Serialize   | 18661ms | 2601ms  |
| Deserialize | 11760ms | 972ms   |

### Protobuf

Serialized size: 16630993 bytes

| Operation   | Debug   | Release |
| ----------- | ------- | ------- |
| Serialize   | 29436ms | 1219ms  |
| Deserialize | 7490ms  | 551ms   |

## Sticky encoding

[Sticky encoding](https://github.com/stickytools/sticky-encoding) looks quite enticing too so I tried it out. All it requires is adding Codable conformance to the types that need to be serialized. However, I tried it out and it's awfully slow (likely because of limitations of Swift's Codable implementation). In debug builds, both serialize and deserialize took over 50 seconds, and in release builds, serialize took around 14 seconds and deserialize took around 12 seconds. It would be nice to use such a nice solution, but it just can't meet our performance requirements.

## Custom binary serialization

As an experiment, I have started implementing a custom serialization and deserialization API that
uses the Minecraft network protocol's binary format behind the scenes. The initial implementation
with no optimization was quite promisingsd. Given that I've gotten a new laptop and the block model
format has changed a lot, here are the initial results including the new Protobuf and Flatbuffer
times. I've removed `Flatbuffers (with messy code)` because it would've been too much work to
reimplement it for the newer block model palette format, and realistically it's not how I would
implement it in Delta Client because it's just too difficult to maintain. I will also not be testing
debug build performance because that's not important to me anymore now that my laptop can demolish
release builds and run debug builds at a reasonable speed.

| Method & Operation          | Release     |
| --------------------------- | ----------- |
| Flatbuffers serialization   | 470.42799ms |
| Flatbuffers deserialization | 341.62700ms |
| Protobuf serialization      | 342.27204ms |
| Protobuf deserialization    | 181.43606ms |
| Custom serialization        |  54.83699ms |
| Custom deserialization      | 516.13605ms |

The serialization speed is almost 7x faster than Protobuf! The order of magnitude difference between
serialization and deserialization tells me that deserialization should have some pretty easy
optimizations to make.

| Method      | Serialized size |
| ----------- | --------------- |
| Flatbuffers | 21472396 bytes  |
| Protobuf    | 15105882 bytes  |
| Custom      | 22136216 bytes  |

As you can see, the new custom method takes significantly more storage than Protobuf, and a tiny bit
more than Flatbuffers, but this isn't very important to me because it's still only 22ish megabytes
which is completely acceptable for a cache.

### Optimizing custom serialization and deserialization

Using Xcode instruments, I found that the `uvs` property of `BlockModelFace` is the most expensive
part of deserializing the block model palette. Optimizing the float decoding code path (which uses
the fixed length integer decoding code path of `Buffer`) by rearranging code to avoid a call to
`Array.reversed` managed to speed up deserialization by 1.7x (to 294.46900ms).

Because `uvs` is so performance critical, I ended up using some unsafe pointer stuff to avoid
unnecessary copies and byte reordering (caused by MC protocol). I basically just store the Float
array's raw bytes in the cache directly because it's a fixed length array. This increased the
deserialization speed by 2.09x (to 140.65397ms). This change also decreased the serialized size to
20229880 bytes (almost a 9% decrease).

After some further optimization of `Buffer.readInteger(size:endianness:)` I managed to get another
2x deserialization speed improvement (down to 69.15092ms).

I ended up deviating from the Minecraft protocol for integers to allow the use of unsafe pointers to
decode them which gave another 1.23x increase in deserialization speed (down to 56.47790ms).
Essentially I just store integers by copying their raw bytes so that while deserializing I can just
get a pointer into the reader's buffer and cast it to a pointer to an integer.

The next optimization gave a massive improvement by greatly simplifying the serialization and
deserialization process for bitwise copyable types. These types can simply just have their raw bytes
copied into the output and subsequently these bytes can be copied out as that type when
deserializing (using unsafe pointer tricks). This gave another 1.52x improvement in deserialization
speed (down to 37.13298ms). It also gave us our first big improvement in serialization speed of 1.3x
(down to 38.87498ms).

Given that `BlockModelFace` is the most performance critical part of serializing/deserializing the
block model palette and it's technically a fixed amount of data, I decided to try making it a
bitwise copyable type. All this involved was converting the fixed length array of `uvs` to a
tuple-equivalent `struct`. I wasn't able to use a tuple because I needed `uvs` to be `Equatable` and
tuples can't conform to protocols (how silly). After removing all use of indirection from
`BlockModelFace` I was able to improve deserialization times by a factor of around 4.5 (to around
8.6ms).

At this point, a large majority of the serialization time is allocations and appending to arrays. I
tried using `Array.init(unsafeUninitializedCapacity:initializingWith:)` to avoid unnecessary
allocations and append operations, however this ended up making the code slower. Either way, 8ms is
definitely fast enough for this application :sweat_smile:.

### Results

| Method & Operation          | Release     |
| --------------------------- | ----------- |
| Flatbuffers serialization   | 470.42799ms |
| Flatbuffers deserialization | 341.62700ms |
| Protobuf serialization      | 343.40799ms |
| Protobuf deserialization    | 181.43606ms |
| Custom serialization        |  50.11296ms |
| Custom deserialization      |   8.18300ms |

Somewhere along the way I managed to reverse a majority of the progress that I made on serialization
performance, but this is fine for my caching needs because cache generation shouldn't happen very
often at all.

| Method      | Serialized size |
| ----------- | --------------- |
| Flatbuffers | 21472396 bytes  |
| Protobuf    | 15105882 bytes  |
| Custom      | 18839177 bytes  |

I'm not quite sure exactly what optimizations ended up decreasing the serialized so much for the
custom serializer, but I guess it's a pleasant side effect!

### Conclusion

I managed to create a custom binary serialization solution that is 22.2x faster at deserialization
than Protobuf, 6.85x faster at serialization than Protobuf, and way more maintainable than an
equivalent Protobuf-based caching system.

Although I started out with the plan to use the Minecraft network protocol binary format to store
the cache, I quickly realised that the Minecraft network protocol just isn't built for high
performance serialization and deserialization. That's why I ended up just creating an approach that
is essentially a fancy memdump that can handle indirection and complicated data structures.

### Aftermath

I've implemented binary caching for the item model palette, block registry, font palette, and
texture palettes (almost all of the expensive things to load). Overall this amounted to a 4x faster
app launch time which is pretty amazing. The caching code is also way nicer than the old Protobuf
stuff, and any optimization of BinarySerializable will basically have an effect on all of the
expensive start up tasks making it a very appealing target. However, startup time is now 160ms (when
files have been cached in memory by previous launches; it's around 200ms when they haven't been), so
I don't think I need to put in any more work for now :sweat_smile:.
