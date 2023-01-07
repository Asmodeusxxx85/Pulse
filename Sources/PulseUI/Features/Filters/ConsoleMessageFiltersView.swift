// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse

#if os(iOS) || os(macOS)

struct ConsoleMessageFiltersView: View {
    @ObservedObject var viewModel: ConsoleMessageSearchCriteriaViewModel
    @ObservedObject var sharedCriteriaViewModel: ConsoleSharedSearchCriteriaViewModel

#if os(iOS)
    @State var isGeneralSectionExpanded = true
    @State var isLevelsSectionExpanded = true
    @State var isLabelsSectionExpanded = false

    @Binding var isPresented: Bool

    var body: some View {
        Form { formContents }
            .navigationBarTitle("Filters", displayMode: .inline)
            .navigationBarItems(leading: buttonReset, trailing: buttonDone)
    }

    private var buttonDone: some View {
        Button("Done") { isPresented = false }
    }
#else
    @AppStorage("networkFilterIsParametersExpanded") var isGeneralSectionExpanded = true
    @AppStorage("consoleFiltersIsLevelsSectionExpanded") var isLevelsSectionExpanded = true
    @AppStorage("consoleFiltersIsLabelsExpanded") var isLabelsSectionExpanded = false

    var body: some View {
        ScrollView {
            VStack(spacing: Filters.formSpacing) {
                VStack(spacing: 6) {
                    HStack {
                        Text("FILTERS")
                            .foregroundColor(.secondary)
                        Spacer()
                        buttonReset
                    }
                    Divider()
                }
                .padding(.top, 6)

                formContents
            }.padding(Filters.formPadding)
        }
    }
#endif
}

// MARK: - ConsoleMessageFiltersView (Contents)

extension ConsoleMessageFiltersView {
    @ViewBuilder
    var formContents: some View {
        if #available(iOS 14, *) {
            generalSection
        }
        logLevelsSection
        labelsSection
        ConsoleSharedFiltersView(viewModel: sharedCriteriaViewModel)
    }

    var buttonReset: some View {
        Button("Reset") {
            viewModel.resetAll()
            sharedCriteriaViewModel.resetAll()
        }.disabled(!(viewModel.isButtonResetEnabled || sharedCriteriaViewModel.isButtonResetEnabled))
    }
}

// MARK: - ConsoleMessageFiltersView (Custom Filters)

extension ConsoleMessageFiltersView {
    @available(iOS 14, *)
    var generalSection: some View {
        FiltersSection(
            isExpanded: $isGeneralSectionExpanded,
            header: { generalHeader },
            content: { generalContent },
            isWrapped: false
        )
    }

    private var generalHeader: some View {
        FilterSectionHeader(
            icon: "line.horizontal.3.decrease.circle", title: "General",
            color: .yellow,
            reset: { viewModel.resetFilters() },
            isDefault: viewModel.filters.count == 1 && viewModel.filters[0].isDefault,
            isEnabled: $viewModel.criteria.isFiltersEnabled
        )
    }

#if os(iOS)
    @available(iOS 14, *)
    @ViewBuilder
    private var generalContent: some View {
        ForEach(viewModel.filters) { filter in
            CustomFilterView(filter: filter, onRemove: {
                viewModel.removeFilter(filter)
            }).buttonStyle(.plain)
        }

        Button(action: { viewModel.addFilter() }) {
            HStack {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18))
                Text("Add Filter")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
#else
    @ViewBuilder
    private var generalContent: some View {
        VStack {
            ForEach(viewModel.filters) { filter in
                CustomFilterView(filter: filter, onRemove: {
                    viewModel.removeFilter(filter)
                })
            }
        }
        .padding(.leading, 4)
        .padding(.top, Filters.contentTopInset)

        Button(action: viewModel.addFilter) {
            Image(systemName: "plus.circle")
        }
    }
#endif
}

// MARK: - ConsoleMessageFiltersView (Log Levels)

extension ConsoleMessageFiltersView {
    var logLevelsSection: some View {
        FiltersSection(
            isExpanded: $isLevelsSectionExpanded,
            header: { logLevelsHeader },
            content: { logLevelsContent }
        )
    }

    private var logLevelsHeader: some View {
        FilterSectionHeader(
            icon: "flag", title: "Levels",
            color: .accentColor,
            reset: { viewModel.criteria.logLevels = .default },
            isDefault: false,
            isEnabled: $viewModel.criteria.logLevels.isEnabled
        )
    }

#if os(iOS)
    @ViewBuilder
    private var logLevelsContent: some View {
        HStack(spacing: 16) {
            makeLevelsSection(levels: [.trace, .debug, .info, .notice])
            Divider()
            makeLevelsSection(levels: [.warning, .error, .critical])
        }
        .padding(.bottom, 10)
        .buttonStyle(.plain)

        Button(viewModel.bindingForTogglingAllLevels.wrappedValue ? "Disable All" : "Enable All", action: { viewModel.bindingForTogglingAllLevels.wrappedValue.toggle() })
            .frame(maxWidth: .infinity, alignment: .center)
    }
#else
    private var logLevelsContent: some View {
        HStack(spacing:0) {
            VStack(alignment: .leading, spacing: 6) {
                Toggle("All", isOn: viewModel.bindingForTogglingAllLevels)
                    .accentColor(Color.secondary)
                    .foregroundColor(Color.secondary)
                HStack(spacing: 32) {
                    makeLevelsSection(levels: [.trace, .debug, .info, .notice])
                    makeLevelsSection(levels: [.warning, .error, .critical])
                }.fixedSize()
            }
            Spacer()
        }
    }
#endif

