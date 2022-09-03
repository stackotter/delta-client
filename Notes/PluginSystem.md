# Plugin System

This document explains how the plugin system is designed and implemented.

## `PluginEnvironment`

The `PluginEnvironment` manages loading, unloading and reloading of plugins. All errors to do with
plugin loading are added to `PluginEnvironment.errors` so that they can be accessed at a later time
(e.g. in the plugin settings view). `PluginEnvironment` also has a method called `addEventBus` which
is used to add all loaded plugins to an event bus as listeners. And a method `handleWillJoinServer`
which should be replaced by an event at a later date when the events part is cleaned up.

## Dynamic linking

All of a plugin's code is contained within a dynamic library (`libPlugin.dylib`). The dynamic
library exposes a function called `buildPlugin` (exported using `@_cdecl("buildPlugin")`) which is
called by the client to get a reference to a `PluginBuilder`. The plugin builder is then used to
create an instance of the plugin and the plugin is installed into the main `PluginEnvironment`
(`DeltaClientApp.pluginEnvironment`).

For typecasting to work correctly in plugins, both the client and the plugin have to be using the
same copies of types. This means that both the client and plugin have to be dynamically linked
against `DeltaCore` (which contains the common code that both plugins and the client have access
to). Due to limitations of Swift Package Manager, this means that `DeltaCore` has to be its own
swift package which has a dynamic library product (see `Sources/Core/Package.swift`). The root swift
package includes `Sources/Core` as a package dependency and the `DeltaClient` target in the root
package has this as a dependency.

To allow use of `DeltaCore` outside of `DeltaClient` (i.e. in plugins), the root package exposes two
products: `DynamicShim` and `StaticShim`. `DynamicShim` re-exports the `DeltaCore` dynamic library
for use in plugins (which must dynamically link to `DeltaCore`). However, not all projects require
`DeltaCore` to be dynamically link (e.g. a simple bot client), therefore the `StaticShim` product
was also exposed which re-exports a statically linked version of `DeltaCore`.

## Loading order

If a feature only supports one plugin using it at a time (such as custom render coordinators), the
client will use the first plugin that uses the feature. Until proper sorting support is added this
can be worked around by unloading all and manually loading the plugins in the order you want (will
not persist across launches).

## Manifest files

A plugin's manifest file is just a JSON file containing basic information about the client such as
its identifier, description and display name. The identifier is used to uniquely identify each
plugin.

## Directory structure

Plugins are just directories with the `deltaplugin` extension. They currently only contain a
`manifest.json` and a `libPlugin.dylib`.
