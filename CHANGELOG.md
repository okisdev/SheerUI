# Changelog

## 0.1.6

- `MenuBarPanel` sets each section on its own card over the popover's material, 300 points wide, instead of one sheet parted by hairlines
- `MenuBarSection` names its card in the accent color, with column titles or one command in its trailing slot
- add `MenuBarHeadline` for a panel's first card: a ring with the whole percent inside, the thing's name and its reading
- add `MenuBarReadings` for two or three readings side by side over the chart they belong to, each with the dot of its series color
- add `MenuBarRow` for a name and a right aligned value with an optional bar, since `InfoRow` and `LabeledContent` only align inside a form
- add `MenuBarTable` and `MenuBarColumns` for a short table of the apps using a resource, one right aligned column per measure
- add `MenuBarFootnote` for the figures under a chart and `MenuBarCommands` for the panel's last card
- add `MenuBarStack` for two readings stacked in one menu bar line and `MenuBarLevel` for a level as an upright bar with a caption read down its side

## 0.1.5

- `ListGroup` takes its rows' data instead of a run of views, counts itself from that data and builds only the rows on screen, so a list of every process or package no longer resolves every row on every change

## 0.1.4

- add `Artwork.file(_:)` for the icon the system shows for a file, folder or app, read once per path, so a list of apps draws their icons without converting them to image data on every update

## 0.1.3

- add `span` to `SampleChart` for a fixed time window ending at the newest sample, with bars capped at 24 points
- hide an empty `ListRow` meta line and centre the title within the row's minimum height

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
