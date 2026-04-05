import SwiftUI

// MARK: - Blob Config

struct BlobConfig: Identifiable {
    let id = UUID()
    var color: Color
    var size: CGFloat
    var blurRadius: CGFloat
    var baseDuration: Double
    var spread: CGFloat
    var pulseScale: CGFloat   // how much it grows/shrinks when pulsing
    var pulseDuration: Double // how fast it pulses
}

extension BlobConfig {
    static func generate(
        count: Int,
        color: Color,
        spread: CGFloat,
        in bounds: CGSize = CGSize(width: 300, height: 600)
    ) -> [BlobConfig] {
        (0..<count).map { i in
            // Give each blob a clearly distinct size tier so they don't all look the same
            let sizeTier = i % 3
            let size: CGFloat
            let blur: CGFloat
            switch sizeTier {
            case 0:
                size = CGFloat.random(in: 280...360)  // large
                blur = CGFloat.random(in: 40...55)
            case 1:
                size = CGFloat.random(in: 160...220)  // medium
                blur = CGFloat.random(in: 20...35)
            default:
                size = CGFloat.random(in: 150...200)  // small — but not too small
                blur = CGFloat.random(in: 25...40)    // still soft, not sharp
            }

            return BlobConfig(
                color: color,
                size: size,
                blurRadius: blur,
                baseDuration: Double.random(in: 2.5...5.5),
                spread: spread,
                pulseScale: CGFloat.random(in: 1.05...1.25),
                pulseDuration: Double.random(in: 3.2...8.8)  // slow, gentle breathing
            )
        }
    }

    func randomOffset(in bounds: CGSize) -> CGSize {
        let actualSpread = spread * CGFloat.random(in: 0.2...1.0)
        let hw = min(bounds.width  * 0.5, actualSpread)
        let hh = min(bounds.height * 0.5, actualSpread)
        return CGSize(
            width:  CGFloat.random(in: -hw...hw),
            height: CGFloat.random(in: -hh...hh)
        )
    }
}

// MARK: - Single Blob

struct AnimatedBlob: View {
    let config: BlobConfig
    let bounds: CGSize

    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Circle()
            .fill(config.color)
            .frame(width: config.size, height: config.size)
            .blur(radius: config.blurRadius)
            .scaleEffect(scale)
            .offset(x: offset.width, y: offset.height)
            .onAppear {
                offset = config.randomOffset(in: bounds)

                // Stagger start so blobs are never in sync
                let delay = Double.random(in: 0...1.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    moveToNext()
                    startPulsing()
                }
            }
    }

    private func moveToNext() {
        let next = config.randomOffset(in: bounds)
        let duration = config.baseDuration + Double.random(in: -1.0...1.0)
        let clamped = max(1.8, duration)
        withAnimation(.easeInOut(duration: clamped)) {
            offset = next
        }
        let pause = Double.random(in: 0.0...0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + clamped + pause) {
            moveToNext()
        }
    }

    private func startPulsing() {
        // Each blob pulses at its own rate independently from movement
        withAnimation(
            .easeInOut(duration: config.pulseDuration)
            .repeatForever(autoreverses: true)
        ) {
            scale = config.pulseScale
        }
    }
}

// MARK: - Blob Field

struct BlobField: View {
    let color: Color
    var count: Int = 4
    var spread: CGFloat = 120
    var fast: Bool = false  // kept for API compatibility

    @State private var blobs: [BlobConfig] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(blobs) { blob in
                    AnimatedBlob(config: blob, bounds: geo.size)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                if blobs.isEmpty {
                    blobs = BlobConfig.generate(count: count, color: color, spread: spread, in: geo.size)
                }
            }
        }
    }
}