    private func makeLevelsSection(levels: [LoggerStore.Level]) -> some View {
        VStack(alignment: .leading) {
            Spacer()
            ForEach(levels, id: \.self) { level in
                Toggle(level.name.capitalized, isOn: viewModel.binding(forLevel: level))
            }
        }
    }
}

// MARK: - ConsoleMessageFiltersView (Labels)

extension ConsoleMessageFiltersView {
    var labelsSection: some View {
        FiltersSection(
            isExpanded: $isLabelsSectionExpanded,
            header: { labelsHeader },
            content: { labelsContent }
        )
    }

    private var labelsHeader: some View {
        FilterSectionHeader(
            icon: "tag", title: "Labels",
            color: .orange,
            reset: { viewModel.criteria.labels = .default },
            isDefault: viewModel.criteria.labels == .default,
            isEnabled: $viewModel.criteria.labels.isEnabled
        )
    }

#if os(iOS)
    @ViewBuilder
    private var labelsContent: some View {
        let labels = viewModel.allLabels

        if labels.isEmpty {
            Text("No Labels")
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.secondary)
        } else {
            ForEach(labels.prefix(4), id: \.self) { item in
                Toggle(item.capitalized, isOn: viewModel.binding(forLabel: item))
            }
            if labels.count > 4 {
                NavigationLink(destination: ConsoleFiltersLabelsPickerView(viewModel: viewModel)) {
                    Text("View All").foregroundColor(.blue)
                }
            }
        }
    }
#else
    private var labelsContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Toggle("All", isOn: viewModel.bindingForTogglingAllLabels)
                    .accentColor(Color.secondary)
                    .foregroundColor(Color.secondary)
                ForEach(viewModel.allLabels, id: \.self) { item in
                    Toggle(item.capitalized, isOn: viewModel.binding(forLabel: item))
                }
            }
            Spacer()
        }
    }
#endif
}

// MARK: - ConsoleMessageFiltersView (Time Period)

struct ConsoleSharedFiltersView: View {
    @ObservedObject var viewModel: ConsoleSharedSearchCriteriaViewModel

    @State var isTimePeriodSectionExpanded = true

    var body: some View {
        FiltersSection(
            isExpanded: $isTimePeriodSectionExpanded,
            header: { timePeriodHeader },
            content: { timePeriodContent }
        )
    }

    private var timePeriodHeader: some View {
        FilterSectionHeader(
            icon: "calendar", title: "Time Period",
            color: .yellow,
            reset: { viewModel.dates = .default },
            isDefault: viewModel.dates == .default,
            isEnabled: $viewModel.dates.isEnabled
        )
    }

    @ViewBuilder
    private var timePeriodContent: some View {
        Filters.toggle("Latest Session", isOn: $viewModel.dates.isCurrentSessionOnly)

        DateRangePicker(title: "Start Date", date: viewModel.bindingStartDate, isEnabled: $viewModel.dates.isStartDateEnabled)
        DateRangePicker(title: "End Date", date: viewModel.bindingEndDate, isEnabled: $viewModel.dates.isEndDateEnabled)

        HStack(spacing: 16) {
            Button("Recent") { viewModel.dates = .recent }
            Button("Today") { viewModel.dates = .today }
            Spacer()
        }
#if os(iOS)
        .foregroundColor(.accentColor)
        .buttonStyle(.plain)
#elseif os(macOS)
        .padding(.top, 6)
#endif
    }
}

#if DEBUG
struct ConsoleMessageFiltersView_Previews: PreviewProvider {
    static var previews: some View {
#if os(iOS)
        NavigationView {
            ConsoleMessageFiltersView(viewModel: makeMockViewModel(), sharedCriteriaViewModel: .init(store: .mock), isPresented: .constant(true))
        }
#else
        ConsoleMessageFiltersView(viewModel: makeMockViewModel(), sharedCriteriaViewModel: .init(store: .mock))
            .previewLayout(.fixed(width: Filters.preferredWidth - 15, height: 700))
#endif
    }
}

private func makeMockViewModel() -> ConsoleMessageSearchCriteriaViewModel {
    ConsoleMessageSearchCriteriaViewModel(store: .mock)
}
#endif

#endif
