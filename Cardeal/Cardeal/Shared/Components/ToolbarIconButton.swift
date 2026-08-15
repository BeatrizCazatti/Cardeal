import SwiftUI


struct ToolbarIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .background(Circle().fill(.primaryAction))
        .shadow(color: Color.primaryAction.opacity(0.22), radius: 10, y: 4)
        .accessibilityLabel(accessibilityLabel)
    }
}
