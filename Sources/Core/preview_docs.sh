TARGET="DeltaCore"

mkdir -p .build/symbol-graphs
swift build --target $TARGET \
  -Xswiftc -emit-symbol-graph \
  -Xswiftc -emit-symbol-graph-dir -Xswiftc .build/symbol-graphs

mkdir .build/swift-docc-symbol-graphs
mv .build/symbol-graphs/$TARGET* .build/swift-docc-symbol-graphs

docc preview \
  --fallback-display-name $TARGET \
  --fallback-bundle-identifier dev.stackotter.$TARGET \
  --fallback-bundle-version 0.1.0 \
  --additional-symbol-graph-dir .build/swift-docc-symbol-graphs
