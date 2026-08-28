import SwiftUI

// Estrutura de dados para definir cada partícula de bolha verde
struct BubbleParticle: Identifiable {
    let id = UUID()
    let size: CGFloat
    let finalX: CGFloat
    let finalY: CGFloat
    let duration: Double
    let delay: Double
}

struct LoadingView: View {
    @State private var isAnimating: Bool = false
    @State private var progress: CGFloat = 0.0
    
    private let primaryBlue = Color(red: 0.25, green: 0.45, blue: 0.88)
    private let lightBlue = Color(red: 0.35, green: 0.55, blue: 0.90)
    private let bubbleColor = Color(red: 0.65, green: 0.85, blue: 0.30)
    
    // Configurações de posições e tamanhos das partículas
    private let particles: [BubbleParticle] = [
        BubbleParticle(size: 26, finalX: -160, finalY: -110, duration: 2.6, delay: 0.0),
        BubbleParticle(size: 16, finalX: -200, finalY: -160, duration: 3.1, delay: 0.4),
        BubbleParticle(size: 32, finalX: 180, finalY: -150, duration: 2.8, delay: 0.2),
        BubbleParticle(size: 22, finalX: 200, finalY: -80, duration: 3.4, delay: 0.6),
        BubbleParticle(size: 28, finalX: 190, finalY: 10, duration: 2.9, delay: 0.3),
        BubbleParticle(size: 14, finalX: 230, finalY: 20, duration: 3.2, delay: 0.8),
        BubbleParticle(size: 34, finalX: -70, finalY: -125, duration: 2.7, delay: 0.1),
        BubbleParticle(size: 12, finalX: -30, finalY: -110, duration: 2.4, delay: 0.5),
        BubbleParticle(size: 18, finalX: 20, finalY: -170, duration: 3.3, delay: 0.7),
        BubbleParticle(size: 10, finalX: 90, finalY: -160, duration: 2.5, delay: 0.2),
        BubbleParticle(size: 24, finalX: 165, finalY: -60, duration: 3.0, delay: 0.9),
        BubbleParticle(size: 16, finalX: -170, finalY: -45, duration: 2.6, delay: 0.4),
        BubbleParticle(size: 12, finalX: -100, finalY: -70, duration: 3.2, delay: 0.3),
        BubbleParticle(size: 18, finalX: -60, finalY: -60, duration: 2.8, delay: 0.7),
        BubbleParticle(size: 22, finalX: -150, finalY: 30, duration: 3.1, delay: 0.5),
        BubbleParticle(size: 14, finalX: -80, finalY: 20, duration: 2.7, delay: 0.2),
        BubbleParticle(size: 10, finalX: -60, finalY: 55, duration: 3.5, delay: 0.6),
        BubbleParticle(size: 10, finalX: 220, finalY: -40, duration: 2.9, delay: 0.8),
        BubbleParticle(size: 12, finalX: 215, finalY: 70, duration: 3.3, delay: 0.4)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Área Central: Pássaro + Animação de Bolhas
            ZStack {
                // Bolhas verdes animadas do centro para fora
                ForEach(particles) { p in
                    Circle()
                        .fill(bubbleColor.opacity(isAnimating ? 0.75 : 0.0))
                        .frame(width: p.size, height: p.size)
                        .scaleEffect(isAnimating ? 1.0 : 0.1)
                        .offset(
                            x: isAnimating ? p.finalX : 0,
                            y: isAnimating ? p.finalY : 0
                        )
                        .animation(
                            .easeInOut(duration: p.duration)
                            .repeatForever(autoreverses: true)
                            .delay(p.delay),
                            value: isAnimating
                        )
                }
                
                // Ilustração central
                Image("MunimCharacter")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170, height: 170)
            }
            .frame(height: 280)
            
            // Textos Informativos
            VStack(spacing: 12) {
                Text("Iniciando sincronização dos dados do Workspace")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(primaryBlue)
                    .multilineTextAlignment(.center)
                
                Text("Aguarde alguns instantes enquanto Munim organiza\nsua memória organizacional...")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(lightBlue)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.top, 24)
            .padding(.bottom, 36)
            
            // Barra de Progresso
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Trilho cinza
                    Capsule()
                        .fill(Color.gray.opacity(0.18))
                        .frame(height: 7)
                    
                    // Preenchimento azul com animação suave
                    Capsule()
                        .fill(primaryBlue)
                        .frame(width: geometry.size.width * progress, height: 7)
                        .animation(.linear(duration: 4.0), value: progress)
                }
            }
            .frame(width: 440, height: 7)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .ignoresSafeArea()
        .onAppear {
            isAnimating = true
            progress = 1.0
        }
    }
}

#Preview {
    LoadingView()
        .frame(width: 960, height: 600)
}
