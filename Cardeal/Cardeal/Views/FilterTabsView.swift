import SwiftUI
//
//  TabFramePreferenceKey.swift
//  Cardeal
//
//  Created by Beatriz Cazatti on 05/08/26.
//


// MARK: - Abas de filtro com pílula de Liquid Glass deslizante
//
// Diferente da 1ª versão (que usava `matchedGeometryEffect` por aba — o
// que na prática cria DUAS views diferentes fazendo cross-fade, e por
// isso parecia "selecionar" em vez de deslizar), aqui existe apenas UMA
// forma de vidro, medida via `GeometryReader` + `PreferenceKey` e
// posicionada com `.offset`/`.frame` numa camada própria, atrás de todo o
// `HStack` de abas. Como o texto vive numa camada separada e estática à
// frente, ele nunca fica "dentro" do vidro em movimento — fica sempre
// visível por cima, mesmo em pleno trânsito.
//
// A pílula preserva exatamente o tamanho da aba selecionada. Durante o
// arraste, somente a sua escala visual muda, como uma lente sobre o texto.

/// Publica a posição (no espaço de coordenadas do próprio grupo de abas)
/// de cada aba, para que a pílula saiba onde deslizar.
private struct TabFramePreferenceKey: PreferenceKey {
    static var defaultValue: [FilterTab.ID: CGRect] = [:]
    static func reduce(value: inout [FilterTab.ID: CGRect], nextValue: () -> [FilterTab.ID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct FilterTabsView: View {
    let tabs: [FilterTab]
    @Binding var selection: FilterTab

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tabFrames: [FilterTab.ID: CGRect] = [:]
    @State private var pillFrame: CGRect?
    @State private var isDraggingSelection = false

    private static let coordinateSpace = "filterTabsRow"

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            ZStack(alignment: .topLeading) {
                if let pillFrame {
                    Capsule()
                        // Durante o arraste, o vidro funciona como lente e
                        // recebe apenas escala visual. Ao soltar, torna-se
                        // um fundo translúcido mais escuro, sem deslocar
                        // nem redimensionar a área dos botões.
                        .fill(Color.primary.opacity(isDraggingSelection ? 0.04 : 0.18))
                        .glassEffect(
                            isDraggingSelection
                                ? .regular.interactive()
                                : .regular.tint(Color.black.opacity(0.22)),
                            in: .capsule
                        )
                        .scaleEffect(isDraggingSelection ? 1.045 : 1)
                        .opacity(isDraggingSelection ? 0.9 : 0.78)
                        .frame(width: pillFrame.width, height: pillFrame.height)
                        .offset(x: pillFrame.minX, y: pillFrame.minY)
                        .allowsHitTesting(false)
                }

                HStack(spacing: 2) {
                    ForEach(tabs) { tab in
                        FilterTabButton(tab: tab, isSelected: tab == selection) {
                            select(tab)
                        }
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: TabFramePreferenceKey.self,
                                    value: [tab.id: proxy.frame(in: .named(Self.coordinateSpace))]
                                )
                            }
                        )
                    }
                }
            }
            .padding(4)
        }
        .coordinateSpace(name: Self.coordinateSpace)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.coordinateSpace))
                .onChanged { value in
                    isDraggingSelection = true
                    updateSelection(at: value.location)
                }
                .onEnded { value in
                    updateSelection(at: value.location)
                    isDraggingSelection = false
                }
        )
        .onPreferenceChange(TabFramePreferenceKey.self) { frames in
            tabFrames = frames
            // Sincroniza a pílula com o layout (1ª medição, redimensionar
            // a janela etc.) sem animar quando não há troca em andamento.
            if pillFrame == nil, let frame = frames[selection.id] {
                pillFrame = frame
            }
        }
    }

    private func select(_ tab: FilterTab, isDragging: Bool = false) {
        guard tab != selection else { return }

        selection = tab
        withAnimation(
            reduceMotion
                ? .linear(duration: 0.01)
                : (isDragging
                    ? .interactiveSpring(response: 0.26, dampingFraction: 0.82)
                    : .spring(response: 0.3, dampingFraction: 0.86))
        ) {
            pillFrame = tabFrames[tab.id]
        }
    }

    private func updateSelection(at location: CGPoint) {
        guard let tab = tabs.first(where: { tabFrames[$0.id]?.contains(location) == true }) else {
            return
        }

        select(tab, isDragging: true)
    }
}

private struct FilterTabButton: View {
    let tab: FilterTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if tab.count > 0 {
                    CountBadge(count: tab.count)
                }
                Text(tab.title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

/// Badge circular numerado, reutilizado nas abas e nos cards. Sempre em
/// vermelho sólido com número branco — mantém a legibilidade constante,
/// selecionado ou não, em vez de variar opacidade sobre vidro.
struct CountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(Circle().fill(Color.counterBadge.gradient))
    }
}

