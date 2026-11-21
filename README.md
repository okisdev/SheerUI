# SheerUI

SheerUI is a component library for quiet, dense desktop apps: a translucent sidebar, the selected page on a bright sheet, headers written into the page instead of toolbars, grouped rows, round and capsule controls, and color only where it means something. It knows nothing about the products that use it.

The Swift package for macOS lives at the repository root. Libraries for other platforms, such as TypeScript, will live under `packages/` and share the same design.

## Install

Add the package in Xcode or in `Package.swift`:

```swift
.package(url: "https://github.com/okisdev/SheerUI", from: "0.1.0")
```

Then depend on the `SheerUI` product. SheerUI requires macOS 15 or later. An app that also targets iOS depends on it for macOS only:

```swift
.product(name: "SheerUI", package: "SheerUI", condition: .when(platforms: [.macOS]))
```

## Components

| Area | Components |
| --- | --- |
| Window | `windowChrome()`, `windowChromeBackground()`, `sheetSurface()`, `SidebarRow`, `SidebarRowLabel` |
| Pages | `Page`, `DrillPage`, `ListPage`, `PageHeader`, `pageCommands(_:)`, `tabAccessory(_:_:)` |
| Lists | `GroupedList`, `ListGroup`, `ListRow`, `DisclosureRow`, `StateDot`, `EmptyLine` |
| Controls | `CircleButtonStyle`, `CapsuleButtonStyle`, `CapsuleTabs`, `CapsuleSearchField`, `ActionCapsule`, `DestructiveButton` |
| Menus | `PopUpMenu`, `CircleMenu`, `MenuCapsule`, `MenuPicker` |
| Forms and sheets | `CardsFormStyle` (`.formStyle(.cards)`), `FormSheet`, `FieldRow`, `InfoRow`, `KeyValueTable`, `SettingsNotice`, `SettingsSliderRow`, `ViewerSheet` |
| States | `EmptyState`, `LoadingState`, `PlaceholderRows`, `FormPlaceholder`, `DotMatrix`, `ProgressLine`, `Toasts`, `Clipboard` |
| Content | `FileBrowser`, `LogView`, `Artwork`, `ArtworkView` |

Metrics, grounds and text roles are in `Sources/SheerUI/Tokens.swift`.

## Text and localization

Every title a caller passes is a `Text`, so it resolves in the caller's own bundle. Each component also takes a `LocalizedStringKey`, which resolves in the main bundle. The words SheerUI draws itself (Cancel, Back, Search, and the file browser's commands) come from its own string catalog in English, German, Spanish, French, Italian, Japanese, Korean, Brazilian Portuguese, Russian, and Simplified and Traditional Chinese.

## Development

```sh
swift build
swift test
xcrun swift-format lint --strict --recursive Sources Tests
```

## License

MIT
