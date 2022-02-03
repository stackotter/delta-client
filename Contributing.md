# Contributing

Delta Client is completely open source and I welcome contributions of all kinds. If you're interested in contributing, you can checkout the [delta client issues](https://github.com/stackotter/delta-client/issues) and [delta client website issues](https://github.com/stackotter/delta-website) ( on GitHub for some tasks. Some of the tasks don't even require Swift! But before you get too excited, make sure that you've read the contributing guidelines, and make sure that your contributions follow them. If you need any help with a contribution, feel free to join the [Discord](https://discord.gg/xZPyDbmR6k) and chat :)

Note: when you've decided on an issue to work on, please leave a comment on it so that everyone else knows not to work on it.

Another note: all changes should either be made on the dev branch or a branch created from the dev branch (if you like branching workflows).

## Guidelines

If your contributions follow these guidelines, they'll be much more likely to get accepted first try :thumbsup:

1. Make sure your indent size matches the repository (in the case of delta-client that's 2 spaces).
2. Be conscious of copyright and don't include any files distributed by Mojang in these repositories.
3. Be concise, only make changes that are required to achieve your end goal. The smaller your pull request, the faster I'll get around to reviewing it.
7. Add documentation comments for any methods or properties you create unless their usage is completely self-evident. Be sure to also document potentially unexpected side-effects or non-obvious requirements of methods.
4. Remove file headers from all files you create, they're unnecessary. `swift-bundler` will automatically remove them for you whenever you build.
5. Use `log` for logging (not just print statements everywhere).
6. If in doubt, consult [Google's Swift style guide](https://google.github.io/swift/#function-declarations) because that's the one I try to follow.

## Getting setup

### Delta Client

**Important**: Only Xcode 13 is supported, Xcode 12 builds don't work because Delta Client uses new automatic `Codable` conformance and there are some weird discrepancies between Xcode 12's swift compiler and Xcode 13's swift compiler

[Delta Client](https://github.com/stackotter/delta-client) uses the `swift-bundler` build system. The first step is to install that on your machine;

```sh
git clone https://github.com/stackotter/swift-bundler
cd swift-bundler
sh ./build_and_install.sh
```

You can use any ide you want to work on Delta Client (vscode and xcode are the best supported), but you'll need Xcode installed anyway because sadly that's currently the only way to get Metal and SwiftUI build support.

Next, fork Delta Client and then clone it.

```sh
git clone [url of your delta-client fork]
cd delta-client
```

To run Delta Client, you can now run `swift bundler run`. See the [swift-bundler repo](https://github.com/stackotter/swift-bundler) for more commands and options.

If you are using Xcode as your IDE run `swift bundler generate-xcode-support` and then open Package.swift with Xcode (`open Package.swift` should work unless you've changed your default program for opening swift files). **Make sure to choose the `DeltaClient` target in the top bar instead of the `DeltaClient-Package` target.**

**Note: Xcode puts DeltaCore in the dependencies section of the file navigator instead of at its physical location in the directory structure. This is due to the way the plugin system had to be implemented.**

You can now make changes and when you're done, just open a pull request on GitHub.

### Website

The [website](https://delta.stackotter.dev) is built with svelte. Just follow these steps to get started;

1. Fork and clone [delta-website](https://github.com/stackotter/delta-website) 
2. Run `npm i`
3. Run `npm run dev` to start a development server. Whenever you save changes to a file, the page will almost instantly reload with the changes, and most of the time it'll retain its state too (pretty cool)
