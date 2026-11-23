import SwiftUI

// MARK: - Estrellas con bisel (diseño F)
// Tres estrellas juntas abajo de la tarjeta de nivel, la de en medio más grande y más
// arriba. Doradas con bisel y borde café oscuro; las que faltan se ven apagadas.
// Todo está dibujado con formas de SwiftUI: no hacen falta imágenes.

/// Puntos de la estrella en un cuadro de 1x1 (mismos números que el diseño: caja de 120).
private enum StarGeo {
    static let center = CGPoint(x: 0.5, y: 0.55)
    static let outerR: CGFloat = 46.0 / 120.0
    static let innerR: CGFloat = 22.0 / 120.0

    private static func point(radius: CGFloat, degrees: Double) -> CGPoint {
        let a = degrees * .pi / 180
        return CGPoint(x: center.x + radius * CGFloat(cos(a)),
                       y: center.y + radius * CGFloat(sin(a)))
    }

    /// Punta k (0 = la de arriba), de 0 a 4.
    static func tip(_ k: Int) -> CGPoint {
        point(radius: outerR, degrees: -90 + 72 * Double(((k % 5) + 5) % 5))
    }

    /// Esquina de adentro k: la que queda a la derecha de la punta k.
    static func inner(_ k: Int) -> CGPoint {
        point(radius: innerR, degrees: -90 + 36 + 72 * Double(((k % 5) + 5) % 5))
    }
}

private func scaled(_ p: CGPoint, in rect: CGRect) -> CGPoint {
    CGPoint(x: rect.minX + p.x * rect.width, y: rect.minY + p.y * rect.height)
}

/// Contorno completo de la estrella.
private struct StarOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for k in 0..<5 {
            let tip = scaled(StarGeo.tip(k), in: rect)
            let inner = scaled(StarGeo.inner(k), in: rect)
            if k == 0 { path.move(to: tip) } else { path.addLine(to: tip) }
            path.addLine(to: inner)
        }
        path.closeSubpath()
        return path
    }
}

/// Una de las 10 caras del bisel: triángulo punta k – esquina – centro.
private struct StarFacet: Shape {
    let tip: Int
    let right: Bool   // true = mitad derecha (más oscura), false = mitad izquierda (más clara)

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inner = right ? StarGeo.inner(tip) : StarGeo.inner(tip - 1)
        path.move(to: scaled(StarGeo.tip(tip), in: rect))
        path.addLine(to: scaled(inner, in: rect))
        path.addLine(to: scaled(StarGeo.center, in: rect))
        path.closeSubpath()
        return path
    }
}

private enum StarColors {
    static let outline   = Color(hex: "5A2A10")
    static let light     = Color(hex: "FFE46B")
    static let dark      = Color(hex: "F2A200")
    static let rim       = Color(hex: "FFF3A8")
    static let emptyFill = Color(hex: "3A1E0E")
    static let emptyEdge = Color(hex: "2A1236")
    static let emptyRim  = Color(hex: "B79AD0")
    static let shadow    = Color(hex: "1E0A28")
}

/// Una estrella con bisel, llena (ganada) o apagada (falta).
struct BevelStar: View {
    let filled: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            if filled { fullStar } else { emptyStar }
        }
        .frame(width: size, height: size)
        .shadow(color: StarColors.shadow.opacity(0.45), radius: 0, x: 0, y: size * 0.025)
    }

    private var fullStar: some View {
        ZStack {
            // Borde café oscuro, grueso
            StarOutline().fill(StarColors.outline)
            StarOutline().stroke(StarColors.outline,
                                 style: StrokeStyle(lineWidth: size * 0.125, lineJoin: .round))
            // Caras del bisel: izquierda clara, derecha oscura
            ForEach(0..<5, id: \.self) { k in
                StarFacet(tip: k, right: false)
                    .fill(StarColors.light)
                    .overlay(StarFacet(tip: k, right: false)
                        .stroke(StarColors.light, style: StrokeStyle(lineWidth: size * 0.012, lineJoin: .round)))
                StarFacet(tip: k, right: true)
                    .fill(StarColors.dark)
                    .overlay(StarFacet(tip: k, right: true)
                        .stroke(StarColors.dark, style: StrokeStyle(lineWidth: size * 0.012, lineJoin: .round)))
            }
            // Filo claro por adentro del borde
            StarOutline()
                .stroke(StarColors.rim.opacity(0.9),
                        style: StrokeStyle(lineWidth: size * 0.02, lineJoin: .round))
                .scaleEffect(0.93, anchor: UnitPoint(x: 0.5, y: 0.55))
            // Brillo
            Ellipse()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 10 / 120, height: size * 6 / 120)
                .rotationEffect(.degrees(-35))
                .position(x: size * 51 / 120, y: size * 48 / 120)
        }
    }

    private var emptyStar: some View {
        ZStack {
            StarOutline().fill(StarColors.emptyFill.opacity(0.55))
            StarOutline().stroke(StarColors.emptyEdge.opacity(0.85),
                                 style: StrokeStyle(lineWidth: size * 0.1, lineJoin: .round))
            StarOutline().stroke(StarColors.emptyRim.opacity(0.7),
                                 style: StrokeStyle(lineWidth: size * 0.025, lineJoin: .round))
        }
    }
}

/// Las tres estrellas de una tarjeta, en arco. Todo se calcula con el lado de la tarjeta (s).
struct LevelStarsArc: View {
    let earned: Int
    let cardSize: CGFloat

    /// Cuánto sobresalen las estrellas por abajo de la tarjeta (como fracción del lado),
    /// para que la cuadrícula deje ese espacio entre filas.
    static let overhangRatio: CGFloat = 0.15
    /// Cuánto se baja la caja de las estrellas respecto al borde de abajo de la tarjeta.
    static let boxDrop: CGFloat = 0.1625

    var body: some View {
        let s = cardSize
        HStack(alignment: .bottom, spacing: -s * 0.05) {
            BevelStar(filled: earned >= 1, size: s * 0.35)
            BevelStar(filled: earned >= 2, size: s * 0.425)
                .offset(y: -s * 0.025)
            BevelStar(filled: earned >= 3, size: s * 0.35)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(earned) / 3")
    }
}
