import SwiftUI

// Every icon in the app is drawn here from paths. Nothing is taken from the system
// symbol set, and there is no emoji anywhere in the interface.

// MARK: - Crescent

/// A crescent: the sliver of a disc that a second, offset disc leaves uncovered.
///
/// Traced directly rather than by subtracting one path from another — `CGPath.subtracting`
/// is iOS 16, and this app targets 15.6. The two boundary arcs are sampled, which also
/// keeps the winding simple enough to both fill and stroke.
struct HJCrescentShape: Shape {
    /// 0 gives a fat crescent, 1 a thin rind.
    var thinness: CGFloat = 0.42

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let outerRadius = side / 2
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let bite = max(0, min(1, thinness))
        let innerRadius = outerRadius * (0.86 + bite * 0.10)
        let offset = outerRadius * (0.32 + bite * 0.52)

        func fullDisc() -> Path {
            var disc = Path()
            disc.addEllipse(in: CGRect(x: centre.x - outerRadius, y: centre.y - outerRadius,
                                       width: outerRadius * 2, height: outerRadius * 2))
            return disc
        }

        // The two circles must actually cross, or there is no crescent to draw.
        guard outerRadius > 0.5,
              offset > abs(outerRadius - innerRadius),
              offset < outerRadius + innerRadius else { return fullDisc() }

        // Where they cross, measured along the axis from the outer centre.
        let axis = (offset * offset + outerRadius * outerRadius - innerRadius * innerRadius)
            / (2 * offset)
        let heightSquared = outerRadius * outerRadius - axis * axis
        guard heightSquared > 0 else { return fullDisc() }
        let height = sqrt(heightSquared)

        // Screen coordinates run downward, so the upper crossing has the negative offset.
        let outerTop = atan2(-height, axis)
        let outerBottom = atan2(height, axis)
        let innerCentre = CGPoint(x: centre.x + offset, y: centre.y)
        let innerTop = atan2(-height, axis - offset)
        let innerBottom = atan2(height, axis - offset)

        var path = Path()
        let steps = 64

        // Outer edge: the long way round the left, from the lower crossing to the upper.
        let outerFrom = outerBottom
        let outerTo = outerTop + 2 * .pi
        for step in 0...steps {
            let angle = outerFrom + (outerTo - outerFrom) * CGFloat(step) / CGFloat(steps)
            let point = CGPoint(x: centre.x + cos(angle) * outerRadius,
                                y: centre.y + sin(angle) * outerRadius)
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }

