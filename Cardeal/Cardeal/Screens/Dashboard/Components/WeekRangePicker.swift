import SwiftUI

/// Um intervalo inclusivo de datas usado pelo navegador de período do dashboard.
struct WeekRange: Equatable {
    let start: Date
    let end: Date

    /// Cria o intervalo padrão de uma semana, de domingo a sábado.
    init(start: Date, calendar: Calendar = .dashboard) {
        let day = calendar.startOfDay(for: start)
        let interval = calendar.dateInterval(of: .weekOfYear, for: day)
        self.start = interval?.start ?? day
        self.end = calendar.date(byAdding: .day, value: 6, to: self.start) ?? self.start
    }

    init(start: Date, end: Date, calendar: Calendar = .dashboard) {
        let normalizedStart = calendar.startOfDay(for: start)
        let normalizedEnd = calendar.startOfDay(for: end)
        self.start = min(normalizedStart, normalizedEnd)
        self.end = max(normalizedStart, normalizedEnd)
    }
}

/// Date-range picker de mês único. A seleção é aplicada imediatamente ao binding.
struct WeekRangePicker: View {
    @Binding var selection: WeekRange

    @State private var displayedMonth: Date
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectionPhase: SelectionPhase

    private let calendar = Calendar.dashboard

    init(selection: Binding<WeekRange>) {
        self._selection = selection
        let initialRange = selection.wrappedValue
        self._displayedMonth = State(initialValue: Self.month(containing: initialRange.start))
        self._startDate = State(initialValue: initialRange.start)
        self._endDate = State(initialValue: initialRange.end)
        self._selectionPhase = State(initialValue: initialRange == WeekRange(start: Date()) ? .defaultWeek : .complete)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Selecione um período")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.Token.interactiveAccent)
                .padding(.bottom, 28)

            HStack {
                Text(monthTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.Token.textPrimary)
                Spacer()
                monthButton(systemImage: "chevron.left", label: "Mês anterior") {
                    changeMonth(by: -1)
                }
                monthButton(systemImage: "chevron.right", label: "Próximo mês") {
                    changeMonth(by: 1)
                }
            }
            .padding(.bottom, 16)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.Token.interactiveAccent.opacity(0.72))
                        .frame(height: 36)
                }

                ForEach(monthDays) { day in
                    CalendarDayButton(
                        day: day,
                        state: selectionState(for: day.date),
                        isToday: calendar.isDateInToday(day.date),
                        action: { select(day.date) }
                    )
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.Token.interactiveAccent.opacity(0.045))
            )
        }
        .padding(24)
        .frame(width: 430)
        .modifier(GlassCardModifier(cornerRadius: 24))
        .onChange(of: selection) { _, range in
            startDate = range.start
            endDate = range.end
        }
    }
}

private extension WeekRangePicker {
    static func month(containing date: Date) -> Date {
        Calendar.dashboard.date(from: Calendar.dashboard.dateComponents([.year, .month], from: date)) ?? date
    }

    var monthTitle: String {
        displayedMonth.formatted(.dateTime.locale(Locale(identifier: "pt_BR")).month(.wide).year())
    }

    var weekdaySymbols: [String] {
        ["D", "S", "T", "Q", "Q", "S", "S"]
    }

