import SwiftUI

struct TesteView: View {
    @State private var activeIndex: Int = 0
    @State private var tabs: [GlassSegmentedControl.Tab] = [
        .init(title: "Geral"),
        .init(title: "Reuniões"),
        .init(title: "Tarefas"),
        .init(title: "Mudanças"),
        .init(title: "Decisões")
        ]
    var body: some View {
        VStack {
            GlassSegmentedControl(selection: $activeIndex, tabs: tabs)
        }
    }
}

#Preview {
    TesteView()
}