        // Inner edge: back down the left side of the smaller circle.
        let innerFrom = innerTop
        let innerTo = innerBottom - 2 * .pi
        for step in 0...steps {
            let angle = innerFrom + (innerTo - innerFrom) * CGFloat(step) / CGFloat(steps)
            path.addLine(to: CGPoint(x: innerCentre.x + cos(angle) * innerRadius,
                                     y: innerCentre.y + sin(angle) * innerRadius))
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Calendar page

/// A leaf of a calendar: a rounded card with a header band and a small grid.
struct HJCalendarPageShape: Shape {
    var rows: Int = 3
    var columns: Int = 4

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let box = CGRect(x: rect.minX + rect.width * 0.06,
                         y: rect.minY + rect.height * 0.12,
                         width: rect.width * 0.88,
                         height: rect.height * 0.80)
        path.addRoundedRect(in: box, cornerSize: CGSize(width: box.width * 0.12,
                                                        height: box.width * 0.12))
        // header rule
        let bandY = box.minY + box.height * 0.28
        path.move(to: CGPoint(x: box.minX, y: bandY))
        path.addLine(to: CGPoint(x: box.maxX, y: bandY))

        // two hangers over the top edge
        let hangerInset = box.width * 0.26
        for x in [box.minX + hangerInset, box.maxX - hangerInset] {
            path.move(to: CGPoint(x: x, y: box.minY - rect.height * 0.09))
            path.addLine(to: CGPoint(x: x, y: box.minY + rect.height * 0.05))
        }

        // grid of ticks
        let gridTop = bandY + box.height * 0.14
        let gridBottom = box.maxY - box.height * 0.12
        let gridLeft = box.minX + box.width * 0.14
        let gridRight = box.maxX - box.width * 0.14
        guard rows > 0, columns > 0 else { return path }
        let cellW = (gridRight - gridLeft) / CGFloat(columns)
        let cellH = (gridBottom - gridTop) / CGFloat(rows)
        let dot = min(cellW, cellH) * 0.34
        for r in 0..<rows {
            for c in 0..<columns {
                let cx = gridLeft + cellW * (CGFloat(c) + 0.5)
                let cy = gridTop + cellH * (CGFloat(r) + 0.5)
                path.addRoundedRect(in: CGRect(x: cx - dot / 2, y: cy - dot / 2,
                                               width: dot, height: dot),
                                    cornerSize: CGSize(width: dot * 0.3, height: dot * 0.3))
            }
        }
        return path
    }
}

// MARK: - Navigation

/// A chevron. `direction`: 0 right, 1 left, 2 up, 3 down.
struct HJChevronShape: Shape {
    var direction: Int = 0

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let inset: CGFloat = 0.24
        var points: [CGPoint]
        switch direction {
        case 1:
            points = [CGPoint(x: w * (1 - inset), y: h * 0.10),
                      CGPoint(x: w * inset, y: h * 0.5),
                      CGPoint(x: w * (1 - inset), y: h * 0.90)]
        case 2:
            points = [CGPoint(x: w * 0.10, y: h * (1 - inset)),
                      CGPoint(x: w * 0.5, y: h * inset),
                      CGPoint(x: w * 0.90, y: h * (1 - inset))]
        case 3:
            points = [CGPoint(x: w * 0.10, y: h * inset),
                      CGPoint(x: w * 0.5, y: h * (1 - inset)),
                      CGPoint(x: w * 0.90, y: h * inset)]
        default:
            points = [CGPoint(x: w * inset, y: h * 0.10),
                      CGPoint(x: w * (1 - inset), y: h * 0.5),
                      CGPoint(x: w * inset, y: h * 0.90)]
        }
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + points[0].x, y: rect.minY + points[0].y))
        path.addLine(to: CGPoint(x: rect.minX + points[1].x, y: rect.minY + points[1].y))
        path.addLine(to: CGPoint(x: rect.minX + points[2].x, y: rect.minY + points[2].y))
        return path
    }
}

/// Two chevrons, for a year jump.
struct HJDoubleChevronShape: Shape {
    var direction: Int = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let half = rect.width * 0.52
        let left = CGRect(x: rect.minX, y: rect.minY, width: half, height: rect.height)
        let right = CGRect(x: rect.maxX - half, y: rect.minY, width: half, height: rect.height)
        path.addPath(HJChevronShape(direction: direction).path(in: left))
        path.addPath(HJChevronShape(direction: direction).path(in: right))
        return path
    }
}

// MARK: - Small marks

struct HJPlusShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.12))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.midY))
        return path
    }
}

struct HJMinusShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.midY))
        return path
    }
}

struct HJCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.54))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.minY + rect.height * 0.78))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.84, y: rect.minY + rect.height * 0.22))
        return path
    }
}

struct HJCrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.20))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.20, y: rect.maxY - rect.height * 0.20))
        path.move(to: CGPoint(x: rect.maxX - rect.width * 0.20, y: rect.minY + rect.height * 0.20))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.maxY - rect.height * 0.20))
        return path
    }
}

