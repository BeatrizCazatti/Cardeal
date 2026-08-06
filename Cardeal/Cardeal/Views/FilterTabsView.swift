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
// A transição tem duas fases, para reproduzir o esticar elástico
// característico do Liquid Glass (como na referência anexada):
//   1. a pílula se estica rapidamente para cobrir todo o trajeto entre a
//      aba antiga e a nova;
//   2. em seguida contrai, com uma mola, até o tamanho exato do destino.

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

    private static let coordinateSpace = "filterTabsRow"

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            ZStack(alignment: .topLeading) {
                if let pillFrame {
                    Capsule()
                        // Vidro puro, sem tint de cor — é o acabamento
                        // fosco/claro e legível da referência (Apple
                        // Music), sem competir com o texto por cima.
                        .glassEffect(.regular.interactive(), in: .capsule)
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
        .onPreferenceChange(TabFramePreferenceKey.self) { frames in
            tabFrames = frames
            // Sincroniza a pílula com o layout (1ª medição, redimensionar
            // a janela etc.) sem animar quando não há troca em andamento.
            if pillFrame == nil, let frame = frames[selection.id] {
                pillFrame = frame
            }
        }
    }

    private func select(_ tab: FilterTab) {
        guard tab != selection else { return }

        guard !reduceMotion,
              let oldFrame = tabFrames[selection.id],
              let newFrame = tabFrames[tab.id]
        else {
            withAnimation(.easeInOut(duration: 0.2)) {
                selection = tab
                pillFrame = tabFrames[tab.id]
            }
            return
        }

        selection = tab

        // Fase 1 — estica para cobrir todo o trajeto entre origem e destino.
        withAnimation(.easeOut(duration: 0.16)) {
            pillFrame = oldFrame.union(newFrame)
        }

        // Fase 2 — contrai elasticamente até o tamanho exato do destino.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                pillFrame = newFrame
            }
        }
    }
}

private struct FilterTabButton: View {
    let tab: FilterTab
    let isSelected: Bool
    let action: () -> Void
    var activeSize: Int = 20

    /// Estado local de hover — responde ao ponteiro mesmo antes do clique,
    /// como pede a HIG para controles no macOS.
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                CountBadge(count: tab.count)
                Text(tab.title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .contentShape(.capsule)
        }
        
        .background (alignment: .leading) {
            ZStack {
                if #available(iOS 26, *) {
                    Capsule()
                        .fill(.clear)
                        .frame(width: isSelected ? CGFloat(activeSize) : 0, height: CGFloat(activeSize))
                        .glassEffect(.regular, in: .capsule)
                }
                else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .frame(width: isSelected ? CGFloat(activeSize) : 0, height: CGFloat(activeSize))
                }
            }
        }
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
            .background(Circle().fill(Color.red.gradient))
    }
}
