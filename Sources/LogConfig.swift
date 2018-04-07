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
import XCGLogger

///
class LogConfig {

    // TODO:
    // *) set log level in app

    ///
    static let fileDateFormatter = DateFormatter()
    static let startedAt = Date()

    /// setup logging system
    class func initLoggingFramework() {
        setupFileDateFormatter()

        let logFilePath = getCurrentLogFilePath()

        Log.logger.add(destination: ConsoleDestination(identifier: "RMBTClient.log"))
        #if RELEASE
            // Release config
            // 1 logfile per day
            Log.logger.setup(.Info, showLogLevel: true, showFileNames: false, showLineNumbers: true, writeToFile: logFilePath) /* .Error */
        #elseif DEBUG
            // Debug config
            Log.logger.setup(level: .verbose, showLevel: true, showFileNames: false, showLineNumbers: true, writeToFile: nil) // don't need log to file
        #elseif BETA
            // Beta config
            Log.logger.setup(.Debug, showLogLevel: true, showFileNames: false, showLineNumbers: true, writeToFile: logFilePath)

            uploadOldLogs()
        #endif
    }

    ///
    fileprivate class func setupFileDateFormatter() {
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
        return fileDateFormatter.string(from: startedAt)
    }

    ///
    class func getLogFolderPath() -> String {
        let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let logDirectory = cacheDirectory + "/logs"

        // try to create logs directory if it doesn't exist yet
        if !FileManager.default.fileExists(atPath: logDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: logDirectory, withIntermediateDirectories: false, attributes: nil)
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

                    Log.logger.debugExec {
                        Log.logger.debug("LOG: log files in folder")
                        Log.logger.debug("LOG: \(fileList)")
                    }

                    // iterate over all log files
                    for file in fileList {
                        if file == currentLogFile {
                            Log.logger.debug("LOG: not submitting log file \(file) because it is the current log file")
                            continue // skip current log file
                        }

                        let absoluteFile = (logFolderPath as NSString).stringByAppendingPathComponent(file)

                        Log.logger.debug("LOG: checking if file should be submitted (\(file))")

                        let fileAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(absoluteFile)

                        let createdDate = fileAttributes[NSFileCreationDate] as! NSDate
                        let modifiedDate = fileAttributes[NSFileModificationDate] as! NSDate
                        Log.logger.debug("LOG: compared dates of file: \(modifiedDate) to current: \(startedAt)")
                        if modifiedDate < startedAt {

                            Log.logger.debug("LOG: found log to submit: \(file), last edited at: \(modifiedDate)")

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

                                Log.logger.debug("LOG: deleting log file \(file)")

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
                            Log.logger.debug("LOG: not submitting log file \(file) because it is the current log file")
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