struct HJTrashShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let bodyTop = rect.minY + h * 0.28
        path.move(to: CGPoint(x: rect.minX + w * 0.22, y: bodyTop))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.30, y: rect.maxY - h * 0.08))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.30, y: rect.maxY - h * 0.08))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.22, y: bodyTop))
        path.move(to: CGPoint(x: rect.minX + w * 0.13, y: bodyTop))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.13, y: bodyTop))
        path.move(to: CGPoint(x: rect.minX + w * 0.38, y: bodyTop))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.38, y: rect.minY + h * 0.12))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.38, y: rect.minY + h * 0.12))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.38, y: bodyTop))
        return path
    }
}

/// An eight-pointed star — the marker for a fixed observance.
struct HJStarShape: Shape {
    var points: Int = 8
    var innerRatio: CGFloat = 0.46

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        let total = max(3, points) * 2
        for i in 0..<total {
            let angle = (CGFloat(i) / CGFloat(total)) * .pi * 2 - .pi / 2
            let r = i % 2 == 0 ? radius : radius * innerRatio
            let point = CGPoint(x: centre.x + cos(angle) * r, y: centre.y + sin(angle) * r)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

/// A small rounded lozenge — the marker for a recurring day.
struct HJLozengeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let rx = rect.width / 2, ry = rect.height / 2
        path.move(to: CGPoint(x: centre.x, y: centre.y - ry))
        path.addQuadCurve(to: CGPoint(x: centre.x + rx, y: centre.y),
                          control: CGPoint(x: centre.x + rx * 0.55, y: centre.y - ry * 0.55))
        path.addQuadCurve(to: CGPoint(x: centre.x, y: centre.y + ry),
                          control: CGPoint(x: centre.x + rx * 0.55, y: centre.y + ry * 0.55))
        path.addQuadCurve(to: CGPoint(x: centre.x - rx, y: centre.y),
                          control: CGPoint(x: centre.x - rx * 0.55, y: centre.y + ry * 0.55))
        path.addQuadCurve(to: CGPoint(x: centre.x, y: centre.y - ry),
                          control: CGPoint(x: centre.x - rx * 0.55, y: centre.y - ry * 0.55))
        path.closeSubpath()
        return path
    }
}

// MARK: - Tab bar

/// A sun over a horizon — the Today tab.
struct HJTodayGlyphShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(rect.width, rect.height) * 0.24
        let centre = CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.06)
        path.addEllipse(in: CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2))
        for i in 0..<8 {
            let angle = CGFloat(i) / 8 * .pi * 2
            let inner = r * 1.45, outer = r * 1.95
            path.move(to: CGPoint(x: centre.x + cos(angle) * inner, y: centre.y + sin(angle) * inner))
            path.addLine(to: CGPoint(x: centre.x + cos(angle) * outer, y: centre.y + sin(angle) * outer))
        }
        return path
    }
}

/// A month grid — the Calendar tab.
struct HJGridGlyphShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let box = rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.10)
        path.addRoundedRect(in: box, cornerSize: CGSize(width: box.width * 0.12,
                                                        height: box.width * 0.12))
        let headY = box.minY + box.height * 0.26
        path.move(to: CGPoint(x: box.minX, y: headY))
        path.addLine(to: CGPoint(x: box.maxX, y: headY))
        let cols = 3
        let rows = 2
        let cellW = box.width / CGFloat(cols + 1)
        let cellH = (box.maxY - headY) / CGFloat(rows + 1)
        for c in 1...cols {
            let x = box.minX + cellW * CGFloat(c)
            path.move(to: CGPoint(x: x, y: headY))
            path.addLine(to: CGPoint(x: x, y: box.maxY))
        }
        for r in 1...rows {
            let y = headY + cellH * CGFloat(r)
            path.move(to: CGPoint(x: box.minX, y: y))
            path.addLine(to: CGPoint(x: box.maxX, y: y))
        }
        return path
    }
}

