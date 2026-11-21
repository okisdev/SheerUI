# Changelog

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
