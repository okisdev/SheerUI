# Changelog

## 0.1.2

- add `SampleChart`, `ChartSeries` and `ChartPalette` for bars over time, stacked or mirrored around zero, with a hover tooltip and an optional fixed span that ends at the newest sample
- add `Figures` and `Figure` for a grid of headline numbers, each optionally a button
- add `Meter`, `ShareBar`, `CapacityBar` and `CapacityLegend` for levels and how a total splits into parts, folding parts beyond eight into one neutral segment
- add menu bar status items (`MenuBarLabel`, `MenuBarStack`, `MenuBarLevel`, `MenuBarBattery`) that keep their width as readings change, and the popover parts (`MenuBarPanel`, `MenuBarSection`, `MenuBarHeadline`, `MenuBarReadings`, `MenuBarRow`, `MenuBarTable`, `MenuBarColumns`, `MenuBarFootnote`, `MenuBarCommands`)
- add `TabbedPage`, which keeps each tab's view once opened and shows `CapsuleTabs` above them
- every menu bar part that takes a title takes a `Text` or a `LocalizedStringKey`; `MenuBarTableRow` also takes a name as is
- `ListGroup` takes its rows' data and builds only the rows on screen
- `Artwork` gains `.file(URL)` for the system icon of a file or app, and `.image(URL, fallback:)` for a picture by address
- `LogView` takes a `highlight:` closure to color a line's message
- `ListRow` drops its meta line when the meta is empty
- selected and prominent controls follow the view's `.tint` instead of the app accent color
- `CapsuleTabs` and `TabbedPage` respect reduce motion
- `SidebarRow` reads its title to VoiceOver
- `windowChrome()` keeps the window controls in place when the title changes or AppKit rebuilds the title bar
- the battery's spoken label in all 11 languages

## 0.1.1

- add `StepRow` and `StepState` for a job the person watches: the state as a mark in a fixed leading column (an empty ring, live dots, a check, an exclamation mark), so titles stay aligned as steps advance, then the elapsed seconds and at most one command for a failed step
- `FormSheet` puts its title on the same 28 point corner as a page header and its footer 28 from the bottom, so every form sheet lines up with the window's pages and viewer sheets
- `FormSheet` takes a `cancel:` title for sheets whose way out is not Cancel, such as Later
- the step states and elapsed seconds in all 11 languages

## 0.1.0

first release of the swift package for macos 15 and later.

- window chrome, sidebar rows and the page sheet
- page header, `Page`, `DrillPage` and `ListPage` with commands sent from nested views
- grouped lists, capsule and circle controls, capsule tabs and search
- menus built on `PopUpMenu` (`CircleMenu`, `MenuCapsule`, `MenuPicker`), which open on click on macos 27
- card forms, form and viewer sheets, empty and loading states, toasts
- file browser, log view and artwork
- caller titles as `Text` with `LocalizedStringKey` overloads; the library's own words in 11 languages
