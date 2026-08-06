import SwiftUI

//struct Sidebar: View {
//    @Binding var selectedSection: WorkspaceSection
//    let onNewMemory: () -> Void
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            BrandMark().padding(.horizontal, 22).padding(.top, 24).padding(.bottom, 30)
//            VStack(spacing: 4) {
//                ForEach(WorkspaceSection.allCases.filter { $0 != .settings }) { section in
//                    SidebarItem(section: section, isSelected: selectedSection == section) { selectedSection = section }
//                }
//            }.padding(.horizontal, 12)
//            Spacer()
//            Button(action: onNewMemory) {
//                Label("Registrar memória", systemImage: "plus")
//                    .font(.system(size: 12, weight: .semibold))
//                    .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 10)
//                    .background(Color.cardealPurple, in: RoundedRectangle(cornerRadius: 8))
//            }.buttonStyle(.plain).padding(.horizontal, 18)
//            Divider().padding(.top, 22).overlay(Color.cardealLine)
//            ProfileButton { selectedSection = .settings }
//        }
//        .frame(width: 220)
//        .background(.white)
//    }
//}

struct TopBar: View {
    @Binding var searchText: String
    let onNewMemory: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            SearchField(text: $searchText)
            Spacer()
            Button { } label: { Image(systemName: "bell").foregroundStyle(Color.cardealMuted).padding(8) }.buttonStyle(.plain)
            Button(action: onNewMemory) {
                Label("Nova entrada", systemImage: "plus")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 13).padding(.vertical, 9)
                    .background(Color.cardealPurple, in: RoundedRectangle(cornerRadius: 7))
            }.buttonStyle(.plain)
        }.padding(.horizontal, 34).padding(.vertical, 15).background(.white)
    }
}

private struct BrandMark: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack { RoundedRectangle(cornerRadius: 8).fill(Color.cardealPurple); Image(systemName: "sparkle").font(.system(size: 13, weight: .bold)).foregroundStyle(.white) }.frame(width: 29, height: 29)
            Text("cardeal").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(Color.cardealInk)
        }
    }
}

//private struct SidebarItem: View {
//    let section: WorkspaceSection
//    let isSelected: Bool
//    let action: () -> Void
//    var body: some View {
//        Button(action: action) {
//            Label(section.rawValue, systemImage: section.icon)
//                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
//                .foregroundStyle(isSelected ? Color.cardealPurple : Color.cardealMuted)
//                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).padding(.vertical, 10)
//                .background(isSelected ? Color.cardealPurple.opacity(0.09) : .clear, in: RoundedRectangle(cornerRadius: 7))
//        }.buttonStyle(.plain)
//    }
//}

private struct ProfileButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Circle().fill(Color.cardealPink).frame(width: 30, height: 30).overlay(Text("BC").font(.system(size: 10, weight: .bold)).foregroundStyle(Color.cardealPurple))
                VStack(alignment: .leading, spacing: 2) { Text("Beatriz Cazatti").font(.system(size: 11, weight: .medium)).foregroundStyle(Color.cardealInk); Text("Administradora").font(.system(size: 10)).foregroundStyle(Color.cardealMuted) }
            }.padding(18)
        }.buttonStyle(.plain)
    }
}

private struct SearchField: View {
    @Binding var text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(Color.cardealMuted)
            TextField("Buscar em toda a memória...", text: $text).textFieldStyle(.plain).font(.system(size: 13))
            Text("⌘ K").font(.system(size: 10, weight: .medium)).foregroundStyle(Color.cardealMuted).padding(.horizontal, 5).padding(.vertical, 3).background(Color.cardealCanvas, in: RoundedRectangle(cornerRadius: 4))
        }.padding(.horizontal, 12).padding(.vertical, 9).frame(maxWidth: 430).background(Color.cardealCanvas, in: RoundedRectangle(cornerRadius: 8))
    }
}
