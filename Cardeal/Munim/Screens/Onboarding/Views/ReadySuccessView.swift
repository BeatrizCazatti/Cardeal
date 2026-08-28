import SwiftUI

struct ReadySuccessView: View {
    var onStartMunim: () -> Void = {}
    
    @State private var animateBubbles = false
    
    // MARK: - Cores
    private enum Theme {
        static let titleColor = Color(red: 0.15, green: 0.35, blue: 0.82)
        static let textColor = Color(red: 0.35, green: 0.55, blue: 0.90)
        static let buttonBackground = Color(red: 0.25, green: 0.45, blue: 0.88)
        static let bubble = Color(red: 0.68, green: 0.88, blue: 0.30)
    }
    
    // MARK: - Configuração das Bolhas
    private struct BubbleItem: Identifiable {
        let id = UUID()
        let size: CGFloat
        let opacity: Double
        let x: CGFloat
        let y: CGFloat
    }
    
    private let bubbles: [BubbleItem] = [
        BubbleItem(size: 32, opacity: 0.35, x: -180, y: -160),
        BubbleItem(size: 48, opacity: 0.85, x: -260, y: -60),
        BubbleItem(size: 16, opacity: 0.75, x: -100, y: -75),
        BubbleItem(size: 28, opacity: 0.80, x: -30, y: -90),
        BubbleItem(size: 36, opacity: 0.85, x: -8,  y: -7),
        BubbleItem(size: 14, opacity: 0.85, x: -300, y: 70),
        BubbleItem(size: 34, opacity: 0.50, x: -390, y: 110),
        BubbleItem(size: 32, opacity: 0.80, x: -250, y: 150),
        BubbleItem(size: 38, opacity: 0.55, x: -70,  y: 190)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                // Conteúdo textual e ação
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    descriptionSection
                    Spacer()
                    actionButton
                }
                .padding(.top, 110)
                .padding(.bottom, 80)
                .padding(.leading, 80)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                
                // Ilustração e partículas decorativas
                characterIllustration(geometry: geometry)
            }
        }
        .background(Color.white)
        .ignoresSafeArea()
        .onAppear {
            animateBubbles = true
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        Text("Sua memória organizacional\nestá pronta!")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(Theme.titleColor)
            .lineSpacing(6)
            .padding(.bottom, 36)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Identificamos sua equipe e seus times, você\npode conferir ou alterar as informações da\nequipe na tela inicial.")
                .lineSpacing(4)
            
            Text("Você está pronto para começar!")
        }
        .font(.system(size: 18, weight: .regular))
        .foregroundColor(Theme.textColor)
    }
    
    private var actionButton: some View {
        Button(action: onStartMunim) {
            Text("Iniciar Munim")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .background(Theme.buttonBackground)
                .cornerRadius(24)
        }
        .buttonStyle(.plain)
    }
    
    private func characterIllustration(geometry: GeometryProxy) -> some View {
        ZStack {
            ForEach(bubbles) { bubble in
                Circle()
                    .fill(Theme.bubble.opacity(bubble.opacity))
                    .frame(width: bubble.size, height: bubble.size)
                    .offset(x: bubble.x, y: bubble.y)
            }
            
            Image("MunimIdle")
                .resizable()
                .scaledToFit()
                .frame(
                    width: geometry.size.width * 0.55,
                    height: geometry.size.height * 0.75
                )
                .offset(x: 40, y: 40)
        }
        .scaleEffect(animateBubbles ? 1.02 : 0.98)
        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: animateBubbles)
    }
}

#Preview {
    ReadySuccessView()
        .frame(width: 960, height: 600)
}
