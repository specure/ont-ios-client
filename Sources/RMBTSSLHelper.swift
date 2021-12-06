//
//  RMBTSSLHelper.swift
//  RMBT
//
//  Created by Benjamin Pucher on 27.03.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class RMBTSSLHelper {

    ///
    fileprivate init() {

    }

    ///
    class func encryptionStringForSSLContext(_ sslContext: SSLContext) -> String {
        return "\(encryptionProtocolStringForSSLContext(sslContext)) (\(encryptionCipherStringForSSLContext(sslContext)))"
    }

    ///
    class func encryptionProtocolStringForSSLContext(_ sslContext: SSLContext) -> String {
        var sslProtocol: SSLProtocol = .sslProtocolUnknown
        SSLGetNegotiatedProtocolVersion(sslContext, &sslProtocol)

        switch sslProtocol {
            case .sslProtocolUnknown: return "No Protocol"
            case .sslProtocol2:       return "SSLv2"
            case .sslProtocol3:       return "SSLv3"
            case .sslProtocol3Only:   return "SSLv3 Only"
            case .tlsProtocol1:       return "TLSv1"
            case .tlsProtocol11:      return "TLSv1.1"
            case .tlsProtocol12:      return "TLSv1.2"
            default:                  return "other protocol: \(sslProtocol)"
        }
    }

    ///
    class func encryptionCipherStringForSSLContext(_ sslContext: SSLContext) -> String {
        var cipher = SSLCipherSuite()
        SSLGetNegotiatedCipher(sslContext, &cipher)

        switch cipher {
            case SSL_RSA_WITH_RC4_128_MD5:    return "SSL_RSA_WITH_RC4_128_MD5"
            case SSL_NO_SUCH_CIPHERSUITE:     return "No Cipher"
            default:                          return String(format: "%X", cipher)
        }
    }
}
