import Foundation
import CryptoKit

enum UUIDGenerator {
    static func generate(seed: String) -> String {
        let data = Data(seed.utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.prefix(12).map { String(format: "%02X", $0) }.joined()
    }
}
