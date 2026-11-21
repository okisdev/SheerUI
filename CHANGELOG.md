# Changelog

## 0.1.2

- every component takes its accent from the environment tint, so an app picks one with `.tint(_:)` and gets the system accent when it sets none
- add `TabbedPage` for a page of several views: each view is built on first choice and kept, the capsule tabs are drawn once above them and step aside while a view shows a drilled detail
- add `MenuBarLabel`, `MenuBarPanel` and `MenuBarSection` for status items and their popovers
- add data display: `ChartPalette`, `Figures` and `Figure`, `SampleChart` (stacked or mirrored bars over time with a hover tooltip), `Meter`, `CapacityBar` with `CapacityLegend`, and `ShareBar`
- capsule tabs respect Reduce Motion
- `Artwork.image(_:fallback:)` shows a picture by address, with the fallback while it loads and when it cannot
- `LogView` takes a `highlight` closure that styles a line's message, such as JSON tokens

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
