//
//  CheckSurveyResponse.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 2/5/18.
//

import UIKit
import ObjectMapper

open class CheckSurveyResponse: BasicResponse {

    open var survey: Survey?
    
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        survey <- map["survey"]
    }
    
    open class Survey: Mappable {
        open var surveyUrl: String?
        open var isFilledUp: Bool?
        
        ///
        public init() {
            
        }
        
        ///
        required public init?(map: Map) {
            
        }
        
        ///
        open func mapping(map: Map) {
            surveyUrl <- map["survey_url"]
            isFilledUp <- map["is_filled_up"]
        }
    }
}
