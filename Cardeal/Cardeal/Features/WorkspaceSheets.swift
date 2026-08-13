import SwiftUI

struct CaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var detail = ""
    @State private var kind: MemoryKind = .decision
    @State private var project = "Expansão LATAM"
    let onSave: (MemoryItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Registrar memória").font(.title3.weight(.bold))
            Text("Capture o contexto agora e transforme-o em conhecimento reutilizável.").font(.caption).foregroundStyle(Color.cardealMuted)
            Picker("Tipo", selection: $kind) { ForEach(MemoryKind.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
            FormField(title: "Título") { TextField("Ex.: Aprovação da nova política comercial", text: $title).textFieldStyle(.roundedBorder) }
            FormField(title: "Contexto e desdobramentos") { TextEditor(text: $detail).font(.body).frame(height: 110).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cardealLine)) }
            TextField("Projeto", text: $project).textFieldStyle(.roundedBorder)
            HStack { Spacer(); Button("Cancelar") { dismiss() }; Button("Salvar memória", action: save).buttonStyle(.borderedProminent).tint(Color.cardealPurple) }
        }.padding(26).frame(width: 510)
    }

    private func save() {
        onSave(MemoryItem(title: title.isEmpty ? "Nova memória sem título" : title, detail: detail.isEmpty ? "Registro criado manualmente." : detail, kind: kind, project: project, time: "Agora"))
        dismiss()
    }
}

struct AutomationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var date = Date().addingTimeInterval(86_400)
    let onSchedule: (String, Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Criar automação").font(.title3.weight(.bold))
            Text("O Cardeal criará uma ação e agendará um lembrete local.").font(.caption).foregroundStyle(Color.cardealMuted)
            TextField("O que precisa acontecer?", text: $title).textFieldStyle(.roundedBorder)
            DatePicker("Quando", selection: $date, displayedComponents: [.date, .hourAndMinute])
            HStack { Spacer(); Button("Cancelar") { dismiss() }; Button("Agendar", action: schedule).buttonStyle(.borderedProminent).tint(Color.cardealPurple) }
        }.padding(26).frame(width: 460)
    }

    private func schedule() {
        onSchedule(title.isEmpty ? "Acompanhamento pendente" : title, date)
        dismiss()
    }
}

private struct FormField<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View { VStack(alignment: .leading, spacing: 6) { Text(title).font(.caption.weight(.medium)); content } }
}
