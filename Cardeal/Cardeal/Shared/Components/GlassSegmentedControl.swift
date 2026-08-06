import SwiftUI

struct GlassSegmentedControl: View {
    var config: Config = .init()
    
    @Binding var selection: Int
    @Binding var tabs: [Self.Tab]
    
    var body: some View {
        GeometryReader {
            let containerSize = $0.size
            let activeSize = tabs[selection].viewSize
            
            HStack(spacing: 0) {
                ForEach(tabs) { tab in
                    Text(tab.title)
                        .font(.system(size: 18))
                        .padding(.horizontal, (config.refractionDepth + 3))
                        .frame(height: containerSize.height)
                }
            }
            .background (alignment: .leading) {
                ZStack {
                    if #available(iOS 26, *) {
                        Capsule()
                            .fill(.clear)
                            .frame(width: activeSize.width, height: activeSize.height)
                            .glassEffect(.regular, in: .capsule)
                    }
                    else {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .frame(width: activeSize.width, height: activeSize.height)
                    }
                }
                .visualEffect { content, proxy in
                    let midX = proxy.frame(in: .global).midX
                    
                    return content
                        .offset(x: -midX)
                }
            }        }
    }
    
    struct Config {
        var tint: Color = .yellow
        var refractionAmount: CGFloat = 10
        var refractionDepth: CGFloat = 17
    }

    struct Tab: Identifiable {
        var id: String { title }
        var title: String
        
        fileprivate var viewSize: CGSize = .zero
        
        init(title: String) {
            self.title = title
        }
    }

}

#Preview {
    TesteView()
}

