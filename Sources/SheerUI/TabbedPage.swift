import SwiftUI

public struct TabbedPage<Tab: Hashable, Content: View>: View {
    let tabs: [(value: Tab, title: Text)]
    @Binding var selection: Tab
    @ViewBuilder let content: (Tab) -> Content
    @State private var visited: Set<Tab> = []
    @State private var opened: Set<Tab> = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(tabs: [(value: Tab, title: Text)], selection: Binding<Tab>, @ViewBuilder content: @escaping (Tab) -> Content) {
        self.tabs = tabs
        _selection = selection
        self.content = content
    }

    public init(tabs: [(value: Tab, title: LocalizedStringKey)], selection: Binding<Tab>, @ViewBuilder content: @escaping (Tab) -> Content) {
        self.init(tabs: tabs.map { ($0.value, Text($0.title)) }, selection: selection, content: content)
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(tabs, id: \.value) { tab in
                let chosen = tab.value == selection
                if chosen || visited.contains(tab.value) {
                    content(tab.value)
                        .environment(\.pageTitle, tab.title)
                        .environment(
                            \.pageAccessory,
                            tabs.count > 1 ? AnyView(CapsuleTabs(options: tabs, selection: .constant(tab.value)).hidden()) : nil
                        )
                        .onPreferenceChange(PageShowsDetail.self) { showsDetail in
                            if showsDetail { opened.insert(tab.value) } else { opened.remove(tab.value) }
                        }
                        .opacity(chosen ? 1 : 0)
                        .disabled(!chosen)
                        .allowsHitTesting(chosen)
                        .accessibilityHidden(!chosen)
                        .zIndex(chosen ? 1 : 0)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if tabs.count > 1, !opened.contains(selection) {
                CapsuleTabs(options: tabs, selection: $selection)
                    .padding(.leading, Metrics.pageInset)
                    .padding(.top, Metrics.pageTop + (Metrics.headerHeight - Metrics.control) / 2)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: selection)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: opened)
        .onAppear { visited.insert(selection) }
        .onChange(of: selection) { _, tab in visited.insert(tab) }
    }
}
