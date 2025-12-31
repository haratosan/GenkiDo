import Foundation
import CloudKit

/// CloudKit service for managing iCloud sync status and operations.
/// Note: SwiftData handles automatic sync via cloudKitDatabase configuration.
final class CloudKitService: Sendable {
    static let shared = CloudKitService()

    private let container: CKContainer

    private init() {
        self.container = CKContainer(identifier: "iCloud.ch.budo-team.GenkiDo")
    }

    func checkAccountStatus() async throws -> CKAccountStatus {
        try await container.accountStatus()
    }

    var isSignedIn: Bool {
        get async {
            do {
                let status = try await checkAccountStatus()
                return status == .available
            } catch {
                return false
            }
        }
    }
}
