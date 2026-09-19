import SwiftUI

/// The app mark.
///
/// This is the supplied artwork (`Art/sonder-mark-source.png`), not a drawing
/// of it. `Tools/render-icon.sh` derives both the 1024px app icon and the
/// 640px in-app asset from that one file, cropping the tile out of its white
/// canvas and filling the rounded corners back in — so the icon on the home
/// screen and the mark on the splash are the same pixels at two sizes and
/// cannot drift apart.
///
/// The asset is square and full-bleed; the rounding happens here.
struct AppMark: View {
    var side: CGFloat

    var body: some View {
        Image(.mark)
            .resizable()
            .interpolation(.high)
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: side * 0.2237, style: .continuous))
    }
}

#Preview {
    VStack(spacing: 24) {
        AppMark(side: 78)
        AppMark(side: 200)
    }
    .padding(40)
    .background(Color.surface)
}
