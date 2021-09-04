# Contributing

Delta Client is completely open source and I welcome contributions of all kinds. If you're interested in contributing, I've provided a list of features, fixes and general improvements that I'd love other people to help out with (I don't have the time for all the interesting features I want to implement). Some of the tasks don't even require Swift! You can also checkout the [project boards](https://github.com/stackotter/delta-client/projects) on GitHub for some more tasks. But before you get too excited, make sure that you've read the contributing guidelines, and make sure that your contributions follow them. If you need any help with a contribution, feel free to join the [Discord](https://discord.gg/xZPyDbmR6k) and chat :)

## Guidelines

If your contributions follow these guidelines, they'll be much more likely to get accepted first try :thumbsup:

1. Make sure your indent size matches the repository (in the case of delta-core and delta-client that's 2 spaces)
2. Be conscious of copyright and don't include any files distributed by Mojang in these repositories
3. Be concise, only make changes that are required to achieve your end goal. The smaller your pull request, the faster I'll get around to reviewing it
4. Use `log` for logging
5. If in doubt, consult [Google's Swift style guide](https://google.github.io/swift/#function-declarations) because that's the one I try to follow
6. Add documentation comments for any methods or properties you create unless their usage is completely self-evident. Be sure to also document potentially unexpected side-effects or non-obvious requirements of methods. (I'm not gonna be too strict about documentation at the moment so don't worry too much about following this guideline perfectly).

## Xcode (don't worry if you don't have enough space)

If you want to make a contribution but you don't have space for Xcode (it's 30gb), don't stress! I've made a version of Xcode that is only 5gb (by deleting parts that Delta Client doesn't require). The caveat is that I can't publicly distribute it because I don't think Apple would like that, but message me on Discord and I'll add you to the private GitHub repo that I store it in so that you can download it :)

**Note**: the minified version of Xcode I've made doesn't include iOS or tvOS support, so you'll probably just want to find the space to install actual Xcode if you need to do stuff with iOS or tvOS.

## Getting setup

### Delta Client

If you only need to change code in Delta Client, just fork Delta Client and start coding.

### Delta Core

If you only need to make changes to Delta Core, follow these steps;

1. Fork Delta Core
2. Clone Delta Client and your fork of Delta Core
3. Open Delta Client in Xcode
4. Make sure that the root folder of your clone of Delta Core is called `delta-core` (it should be already) and then drag the `delta-core` folder from Finder into Xcode's file navigator
5. When you build Delta Client, it will now use your local copy of Delta Core and you will be able to edit Delta Core from within the Delta Client workspace

### Both Delta Client and Delta Core

It simplifies the pull request process if you only work on one repository at a time, but if it's absolutely necessary for changes to be made in both Delta Client and Delta Core such as when making API changes, these are the steps to follow;

1. Fork Delta Client and clone that
2. Follow the steps listed in the Delta Core section above, making sure to clone your Delta Client fork in step 2
3. Update your Delta Client fork's dependencies to point to your fork of Delta Core
   1. Click on the `DeltaClient` in the file navigator (the root item)
   2. Select `DeltaClient` in the drop down in the top left of the file editor
   3. Under the `Swift Packages` tab remove the delta-core dependency and then add your own (choosing branch: main as the rule when prompted)

### Website

The [website](https://delta.stackotter.dev) is built with svelte. Just follow these steps to get started;

1. Fork and clone [delta-website](https://github.com/stackotter/delta-website) 
2. Run `npm i`
3. Run `npm run dev` to start a development server. Whenever you save changes to a file, the page will almost instantly reload with the changes, and most of the time it'll retain its state too (pretty cool)

## Contribution ideas

### Delta Client and Delta Core

- **First launch loading screen**: Currently the messages shown while the client is downloading necessary assets on the first launch aren't very descriptive. It'd also be great if the client could show a progress bar for certain tasks such as downloading and unzipping the client jar. And the loading system could just do with an all around clean up probably.
- **First launch speed**: For some reason unzipping the client jar takes a ridiculous amount of time, this could be a somewhat straightforward first contribution (just make a benchmark, try out a few different swift zip libraries, and see which is fastest).
- **Caching**: At the moment the client caches the block model palette because it's otherwise quite slow to load. The loading time of the client could probably be halved if we also cached the block registry (the client currently has it stored as json exactly how it was downloaded from pixlyzer). Caching is also currently a bit tedious to implement and there's a library called [sticky-encoding](https://github.com/stickytools/sticky-encoding) that caught my eye. It allows `Codable` structs to be serialized into a supposedly fast binary format, but I don't quite believe that it can be fast cause `Codable` seems convenient but slow. If it's any slower than protobuf we won't use it because startup time is one of Delta Client's priorities.
- **iOS support**: Due to the fact that the client uses SwiftUI, almost the entire client could be ported to iOS almost effortlessly. There are just a few things such as file storage, input, and the way the renderer is integrated into SwiftUI that would need iOS specific implementations.
- **Themable UI**: Having a themable UI is a feature that some users want, and with SwiftUI this could be sort of annoying to make (theming would be quite limited to what parameters we link to a theming system). One idea I've had for making a more themable UI is to use WebViews along with html/css (not too far from what Electron apps do). This would mean loading a theme would be as simple as including a CSS file. The WebView-based UI would most likely be offered as an alternative to the SwiftUI UI, because WebViews would only really make sense on desktop (for example, on tvOS there are a lot of constraints designs should follow due to the controller, and SwiftUI will automatically restyle our SwiftUI UI to fit right in).
- **Tests**: We're really getting the fun stuff now. At the moment Delta Client and Delta Core don't contain any tests, and they're getting to the size were tests would probably help in detecting performance regressions and such. When I started Delta Client I had no experience with Swift so I just ignored tests, and now I still have none, so it'd be extremely appreciated if someone with knowledge of how tests work could setup someone basic tests for Delta Client and/or Delta Core

### Website 

- Media queries: the site uses CSS media queries to make the design work on all sorts of screen sizes, but I threw them together very quickly so the website's design is a bit odd on certain screen sizes. I'd love it if someone could go through and redo the media queries again (keeping the design the same on desktop and pretty similar to how it is on mobile)