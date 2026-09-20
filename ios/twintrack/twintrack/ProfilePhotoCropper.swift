import ImageIO
import SwiftUI
import UIKit

nonisolated enum ProfilePhotoCropper {
    static let outputDimension: CGFloat = 768
    static let maximumZoom: CGFloat = 5
    static let sourceMaximumDimension = 1_600

    /// Creates the only editable source TwinTrack stores: orientation-normalized,
    /// bounded in size, and re-encoded without the selected asset's metadata.
    static func sanitizedSourceJPEG(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: sourceMaximumDimension,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        // UIKit encodes the transformed pixels into a fresh container without
        // copying the selected asset's EXIF, GPS, or other source dictionaries.
        return UIImage(cgImage: image).jpegData(compressionQuality: 0.86)
    }

    static func minimumScale(imageSize: CGSize, cropSize: CGFloat) -> CGFloat {
        guard imageSize.width > 0, imageSize.height > 0, cropSize > 0 else { return 1 }
        return max(cropSize / imageSize.width, cropSize / imageSize.height)
    }

    static func clampedOffset(
        _ offset: CGSize,
        imageSize: CGSize,
        cropSize: CGFloat,
        zoom: CGFloat
    ) -> CGSize {
        let safeZoom = min(max(zoom, 1), maximumZoom)
        let scale = minimumScale(imageSize: imageSize, cropSize: cropSize) * safeZoom
        let maximumX = max(0, (imageSize.width * scale - cropSize) / 2)
        let maximumY = max(0, (imageSize.height * scale - cropSize) / 2)
        return CGSize(
            width: min(max(offset.width, -maximumX), maximumX),
            height: min(max(offset.height, -maximumY), maximumY)
        )
    }

    static func croppedJPEG(
        from image: UIImage,
        cropSize: CGFloat,
        zoom: CGFloat,
        offset: CGSize
    ) -> Data? {
        guard image.size.width > 0, image.size.height > 0, cropSize > 0 else { return nil }
        let safeZoom = min(max(zoom, 1), maximumZoom)
        let safeOffset = clampedOffset(
            offset,
            imageSize: image.size,
            cropSize: cropSize,
            zoom: safeZoom
        )
        let displayScale = minimumScale(imageSize: image.size, cropSize: cropSize) * safeZoom
        let outputScale = outputDimension / cropSize
        let drawSize = CGSize(
            width: image.size.width * displayScale * outputScale,
            height: image.size.height * displayScale * outputScale
        )
        let drawOrigin = CGPoint(
            x: (outputDimension - drawSize.width) / 2 + safeOffset.width * outputScale,
            y: (outputDimension - drawSize.height) / 2 + safeOffset.height * outputScale
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: outputDimension, height: outputDimension),
            format: format
        )
        let cropped = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: outputDimension, height: outputDimension))
            image.draw(in: CGRect(origin: drawOrigin, size: drawSize))
        }
        // Re-rendering creates a new local image and drops the source container's
        // EXIF/GPS metadata. Only this square JPEG is eligible for persistence.
        return cropped.jpegData(compressionQuality: 0.86)
    }
}

struct ProfilePhotoCropEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @GestureState private var dragTranslation = CGSize.zero
    @GestureState private var magnification: CGFloat = 1
    @State private var zoom: CGFloat = 1
    @State private var offset = CGSize.zero
    @State private var previewCropSize: CGFloat = 1
    @State private var renderFailed = false

    let image: UIImage
    let onSave: (Data) -> Void

    init?(sourceData: Data, onSave: @escaping (Data) -> Void) {
        guard let image = UIImage(data: sourceData), image.size.width > 0, image.size.height > 0 else {
            return nil
        }
        self.image = image
        self.onSave = onSave
    }

    private var background: Color {
        colorScheme == .dark ? Color(red: 7 / 255, green: 11 / 255, blue: 18 / 255) : Color(red: 241 / 255, green: 244 / 255, blue: 248 / 255)
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("Drag to reposition and pinch to zoom.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            GeometryReader { proxy in
                let cropSize = max(1, min(proxy.size.width - 32, proxy.size.height))
                cropPreview(cropSize: cropSize)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { previewCropSize = cropSize }
                    .onChange(of: cropSize) { _, value in previewCropSize = value }
            }
            .frame(minHeight: 280, maxHeight: 430)

            Button("Reset") {
                zoom = 1
                offset = .zero
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("profilePhotoCropReset")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(background.ignoresSafeArea())
        .navigationTitle("Edit Photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .accessibilityIdentifier("profilePhotoCropCancel")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("profilePhotoCropSave")
            }
        }
        .alert("Photo Not Saved", isPresented: $renderFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The crop could not be created. Reset the photo and try again.")
        }
    }

    private func cropPreview(cropSize: CGFloat) -> some View {
        let liveZoom = min(max(zoom * magnification, 1), ProfilePhotoCropper.maximumZoom)
        let proposedOffset = CGSize(
            width: offset.width + dragTranslation.width,
            height: offset.height + dragTranslation.height
        )
        let liveOffset = ProfilePhotoCropper.clampedOffset(
            proposedOffset,
            imageSize: image.size,
            cropSize: cropSize,
            zoom: liveZoom
        )
        let baseScale = ProfilePhotoCropper.minimumScale(imageSize: image.size, cropSize: cropSize)

        return ZStack {
            Color.black
            Image(uiImage: image)
                .resizable()
                .frame(width: image.size.width * baseScale, height: image.size.height * baseScale)
                .scaleEffect(liveZoom)
                .offset(liveOffset)
        }
        .frame(width: cropSize, height: cropSize)
        .clipShape(Circle())
        .overlay { Circle().stroke(.white.opacity(0.9), lineWidth: 2) }
        .shadow(color: .black.opacity(0.22), radius: 12, y: 5)
        .contentShape(Circle())
        .accessibilityIdentifier("profilePhotoCropPreview")
        .gesture(
            DragGesture()
                .updating($dragTranslation) { value, state, _ in state = value.translation }
                .onEnded { value in
                    offset = ProfilePhotoCropper.clampedOffset(
                        CGSize(width: offset.width + value.translation.width,
                               height: offset.height + value.translation.height),
                        imageSize: image.size,
                        cropSize: cropSize,
                        zoom: zoom
                    )
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .updating($magnification) { value, state, _ in state = value }
                .onEnded { value in
                    let updatedZoom = min(max(zoom * value, 1), ProfilePhotoCropper.maximumZoom)
                    zoom = updatedZoom
                    offset = ProfilePhotoCropper.clampedOffset(
                        offset,
                        imageSize: image.size,
                        cropSize: cropSize,
                        zoom: updatedZoom
                    )
                }
        )
    }

    private func save() {
        let cropSize = previewCropSize
        guard let data = ProfilePhotoCropper.croppedJPEG(
            from: image,
            cropSize: cropSize,
            zoom: zoom,
            offset: ProfilePhotoCropper.clampedOffset(
                offset,
                imageSize: image.size,
                cropSize: cropSize,
                zoom: zoom
            )
        ) else {
            renderFailed = true
            return
        }
        onSave(data)
        dismiss()
    }
}
