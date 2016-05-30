//
//  LogConfig.swift
//  RMBT
//
//  Created by Benjamin Pucher on 03.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation
import XCGLogger

///
let logger = XCGLogger.defaultInstance()

///
class LogConfig {

    // TODO:
    // *) set log level in app

    ///
    static let fileDateFormatter = NSDateFormatter()
    static let startedAt = NSDate()

    /// setup logging system
    class func initLoggingFramework() {
        setupFileDateFormatter()

        let logFilePath = getCurrentLogFilePath()

        #if RELEASE
            // Release config
            // 1 logfile per day
            logger.setup(.Info, showLogLevel: true, showFileNames: false, showLineNumbers: true, writeToFile: logFilePath) /* .Error */
        #elseif DEBUG
            // Debug config
            logger.setup(.Verbose, showLogLevel: true, showFileNames: false, showLineNumbers: true, writeToFile: nil) // don't need log to file
        #elseif BETA
            // Beta config
            logger.setup(.Debug, showLogLevel: true, showFileNames: false, showLineNumbers: true, writeToFile: logFilePath)

            uploadOldLogs()
        #endif
    }

    ///
    private class func setupFileDateFormatter() {
/*        let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier ?? "rmbt"
        let uuid = ControlServer.sharedControlServer.uuid ?? "uuid_missing"

        #if RELEASE
            fileDateFormatter.dateFormat = "'\(bundleIdentifier)_\(uuid)_'yyyy_MM_dd'.log'"
        #else
            fileDateFormatter.dateFormat = "'\(bundleIdentifier)_\(uuid)_'yyyy_MM_dd_HH_mm_ss'.log'"
        #endif
*/    }

    ///
    class func getCurrentLogFilePath() -> String {
        return getLogFolderPath() + "/" + getCurrentLogFileName()
    }

    ///
    class func getCurrentLogFileName() -> String {
        return fileDateFormatter.stringFromDate(startedAt)
    }

    ///
    class func getLogFolderPath() -> String {
        let cacheDirectory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
        let logDirectory = cacheDirectory + "/logs"

        // try to create logs directory if it doesn't exist yet
        if !NSFileManager.defaultManager().fileExistsAtPath(logDirectory) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(logDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                // TODO
            }
        }

        return logDirectory
    }
/*
    ///
    private class func uploadOldLogs() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {

            let logFolderPath = self.getLogFolderPath()
            let currentLogFile = self.getCurrentLogFileName()

            // get file list
            do {
                if let fileList: [String] = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(logFolderPath) {

                    logger.debugExec {
                        logger.debug("LOG: log files in folder")
                        logger.debug("LOG: \(fileList)")
                    }

                    // iterate over all log files
                    for file in fileList {
                        if file == currentLogFile {
                            logger.debug("LOG: not submitting log file \(file) because it is the current log file")
                            continue // skip current log file
                        }

                        let absoluteFile = (logFolderPath as NSString).stringByAppendingPathComponent(file)

                        logger.debug("LOG: checking if file should be submitted (\(file))")

                        let fileAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(absoluteFile)

                        let createdDate = fileAttributes[NSFileCreationDate] as! NSDate
                        let modifiedDate = fileAttributes[NSFileModificationDate] as! NSDate
                        logger.debug("LOG: compared dates of file: \(modifiedDate) to current: \(startedAt)")
                        if modifiedDate < startedAt {

                            logger.debug("LOG: found log to submit: \(file), last edited at: \(modifiedDate)")

                            let content = try String(contentsOfFile: absoluteFile, encoding: NSUTF8StringEncoding)

                            let logFileJson: [String:AnyObject] = [
                                "logfile": file,
                                "content": content,
                                "file_times": [
                                    "last_modified": modifiedDate.timeIntervalSince1970,
                                    "created": createdDate.timeIntervalSince1970,
                                    "last_access": modifiedDate.timeIntervalSince1970 // TODO
                                ]
                            ]

                            ControlServer.sharedControlServer.submitLogFile(logFileJson, success: {

                                logger.debug("LOG: deleting log file \(file)")

                                // delete old log file
                                do {
                                    try NSFileManager.defaultManager().removeItemAtPath(absoluteFile)
                                } catch {
                                    // do nothing
                                }

                                return

                            }, error: { error, info in
                                // do nothing
                            })
                        } else {
                            logger.debug("LOG: not submitting log file \(file) because it is the current log file")
                        }
                    }
                }
            } catch {
                // do nothing
            }
        }
    }
*/
}

// TODO: move to other file...
extension NSDate: Comparable {}

///
/* public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.timeIntervalSince1970 == rhs.timeIntervalSince1970
} */

///
public func < (lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.timeIntervalSince1970 < rhs.timeIntervalSince1970
}
