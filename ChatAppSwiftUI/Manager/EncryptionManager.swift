//
//  EncryptionManager.swift
//  NFC Encrypted Flow
//
//  Created by Karan on 20/07/24.
//

import Foundation
import CryptoKit

class EncryptionManager {
    
    // Generate a new Ed25519 public-private key pair
    func generateKeyPair() throws -> (publicKey: Curve25519.Signing.PublicKey, privateKey: Curve25519.Signing.PrivateKey) {
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        return (publicKey, privateKey)
    }
    
    // Generate a shared secret from the recipient's public key and sender's private key
    func sharedSecret(recipientPublicKey: Curve25519.KeyAgreement.PublicKey, senderPrivateKey: Curve25519.KeyAgreement.PrivateKey) throws -> SymmetricKey {
        let sharedSecret = try senderPrivateKey.sharedSecretFromKeyAgreement(with: recipientPublicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: "My Key Agreement Salt".data(using: .utf8)!,
            sharedInfo: Data(),
            outputByteCount: 32
        )
        return symmetricKey
    }
    
    // Encrypt a message using the shared secret
    func encrypt(_ message: String, using sharedSecret: SymmetricKey) throws -> Data {
        let messageData = message.data(using: .utf8)!
        let sealedBox = try ChaChaPoly.seal(messageData, using: sharedSecret)
        return sealedBox.combined
    }
    
    // Decrypt an encrypted message using the shared secret
    func decrypt(_ encryptedMessage: Data, using sharedSecret: SymmetricKey) throws -> String {
        let sealedBox = try ChaChaPoly.SealedBox(combined: encryptedMessage)
        let decryptedData = try ChaChaPoly.open(sealedBox, using: sharedSecret)
        guard let decryptedMessage = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        return decryptedMessage
    }
    
    
    enum EncryptionError: Error {
        case decryptionFailed
    }
}
