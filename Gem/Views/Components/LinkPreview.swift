import SwiftUI
import LinkPresentation
import UniformTypeIdentifiers

struct LinkPreview: View {
    let url: URL
    let title: String
    @State var isSafariSheetPresented: Bool = false
    @State var summary: String = ""
    @State var imageUrl: URL?
    @State var iconImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let iconImage {
                    Image(uiImage: iconImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                if let host = url.host() {
                    Text(host)
                        .foregroundStyle(.foreground.opacity(0.7))
                        .font(.caption)
                }
            }
            .padding([.horizontal, .top])
            HStack {
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .font(.system(.title3, design: .serif))
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .if(summary.isEmpty) { view in
                view
                    .padding(.bottom)
            }
            if summary.isNotEmpty {
                Text(summary)
                    .padding(.bottom)
                    .padding(.horizontal, 12)
                    .font(.system(.subheadline))
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contextMenu(
            menuItems: {
                Button {
                    isSafariSheetPresented = true
                } label: {
                    Label("View in Safari", systemImage: "safari")
                }
            },
            preview: {
                SafariView(url: url)
            }
        )
        .padding(.horizontal, 6)
        .sheet(isPresented: $isSafariSheetPresented) {
            SafariView(url: url, draggable: true)
        }
        .task(priority: .background) {
            let provider = LPMetadataProvider()
            
            try? await Task.sleep(until: .now + .milliseconds(200))
            let metadata = try? await provider.startFetchingMetadata(for: url)
            if let metadata = metadata {
                metadata.title = title
                let summary = metadata.value(forKey: "summary") as? String
                _ = metadata.iconProvider?.loadDataRepresentation(for: .image) { imageData, error in
                    if let imageData = imageData {
                        // We now have access to the URL's icon by using NSItemProvider to load the image object
                        let iconUiImage = UIImage(data: imageData)
                        DispatchQueue.main.async {
                            withAnimation(.snappy.speed(200)) {
                                self.iconImage = iconUiImage
                            }
                        }
                    }
                }
                withAnimation(.snappy.speed(200)) {
                    self.summary = summary.orEmpty
                }
            }
        }
    }
}
