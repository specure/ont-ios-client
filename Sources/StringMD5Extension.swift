/*****************************************************************************************************
 * Copyright 2014-2016 SPECURE GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************************************/

import Foundation
import CommonCrypto
#if swift(>=3.2)
    import Darwin
//    import CommonCrypto
#else
    import RMBTClientPrivate
#endif

///
//extension Int {
//
//    func hexString() -> String {
//        return String(format: "%02x", self)
//    }
//
//}

///
extension Data {

    func hexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }

    func MD5() -> Data {
        var result = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        _ = result.withUnsafeMutableBytes {resultPtr in
            self.withUnsafeBytes {(bytes: UnsafePointer<UInt8>) in
                CC_MD5(bytes, CC_LONG(count), resultPtr)
            }
        }
        return result
    }

    func SHA1() -> Data {
//        let result = NSMutableData(length: Int(CC_SHA1_DIGEST_LENGTH))!
//        CC_SHA1(bytes, CC_LONG(count), UnsafeMutablePointer<UInt8>(result.mutableBytes))
//        return (NSData(data: result as Data) as Data)
        //
        var result = Data(count: Int(CC_SHA1_DIGEST_LENGTH))
        _ = result.withUnsafeMutableBytes {resultPtr in
            self.withUnsafeBytes {(bytes: UnsafePointer<UInt8>) in
                CC_MD5(bytes, CC_LONG(count), resultPtr)
            }
        }
        return result
    }
}
