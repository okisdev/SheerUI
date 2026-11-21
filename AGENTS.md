# SheerUI

A public, product agnostic component library; README.md is the catalog for people.

## Commands

- `swift build && swift test`: builds the macOS package and runs its tests; run both before shipping.
- `xcrun swift-format lint --strict --recursive Sources Tests`: passes before shipping, with the repository's `.swift-format`.

## Rules

- Never name a product, its paths, or its data in this repository, because the library is public and serves every product alike.
- A title a caller passes is a `Text`, with a `LocalizedStringKey` overload, because a `LocalizedStringKey` alone resolves in the main bundle and a caller with its own bundle could not localize it.
- A word SheerUI draws itself is `String(localized:bundle: .module)` or `Text(_:bundle: .module)` and has every language of `Sources/SheerUI/Resources/Localizable.xcstrings`, because a plain literal resolves in the app's bundle and shows English.
- A control that opens a menu is built on `PopUpMenu`, never a SwiftUI `Menu` with `.menuStyle(.button)` and a drawn label, because that combination does not open on click on macOS 27.
- The Swift package stays at the repository root and every other platform gets its own folder under `packages/`, because Swift Package Manager reads `Package.swift` only from the root.
- Version tags are plain semantic versions (`0.1.0`) for the Swift package; a package under `packages/` tags as `<name>@<version>`.
