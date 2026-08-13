import SwiftUI

/// Controle segmentado com uma única superfície de vidro em movimento.
/// O `matchedGeometryEffect` é aplicado apenas à pílula selecionada, evitando
/// camadas duplicadas e mantendo o texto fora da animação.
struct GlassSegmentedControl: View {
    var config: Config = .init()
    @Binding var selection: Int
    let tabs: [Tab]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                Button {
                    if reduceMotion {
                        selection = index
                    } else {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            selection = index
                        }
                    }
                } label: {
                    Text(tab.title)
                        .font(.subheadline.weight(selection == index ? .semibold : .regular))
                        .foregroundStyle(selection == index ? .primary : .secondary)
                        .lineLimit(1)
                        .padding(.vertical, 8)
                        .padding(.horizontal, config.horizontalPadding)
                }
                .buttonStyle(GlassSegmentButtonStyle(
                    isSelected: selection == index,
                    namespace: selectionNamespace,
                    reduceMotion: reduceMotion
                ))
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selection == index ? .isSelected : [])
            }
        }
        .padding(4)
        .modifier(GlassSegmentContainerModifier())
    }

    struct Config {
        var horizontalPadding: CGFloat = 16
    }

    struct Tab: Identifiable {
        var id: String { title }
        var title: String
    }
}

private struct GlassSegmentButtonStyle: ButtonStyle {
    let isSelected: Bool
    let namespace: Namespace.ID
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                if isSelected {
                    GlassSelectionCapsule(isPressed: configuration.isPressed)
                        .matchedGeometryEffect(id: "glass-segment-selection", in: namespace)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Ao pressionar, somente o vidro desaparece. O rótulo permanece opaco e
/// legível; ao soltar, a pílula translúcida volta ao estado selecionado.
private struct GlassSelectionCapsule: View {
    let isPressed: Bool

    var body: some View {
        Group {
            if #available(macOS 26.0, iOS 26.0, *) {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular.tint(Color.primary.opacity(0.12)).interactive(), in: .capsule)
            } else {
                Capsule()
                    .fill(Color.primary.opacity(0.12))
                    .overlay { Capsule().strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.5) }
            }
        }
        .opacity(isPressed ? 0 : 1)
        .animation(.easeOut(duration: 0.1), value: isPressed)
    }
}

private struct GlassSegmentContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, iOS 26.0, *) {
            GlassEffectContainer(spacing: 4) { content }
        } else {
            content
                .background(Capsule().fill(.thinMaterial))
                .overlay { Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5) }
        }
    }
}
