import UIKit

enum ImageCompressor {
    /// Maximum dimension (width or height) for compressed images
    static let maxDimension: CGFloat = 800

    /// JPEG compression quality (0.0 - 1.0)
    static let compressionQuality: CGFloat = 0.5

    /// Compresses an image by resizing and reducing quality.
    /// Does NOT save to photo library.
    static func compress(_ image: UIImage) -> Data? {
        let resized = resize(image, maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: compressionQuality)
    }

    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let ratio = size.width / size.height
        let newSize: CGSize

        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
