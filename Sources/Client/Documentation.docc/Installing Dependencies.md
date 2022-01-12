# Installing Dependencies

Before working on Delta Client or plugins you first need a few dependencies.

## Overview

The essential dependencies are as follow:

- [Xcode](https://developer.apple.com/xcode/) 13.2 or greater
- The latest version of [swift-bundler](https://github.com/stackotter/swift-bundler)

 
If you are developing a plugin you will also need to install [jq](https://stedolan.github.io/jq/).

## Xcode

[Xcode](https://developer.apple.com/xcode/) is Apple's integrated development environment for Swift. You can use any code editor you want to work on Delta Client and plugins, however, installing Xcode is currently the only way to get access to certain essential frameworks such as [SwiftUI](https://developer.apple.com/xcode/swiftui/) and [Metal](https://developer.apple.com/metal/).

Xcode can be installed from either the Mac App Store, [xcodereleases](https://xcodereleases.com), or the [Apple website](https://developer.apple.com/xcode/).

> NOTE: You may need to clear up some space before installing Xcode, because a full installation of Xcode is around 30gb (as of the latest release).

## Swift Bundler

Swift Bundler is the custom build system used for building and packaging Delta Client. It was created to allow Delta Client to just be a Swift package which allows for easy command-line and cloud builds.

To install Swift Bundler, follow the installation instructions in [its Readme](https://github.com/stackotter/swift-bundler/blob/main/README.md).

## jq

[jq](https://stedolan.github.io/jq/) is a command-line tool for processing JSON. It is used in some of the build scripts for plugins to access configuration.

To install jq, first install [brew](https://brew.sh) and then run:

```sh
brew install jq
```