    var monthDays: [CalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstGridDay = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start)?.start ?? monthInterval.start
        let lastMonthDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end) ?? monthInterval.end
        let lastGridDay = calendar.date(byAdding: .day, value: 6, to: calendar.dateInterval(of: .weekOfYear, for: lastMonthDay)?.start ?? lastMonthDay) ?? lastMonthDay
        let dayCount = calendar.dateComponents([.day], from: firstGridDay, to: lastGridDay).day ?? 0

        return (0...dayCount).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: firstGridDay) else { return nil }
            return CalendarDay(date: date, belongsToDisplayedMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month))
        }
    }

    func selectionState(for date: Date) -> CalendarDaySelectionState {
        if calendar.isDate(date, inSameDayAs: startDate) {
            return calendar.isDate(startDate, inSameDayAs: endDate) ? .single : .start
        }
        if calendar.isDate(date, inSameDayAs: endDate) { return .end }
        return date > startDate && date < endDate ? .middle : .none
    }

    func select(_ date: Date) {
        let selectedDay = calendar.startOfDay(for: date)
        switch selectionPhase {
        case .complete:
            if calendar.isDate(selectedDay, inSameDayAs: startDate),
               !calendar.isDate(startDate, inSameDayAs: endDate) {
                // Ao remover o início, o fim restante passa a ser o novo início.
                selectSingleDay(endDate)
                return
            }
            if calendar.isDate(selectedDay, inSameDayAs: endDate) {
                // Ao remover o fim, mantém o início aguardando um novo término.
                selectSingleDay(startDate)
                return
            }
            selectSingleDay(selectedDay)
        case .defaultWeek:
            selectSingleDay(selectedDay)
        case .awaitingEnd:
            guard !calendar.isDate(selectedDay, inSameDayAs: startDate) else { return }
            let range = WeekRange(start: startDate, end: selectedDay, calendar: calendar)
            startDate = range.start
            endDate = range.end
            selectionPhase = .complete
            selection = range
        }
    }

    func selectSingleDay(_ date: Date) {
        startDate = date
        endDate = date
        selectionPhase = .awaitingEnd
        selection = WeekRange(start: date, end: date, calendar: calendar)
    }

    func changeMonth(by value: Int) {
        guard let month = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            displayedMonth = month
        }
    }

    func monthButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(width: 32, height: 32)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.Token.interactiveAccent)
        .background(Capsule().fill(Color.Token.interactiveAccent.opacity(0.09)))
        .accessibilityLabel(label)
    }
}

private enum SelectionPhase {
    case defaultWeek
    case awaitingEnd
    case complete
}

private struct CalendarDayButton: View {
    let day: CalendarDay
    let state: CalendarDaySelectionState
    let isToday: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            // A célula sempre tem a mesma área. Os estados visuais ficam em
            // overlays para que círculos, bordas e preenchimentos não mudem
            // o tamanho que o LazyVGrid usa para calcular suas linhas.
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48)
                .overlay { rangeHighlight }
                .overlay { dayIndicator }
                .overlay {
                    Text(day.date.formatted(.dateTime.day()))
                        .font(.body.weight(.medium))
                        .foregroundStyle(foregroundColor)
                        .frame(width: 42, height: 42)
                }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(day.date.formatted(date: .long, time: .omitted))
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("Seleciona esta data para o período")
    }

    @ViewBuilder
    private var rangeHighlight: some View {
        GeometryReader { proxy in
            let halfWidth = proxy.size.width / 2

            switch state {
            case .middle:
                Rectangle()
                    .fill(Color.Token.interactiveAccent.opacity(0.14))
            case .start:
                Rectangle()
                    .fill(Color.Token.interactiveAccent.opacity(0.14))
                    .frame(width: halfWidth)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            case .end:
                Rectangle()
                    .fill(Color.Token.interactiveAccent.opacity(0.14))
                    .frame(width: halfWidth)
                    .frame(maxWidth: .infinity, alignment: .leading)
            case .none, .single:
                Color.clear
            }
        }
        .frame(height: 42)
    }

    @ViewBuilder
    private var dayIndicator: some View {
        ZStack {
            if state == .start || state == .end || state == .single {
                Circle().fill(Color.Token.interactiveAccent)
            } else if isToday {
                Circle().strokeBorder(Color.Token.interactiveAccent, lineWidth: 1.5)
                    .padding(6)
            } else if isHovering {
                Capsule().fill(Color.Token.interactiveAccent.opacity(0.08))
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
            }
        }
        .frame(width: 42, height: 42)
    }

    private var foregroundColor: Color {
        switch state {
        case .start, .end, .single: Color.Token.textOnAccent
        case .none, .middle: day.belongsToDisplayedMonth ? Color.Token.textPrimary : Color.Token.textSecondary.opacity(0.48)
        }
    }

    private var accessibilityValue: String {
        switch state {
        case .none: isToday ? "Hoje" : ""
        case .single: "Início do período"
        case .start: "Início do período"
        case .middle: "No período selecionado"
        case .end: "Fim do período"
        }
    }
}

private enum CalendarDaySelectionState {
    case none, single, start, middle, end
}

private struct CalendarDay: Identifiable {
    let date: Date
    let belongsToDisplayedMonth: Bool
    var id: Date { date }
}

extension Calendar {
    static var dashboard: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "pt_BR")
        calendar.firstWeekday = 1
        calendar.minimumDaysInFirstWeek = 1
        return calendar
    }
}
