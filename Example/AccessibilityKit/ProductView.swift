//
//  ProductView.swift
//  Example
//

import SwiftUI

///
/// A realistic product screen that doubles as a test bench for the kit.
///
/// Four accessibility problems are planted on purpose, so every tool has
/// something to find. The Monitor ships today; the other tools named below
/// are planned. Each is marked `Planted issue N` — leave them in when
/// cleaning up. Everything else is built correctly, as the reference for what
/// good looks like.
///
/// | # | Problem | Found by |
/// |---|---------|----------|
/// | 1 | The heart button has no label, so VoiceOver says only "Button" | Audit, Inspect |
/// | 2 | The heart button's target is 32 × 32 pt | Audit, Overlays, Inspect |
/// | 3 | The delivery line's contrast is 2.7:1 (needs 4.5:1) | Audit |
/// | 4 | The size buttons are a fixed 32 × 32 pt, so their numbers clip from about AX2 | Audit, Overlays, Text size |
///
struct ProductView: View {

    @State private var selectedSize = 39
    @State private var isFavourite = false

    private let sizes = [38, 39, 40, 41]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                photo
                    .padding(.bottom, 20)

                details

                sizePicker
                    .padding(.top, 20)

                Text("Light trail shoe with a grippy outsole and a breathable upper, made for long runs on rough ground.")
                    .font(.body)
                    .foregroundStyle(Color.benchText2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 24)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: 672)
            .frame(maxWidth: .infinity)
        }
        .background(Color.benchBg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            addToBag
        }
        .tint(Color.benchText)
    }
}

// MARK: - Sections

private extension ProductView {

    var photo: some View {
        ZStack(alignment: .topTrailing) {
            ShoeDrawing()
                .stroke(Color.benchText2, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                .frame(width: 180, height: 96)
                .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 240)
                .background(Color.benchSheet)
                // Decorative: the name below says what it shows.
                .accessibilityHidden(true)

            // Planted issue 1: the button has no accessibility label, so
            // VoiceOver says only "Button".
            // Planted issue 2: its touch target is 32 × 32 pt, under 44 × 44.
            Button {
                isFavourite.toggle()
            } label: {
                HeartShape()
                    .stroke(Color.benchText, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                    .background(HeartShape().fill(isFavourite ? Color.benchAction : Color.clear))
                    .frame(width: 18, height: 16)
                    .frame(width: 32, height: 32)
                    .background(Color.benchBg)
            }
            .buttonStyle(.plain)
            .padding(12)
        }
    }

    var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Running · Women")
                .font(.caption.weight(.medium))
                .textCase(.uppercase)
                .tracking(0.2)
                .foregroundStyle(Color.benchText2)

            Text("Trail Runner 2")
                .font(.title.bold())
                .foregroundStyle(Color.benchText)
                .accessibilityAddTraits(.isHeader)

            Text("€129")
                .font(.headline.monospacedDigit())
                .foregroundStyle(Color.benchText)
                .padding(.top, 4)

            // Planted issue 3: `benchDisabled` grey on white is 2.7:1, under
            // the 4.5:1 that text this size needs.
            Text("Free returns · Ships in 2 days")
                .font(.footnote)
                .foregroundStyle(Color.benchDisabled)
                .padding(.top, 8)
        }
    }

    var sizePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Size")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.benchText)

            HStack(spacing: 8) {
                ForEach(sizes, id: \.self) { size in
                    let isSelected = size == selectedSize
                    Button {
                        selectedSize = size
                    } label: {
                        // Planted issue 4: a fixed 32 × 32 pt frame. The targets
                        // are too small, and the numbers clip from about AX2.
                        Text("\(size)")
                            .font(.footnote.monospacedDigit())
                            .frame(width: 32, height: 32)
                            .foregroundStyle(isSelected ? Color.benchOnSelected : Color.benchText)
                            .background(isSelected ? Color.benchSelected : Color.clear)
                            .overlay(Rectangle().strokeBorder(isSelected ? Color.benchSelected : Color.benchText2, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Size \(size)")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Size")
        }
    }

    var addToBag: some View {
        Button {
            // Not part of the test bench.
        } label: {
            HStack(spacing: 12) {
                Text("Add to bag")
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .accessibilityHidden(true)
            }
            .font(.body.weight(.medium))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: 672)
        .frame(maxWidth: .infinity)
        .background(Color.benchBg.ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - Styles and drawings

private struct PrimaryButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? Color.benchBg : Color.benchOnAction)
            .background(Capsule().fill(configuration.isPressed ? Color.benchText : Color.benchAction))
            .contentShape(Capsule())
    }
}

/// A line-drawn shoe in a 180 × 96 box.
private struct ShoeDrawing: Shape {

    func path(in rect: CGRect) -> Path {
        let x = rect.width / 180
        let y = rect.height / 96
        func point(_ px: CGFloat, _ py: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + px * x, y: rect.minY + py * y)
        }

        var path = Path()
        path.move(to: point(14, 74))
        path.addLine(to: point(18, 30))
        path.addQuadCurve(to: point(56, 44), control: point(40, 26))
        path.addLine(to: point(74, 54))
        path.addLine(to: point(132, 60))
        path.addQuadCurve(to: point(166, 78), control: point(166, 64))
        path.addLine(to: point(166, 84))
        path.addLine(to: point(14, 84))
        path.closeSubpath()

        path.move(to: point(14, 74))
        path.addLine(to: point(166, 74))
        path.move(to: point(70, 52))
        path.addLine(to: point(62, 62))
        path.move(to: point(82, 55))
        path.addLine(to: point(76, 64))
        return path
    }
}

/// A heart outline in an 18 × 16 box. Drawn, not a symbol, so it carries no
/// automatic label.
private struct HeartShape: Shape {

    func path(in rect: CGRect) -> Path {
        let x = rect.width / 18
        let y = rect.height / 16
        func point(_ px: CGFloat, _ py: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + px * x, y: rect.minY + py * y)
        }

        var path = Path()
        path.move(to: point(9, 15))
        path.addLine(to: point(2.2, 8.4))
        path.addCurve(to: point(9, 3.2), control1: point(-0.6, 5.2), control2: point(5.6, -0.6))
        path.addCurve(to: point(15.8, 8.4), control1: point(12.4, -0.6), control2: point(18.6, 5.2))
        path.closeSubpath()
        return path
    }
}
