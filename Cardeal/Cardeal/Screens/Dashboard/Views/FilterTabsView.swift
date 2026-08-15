import SwiftUI

// MARK: - Abas de filtro

/// Uma barra de abas horizontal com seleção em Liquid Glass e badges de itens
/// pendentes. O conteúdo continua legível e cada aba mantém uma área de toque
/// independente, mesmo quando a barra precisa rolar horizontalmente.
struct FilterTabsView: View {
    let tabs: [FilterTab]
    @Binding var selection: FilterTab

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainerCompat(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(tabs) { tab in
                        FilterTabButton(
                            tab: tab,
                            isSelected: tab == selection,
                            action: { select(tab) }
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filtros do dashboard")
    }

    private func select(_ tab: FilterTab) {
        guard tab != selection else { return }

        if reduceMotion {
            selection = tab
        } else {
            withAnimation(.snappy(duration: 0.25)) {
                selection = tab
            }
        }
    }
}

private struct FilterTabButton: View {
    let tab: FilterTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tab.title)
                .foregroundStyle(isSelected ? Color.tabButtonSelectedText : Color.tabButtonText)
                .font(.title3.weight(isSelected ? .semibold : .regular))
                .lineLimit(1)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .background {
            if isSelected {
                Capsule(style: .continuous)
                    .fill(Color.primaryAction)
            }
        }
        .overlay(alignment: .topTrailing) {
            if tab.count > 0 {
                CountBadge(count: tab.count, diameter: 25)
                    .offset(x: 10, y: -10)
                    .allowsHitTesting(false)
            }
        }
        .padding(.top, 16)
        .accessibilityLabel(tab.title)
        .accessibilityValue(tab.count > 0 ? "\(tab.count) itens pendentes" : "Nenhum item pendente")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Badge circular reutilizável para sinalizar a quantidade de itens pendentes.
/// O valor vem do estado do dashboard; ao mudá-lo, o SwiftUI atualiza a badge
/// junto com a aba correspondente.
struct CountBadge: View {
    let count: Int
    var diameter: CGFloat = 20

    var body: some View {
        Text("\(count)")
            .font(diameter >= 30 ? .subheadline.weight(.bold) : .caption2.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(.white)
            .frame(width: diameter, height: diameter)
            .background(Circle().fill(Color.counterBadge.gradient))
            .accessibilityLabel("\(count) itens pendentes")
    }
}
