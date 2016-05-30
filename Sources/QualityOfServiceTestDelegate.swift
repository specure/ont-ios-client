//
//  QualityOfServiceTestDelegate.swift
//  RMBT
//
//  Created by Benjamin Pucher on 16.01.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
protocol QualityOfServiceTestDelegate {

    ///
    func qualityOfServiceTestDidStart(test: QualityOfServiceTest)

    ///
    func qualityOfServiceTestDidStop(test: QualityOfServiceTest)

    ///
    func qualityOfServiceTest(test: QualityOfServiceTest, didFinishWithResults results: [QOSTestResult])

    ///
    func qualityOfServiceTest(test: QualityOfServiceTest, didFailWithError: NSError!)

    ///
    func qualityOfServiceTest(test: QualityOfServiceTest, didFetchTestTypes testTypes: [QOSTestType])

    ///
    func qualityOfServiceTest(test: QualityOfServiceTest, didFinishTestType testType: QOSTestType)

    ///
    func qualityOfServiceTest(test: QualityOfServiceTest, didProgressToValue progress: Float)
}
