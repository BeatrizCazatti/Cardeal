import SwiftUI

// MARK: - Preference Keys
struct TabWidthPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct TextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - ClearSegmentedPicker
public struct ClearSegmentedPicker: View {
    public let tabs: [String]
//    public let icons: [String]?
    public let colors: [Color]?
    public let badges: [Int]?
    public let selectedTextColor: Color
    public let unselectedTextColor: Color
    @Binding var currentTab: Int

    @Environment(\.colorScheme) private var colorScheme
    @State private var tabWidths: [Int: CGFloat] = [:]
    @State private var textWidths: [Int: CGFloat] = [:]
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var feedbackTrigger: Int = 0

    private let horizontalPadding: CGFloat = 20
    private let verticalPadding: CGFloat = 10

    public init(
        tabs: [String],
//        icons: [String]? = nil,
        colors: [Color]? = nil,
        badges: [Int]? = nil,
        selectedTextColor: Color = .white,
        unselectedTextColor: Color = .white.opacity(0.6),
        currentTab: Binding<Int>
    ) {
        self.tabs = tabs
        self.colors = colors
        self.badges = badges
        self.selectedTextColor = selectedTextColor
        self.unselectedTextColor = unselectedTextColor
        self._currentTab = currentTab
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            // LAYER 0: Indicador Glassmorphism
            indicatorView

            // LAYER 1: Textos e Ícones
            labelsHStack

            // LAYER 2: Overlay de Drag
            dragOverlayView
        }
        .sensoryFeedback(.selection, trigger: feedbackTrigger)
        .onPreferenceChange(TabWidthPreferenceKey.self) { tabWidths = $0 }
        .onPreferenceChange(TextWidthPreferenceKey.self) { textWidths = $0 }
    }

    // MARK: - Views

    @ViewBuilder
    private var indicatorView: some View {
        let activeWidth = (textWidths[currentTab] ?? 60) + (horizontalPadding * 2)
        let activeColor = (colors != nil && currentTab < (colors?.count ?? 0)) ? colors![currentTab] : Color.white.opacity(0.18)

        Capsule()
            .fill(.ultraThinMaterial)
            .overlay(
                Capsule()
                    .fill(activeColor.opacity(0.25))
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            // Materiais já comunicam profundidade. No modo claro, uma sombra
            // curta e pouco opaca evita o halo escuro e mantém o contraste.
            .shadow(
                color: indicatorShadowColor,
                radius: indicatorShadowRadius,
                x: 0,
                y: indicatorShadowYOffset
            )
            .frame(width: activeWidth, height: 42)
            .offset(x: currentIndicatorOffset)
            .animation(
                isDragging ? .interactiveSpring() : .spring(response: 0.38, dampingFraction: 0.72, blendDuration: 0),
                value: currentTab
            )
            .animation(
                isDragging ? .interactiveSpring() : .spring(response: 0.38, dampingFraction: 0.72, blendDuration: 0),
                value: dragOffset
            )
    }

    private var labelsHStack: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    select(index)
                } label: {
                    HStack(spacing: 6) {
                        Text(tabs[index])
                            .font(.system(size: 15, weight: currentTab == index ? .semibold : .medium, design: .rounded))
                    }
                    .foregroundColor(currentTab == index ? selectedTextColor : unselectedTextColor)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .overlay(alignment: .topTrailing) {
                        if let count = badges?[safe: index], count > 0 {
                            ClearSegmentBadge(count: count)
                                .offset(x: 9, y: -9)
                                .allowsHitTesting(false)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: TextWidthPreferenceKey.self, value: [index: geo.size.width - (horizontalPadding * 2)])
                            .preference(key: TabWidthPreferenceKey.self, value: [index: geo.size.width])
                    }
                )
                .accessibilityValue(accessibilityValue(for: index))
                .accessibilityAddTraits(currentTab == index ? .isSelected : [])
            }
        }
    }

    private var indicatorShadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.24) : .black.opacity(0.07)
    }

    private var indicatorShadowRadius: CGFloat {
        colorScheme == .dark ? 8 : 5
    }

    private var indicatorShadowYOffset: CGFloat {
        colorScheme == .dark ? 3 : 2
    }

    @ViewBuilder
    private var dragOverlayView: some View {
        let activeWidth = (textWidths[currentTab] ?? 60) + (horizontalPadding * 2)

        Color.clear
            .frame(width: activeWidth, height: 42)
            .contentShape(Capsule())
            .offset(x: currentIndicatorOffset)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        dragOffset = gesture.translation.width
                    }
                    .onEnded { gesture in
                        isDragging = false
                        snapToNearestTab(dragDistance: gesture.translation.width)
                        dragOffset = 0
                    }
            )
    }

    // MARK: - Lógica

    private var currentIndicatorOffset: CGFloat {
        var offset: CGFloat = 0
        for i in 0..<currentTab {
            offset += tabWidths[i] ?? 0
        }
        return offset + dragOffset
    }

    private func snapToNearestTab(dragDistance: CGFloat) {
        var currentCenter: CGFloat = 0
        for i in 0..<currentTab {
            currentCenter += tabWidths[i] ?? 0
        }
        currentCenter += (tabWidths[currentTab] ?? 0) / 2
        let projectedCenter = currentCenter + dragDistance

        var accumulatedWidth: CGFloat = 0
        var closestIndex = currentTab
        var minDistance: CGFloat = .infinity

        for i in 0..<tabs.count {
            let itemWidth = tabWidths[i] ?? 0
            let tabCenter = accumulatedWidth + (itemWidth / 2)
            let distance = abs(projectedCenter - tabCenter)

            if distance < minDistance {
                minDistance = distance
                closestIndex = i
            }
            accumulatedWidth += itemWidth
        }

        if closestIndex != currentTab {
            feedbackTrigger += 1
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            currentTab = closestIndex
        }
    }

    private func select(_ index: Int) {
        guard tabs.indices.contains(index), currentTab != index else { return }
        feedbackTrigger += 1
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            currentTab = index
        }
    }

    private func accessibilityValue(for index: Int) -> String {
        guard let count = badges?[safe: index], count > 0 else {
            return "Nenhum item pendente"
        }
        return "\(count) itens pendentes"
    }
}

private struct ClearSegmentBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.caption2.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(Color.Token.textOnAccent)
            .frame(width: 20, height: 20)
            .background(Circle().fill(Color.Token.statusNotification.gradient))
            .accessibilityHidden(true)
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
