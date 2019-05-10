/*****************************************************************************************************
 * Copyright 2016 SPECURE GmbH
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
import ObjectMapper

///
open class OperatorsResponse: BasicResponse {

    open class Operator: NSObject, Mappable {
        
        open var isDefault = false
        open var title: String = ""
        open var subtitle: String = ""
        open var idProvider: Int?
        open var provider: String?
        
        open var providerForRequest: String {
            if let idProvider = self.idProvider {
                return String(format: "%d", idProvider)
            } else if let provider = provider {
                return provider
            }
            return ""
        }
        
        public required init?(map: Map) {
            
        }
        
        open func mapping(map: Map) {
            isDefault <- map["default"]
            idProvider <- map["id_provider"]
            provider <- map["provider"]
            title <- map["title"]
            subtitle <- map["detail"]
        }
    }
    ///
    open var operators: [OperatorsResponse.Operator]?

    open var title: String = ""
    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)

        operators <- map["options"]
        title <- map["title"]
    }
}
