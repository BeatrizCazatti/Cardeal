import SwiftUI

/// Um período fechado de sete dias, sempre alinhado ao início da semana.
struct WeekRange: Equatable {
    let start: Date
    let end: Date

    init(start: Date, calendar: Calendar = .dashboard) {
        let day = calendar.startOfDay(for: start)
        let interval = calendar.dateInterval(of: .weekOfYear, for: day)
        self.start = interval?.start ?? day
        self.end = calendar.date(byAdding: .day, value: 6, to: self.start) ?? self.start
    }
}

struct WeekRangePicker: View {
    @Binding var selection: WeekRange
    let onSelection: (() -> Void)?

    @State private var displayedMonth: Date
    private let calendar = Calendar.dashboard

    init(selection: Binding<WeekRange>, onSelection: (() -> Void)? = nil) {
        self._selection = selection
        self.onSelection = onSelection
        self._displayedMonth = State(initialValue: Self.month(containing: selection.wrappedValue.start))
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Selecione um período")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 46)
                .padding(.bottom, 38)

            HStack {
                Text(monthTitle)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Mês anterior", systemImage: "chevron.left") { changeMonth(by: -1) }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .frame(width: 36, height: 36)
                Button("Próximo mês", systemImage: "chevron.right") { changeMonth(by: 1) }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .frame(width: 36, height: 36)
            }
            .foregroundStyle(.blue)
            .padding(.horizontal, 46)
            .padding(.bottom, 12)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.secondary)
                        .frame(height: 50)
                }

                ForEach(monthDays) { day in
                    dayCell(day)
                }
            }
            .padding(.horizontal, 42)
            .padding(.bottom, 36)
        }
        .frame(width: 482)
        .padding(.vertical, 40)
        .background(pickerBackground)
    }
}

private extension WeekRangePicker {
    static func month(containing date: Date) -> Date {
        Calendar.dashboard.date(from: Calendar.dashboard.dateComponents([.year, .month], from: date)) ?? date
    }

    var monthTitle: String {
        displayedMonth.formatted(.dateTime.locale(Locale(identifier: "pt_BR")).month(.wide).year())
            .capitalized
    }

    var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    var monthDays: [CalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstGridDay = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start)?.start ?? monthInterval.start
        let lastDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end) ?? monthInterval.end
        let lastGridDay = calendar.date(byAdding: .day, value: 6, to: calendar.dateInterval(of: .weekOfYear, for: lastDay)?.start ?? lastDay) ?? lastDay

        return stride(from: 0, through: calendar.dateComponents([.day], from: firstGridDay, to: lastGridDay).day ?? 0, by: 1).compactMap {
            calendar.date(byAdding: .day, value: $0, to: firstGridDay).map { CalendarDay(date: $0, belongsToDisplayedMonth: calendar.isDate($0, equalTo: displayedMonth, toGranularity: .month)) }
        }
    }

    func dayCell(_ day: CalendarDay) -> some View {
        let isSelected = day.date >= selection.start && day.date <= selection.end
        let isStart = calendar.isDate(day.date, inSameDayAs: selection.start)
        let isEnd = calendar.isDate(day.date, inSameDayAs: selection.end)

        return Button {
            selection = WeekRange(start: day.date, calendar: calendar)
            onSelection?()
        } label: {
            ZStack {
                if isSelected {
                    Rectangle().fill(Color.blue.opacity(0.12)).frame(height: 42)
                }
                if isStart || isEnd {
                    Circle().fill(.blue).frame(width: 42, height: 42)
                }
                Text(day.date.formatted(.dateTime.day()))
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(isStart || isEnd ? .white : (day.belongsToDisplayedMonth ? .primary : .secondary.opacity(0.55)))
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.date.formatted(date: .long, time: .omitted))
        .accessibilityHint("Seleciona a semana desta data")
    }

    func changeMonth(by value: Int) {
        guard let month = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        withAnimation(.easeInOut(duration: 0.2)) { displayedMonth = month }
    }

    var pickerBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(nsColor: .windowBackgroundColor))
            .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.gray.opacity(0.28), lineWidth: 1) }
            .shadow(color: .black.opacity(0.13), radius: 18, y: 8)
    }
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