/// Two arrows swapping — the Convert tab.
struct HJSwapGlyphShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let topY = rect.minY + h * 0.30
        let bottomY = rect.maxY - h * 0.30
        path.move(to: CGPoint(x: rect.minX + w * 0.12, y: topY))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.14, y: topY))
        path.move(to: CGPoint(x: rect.maxX - w * 0.34, y: topY - h * 0.14))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.12, y: topY))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.34, y: topY + h * 0.14))
        path.move(to: CGPoint(x: rect.maxX - w * 0.12, y: bottomY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.14, y: bottomY))
        path.move(to: CGPoint(x: rect.minX + w * 0.34, y: bottomY - h * 0.14))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.12, y: bottomY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.34, y: bottomY + h * 0.14))
        return path
    }
}

/// An open book — the Library tab.
struct HJBookGlyphShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let top = rect.minY + h * 0.22
        let bottom = rect.maxY - h * 0.18
        let spine = rect.midX
        path.move(to: CGPoint(x: spine, y: top + h * 0.06))
        path.addLine(to: CGPoint(x: spine, y: bottom))
        path.move(to: CGPoint(x: rect.minX + w * 0.10, y: top))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.10, y: bottom - h * 0.06))
        path.addQuadCurve(to: CGPoint(x: spine, y: bottom),
                          control: CGPoint(x: rect.minX + w * 0.26, y: bottom - h * 0.02))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.10, y: top),
                          control: CGPoint(x: rect.minX + w * 0.26, y: top - h * 0.02))
        path.move(to: CGPoint(x: rect.maxX - w * 0.10, y: top))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.10, y: bottom - h * 0.06))
        path.addQuadCurve(to: CGPoint(x: spine, y: bottom),
                          control: CGPoint(x: rect.maxX - w * 0.26, y: bottom - h * 0.02))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - w * 0.10, y: top),
                          control: CGPoint(x: rect.maxX - w * 0.26, y: top - h * 0.02))
        return path
    }
}

/// A notched dial — the Settings tab.
struct HJDialGlyphShape: Shape {
    var teeth: Int = 8

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) * 0.40
        let inner = outer * 0.52
        path.addEllipse(in: CGRect(x: centre.x - outer, y: centre.y - outer,
                                   width: outer * 2, height: outer * 2))
        path.addEllipse(in: CGRect(x: centre.x - inner, y: centre.y - inner,
                                   width: inner * 2, height: inner * 2))
        for i in 0..<max(3, teeth) {
            let angle = CGFloat(i) / CGFloat(max(3, teeth)) * .pi * 2
            path.move(to: CGPoint(x: centre.x + cos(angle) * outer,
                                  y: centre.y + sin(angle) * outer))
            path.addLine(to: CGPoint(x: centre.x + cos(angle) * outer * 1.30,
                                     y: centre.y + sin(angle) * outer * 1.30))
        }
        return path
    }
}

/// A knotted band used as a quiet header ornament.
struct HJBandOrnamentShape: Shape {
    var cells: Int = 8

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let count = max(2, cells)
        let step = rect.width / CGFloat(count)
        let midY = rect.midY
        let amp = min(rect.height / 2, step * 0.55)
        for i in 0..<count {
            let x0 = rect.minX + step * CGFloat(i)
            let x1 = x0 + step
            path.move(to: CGPoint(x: x0, y: midY))
            path.addLine(to: CGPoint(x: x0 + step / 2, y: midY - amp))
            path.addLine(to: CGPoint(x: x1, y: midY))
            path.addLine(to: CGPoint(x: x0 + step / 2, y: midY + amp))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Rendering helper

/// Draws a shape as a stroked glyph at a fixed square size, with a tap target that
/// always exists — a bare shape over a clear background has none.
struct HJGlyph<S: Shape>: View {
    var shape: S
    var size: CGFloat
    var color: Color
    var lineWidth: CGFloat = 1.6
    var filled: Bool = false

    var body: some View {
        Group {
            if filled {
                shape.fill(color)
            } else {
                shape.stroke(color, style: StrokeStyle(lineWidth: lineWidth,
                                                       lineCap: .round,
                                                       lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
    }
}
