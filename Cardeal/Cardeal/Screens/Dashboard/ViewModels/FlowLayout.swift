import SwiftUI

struct FlowLayout: Layout {

    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {

        let width =
            proposal.width ?? 300

        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {

            let size = subview.sizeThatFits(
                ProposedViewSize(
                    width: nil,
                    height: nil
                )
            )

            if currentX + size.width > width &&
                currentX > 0 {

                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            currentX += size.width + spacing
            rowHeight = max(
                rowHeight,
                size.height
            )
        }

        return CGSize(
            width: width,
            height: currentY + rowHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {

        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {

            let size = subview.sizeThatFits(
                ProposedViewSize(
                    width: nil,
                    height: nil
                )
            )

            if x + size.width > bounds.maxX &&
                x > bounds.minX {

                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(
                    x: x,
                    y: y
                ),
                proposal: ProposedViewSize(
                    size
                )
            )

            x += size.width + spacing

            rowHeight = max(
                rowHeight,
                size.height
            )
        }
    }
}
