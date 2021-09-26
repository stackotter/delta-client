# Contributing

Delta Client is completely open source and I welcome contributions of all kinds. If you're interested in contributing, I've provided a list of features, fixes and general improvements that I'd love other people to help out with (I don't have the time for all the interesting features I want to implement). Some of the tasks don't even require Swift! You can also checkout the [project boards](https://github.com/stackotter/delta-client/projects) on GitHub for some more tasks. But before you get too excited, make sure that you've read the contributing guidelines, and make sure that your contributions follow them. If you need any help with a contribution, feel free to join the [Discord](https://discord.gg/xZPyDbmR6k) and chat :)

## Guidelines

If your contributions follow these guidelines, they'll be much more likely to get accepted first try :thumbsup:

1. Make sure your indent size matches the repository (in the case of delta-core and delta-client that's 2 spaces)
2. Be conscious of copyright and don't include any files distributed by Mojang in these repositories
3. Be concise, only make changes that are required to achieve your end goal. The smaller your pull request, the faster I'll get around to reviewing it
4. Remove file headers from all files you create, I've decided they're not necessary and I'll be removing them all soon. `swift-bundler` will soon support removing them automatically
5. Use `log` for logging (not just print statements everywhere)
6. If in doubt, consult [Google's Swift style guide](https://google.github.io/swift/#function-declarations) because that's the one I try to follow
7. Add documentation comments for any methods or properties you create unless their usage is completely self-evident. Be sure to also document potentially unexpected side-effects or non-obvious requirements of methods. (I'm not gonna be too strict about documentation at the moment so don't worry too much about following this guideline perfectly).

## Getting setup

### Delta Client

[Delta Client](https://github.com/stackotter/delta-client) uses the `swift-bundler` build system. The first step is to install that on your machine;

```sh
git clone https://github.com/stackotter/swift-bundler
cd swift-bundler
sh ./build_and_install.sh
```

You can use any ide you want to work on Delta Client (vscode and xcode are the best supported), but you'll need Xcode installed anyway because sadly that's currently the only way to get Metal and SwiftUI build support.

Next, fork Delta Client and/or Delta Core depending on where you need to make changes.

```sh
# Clone your fork of Delta Client instead if you made one
git clone https://github.com/stackotter/delta-client
cd delta-client
# Clone your fork of Delta Core instead if you made one
git clone https://github.com/stackotter/delta-core
```

To run Delta Client, you can now run `swift bundler run` in the root directory of Delta Client. See the [swift-bundler repo](https://github.com/stackotter/swift-bundler) for more commands and options.

If you are using Xcode as your IDE run `swift bundler generate-xcodeproj` and open then open the generated `DeltaClient.xcodeproj` file. You'll want to generate the xcodeproj again each time you pull just in case.

### Website

The [website](https://delta.stackotter.dev) is built with svelte. Just follow these steps to get started;

1. Fork and clone [delta-website](https://github.com/stackotter/delta-website) 
2. Run `npm i`
3. Run `npm run dev` to start a development server. Whenever you save changes to a file, the page will almost instantly reload with the changes, and most of the time it'll retain its state too (pretty cool)

## Contribution ideas

### Delta Client and Delta Core

- **First launch loading screen**: Currently the messages shown while the client is downloading necessary assets on the first launch aren't very descriptive. It'd also be great if the client could show a progress bar for certain tasks such as downloading and unzipping the client jar. And the loading system could just do with an all around clean up probably.
- **First launch speed**: For some reason unzipping the client jar takes a ridiculous amount of time, this could be a somewhat straightforward first contribution (just make a benchmark, try out a few different swift zip libraries, and see which is fastest).
- **Caching**: At the moment the client caches the block model palette because it's otherwise quite slow to load. The loading time of the client could probably be halved if we also cached the block registry (the client currently has it stored as json exactly how it was downloaded from pixlyzer). Caching is also currently a bit tedious to implement with Protobufs so if you've got a better idea, feel free to give it a go!
- **iOS support**: Due to the fact that the client uses SwiftUI, almost the entire client could be ported to iOS almost effortlessly. There are just a few things such as file storage, input, and the way the renderer is integrated into SwiftUI that would need iOS specific implementations.
- **Themable UI**: Having a themable UI is a feature that some users want, and with SwiftUI this could be sort of annoying to make (theming would be quite limited to what parameters we link to a theming system). One idea I've had for making a more themable UI is to use WebViews along with html/css (not too far from what Electron apps do). This would mean loading a theme would be as simple as including a CSS file. The WebView-based UI would most likely be offered as an alternative to the SwiftUI UI, because WebViews would only really make sense on desktop (for example, on tvOS there are a lot of constraints designs should follow due to the controller, and SwiftUI will automatically restyle our SwiftUI UI to fit right in).
- **Tests**: We're really getting to the fun stuff now. At the moment Delta Client and Delta Core don't contain any tests, and they're getting to the size were tests would probably help in detecting performance regressions and such. When I started Delta Client I had no experience with Swift so I just ignored tests, and now I still have none, so it'd be extremely appreciated if someone with knowledge of how tests work in Swift packages could setup some basic tests for Delta Client and/or Delta Core.

### Website 

- Media queries: the site uses CSS media queries to make the design work on all sorts of screen sizes, but I threw them together very quickly so the website's design is a bit odd on certain screen sizes. I'd love it if someone could go through and redo the media queries again (keeping the design the same on desktop and pretty similar to how it is on mobile)