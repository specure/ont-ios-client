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
    private init() {

    }

    ///
    class func encryptionStringForSSLContext(sslContext: SSLContextRef) -> String {
        return "\(encryptionProtocolStringForSSLContext(sslContext)) (\(encryptionCipherStringForSSLContext(sslContext)))"
    }

    ///
    class func encryptionProtocolStringForSSLContext(sslContext: SSLContextRef) -> String {
        var sslProtocol: SSLProtocol = .SSLProtocolUnknown
        SSLGetNegotiatedProtocolVersion(sslContext, &sslProtocol)

        switch sslProtocol {
            case .SSLProtocolUnknown: return "No Protocol"
            case .SSLProtocol2:       return "SSLv2"
            case .SSLProtocol3:       return "SSLv3"
            case .SSLProtocol3Only:   return "SSLv3 Only"
            case .TLSProtocol1:       return "TLSv1"
            case .TLSProtocol11:      return "TLSv1.1"
            case .TLSProtocol12:      return "TLSv1.2"
            default:                  return "other protocol: \(sslProtocol)"
        }
    }

    ///
    class func encryptionCipherStringForSSLContext(sslContext: SSLContextRef) -> String {
        var cipher = SSLCipherSuite()
        SSLGetNegotiatedCipher(sslContext, &cipher)

        switch cipher {
            case SSL_RSA_WITH_RC4_128_MD5:    return "SSL_RSA_WITH_RC4_128_MD5"
            case SSL_NO_SUCH_CIPHERSUITE:     return "No Cipher"
            default:                          return String(format: "%X", cipher)
        }
    }
}
