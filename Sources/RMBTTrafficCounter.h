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

#import <Foundation/Foundation.h>

#include <arpa/inet.h>
#include <net/if.h>

typedef struct {
    uint32_t bytesReceived;
    uint32_t bytesSent;
} RMBTConnectivityInterfaceInfo;

@interface RMBTTrafficCounter : NSObject

- (NSDictionary *)getTrafficCount;
- (NSDictionary *)getTrafficCount:(NSString *)interfaceName;

+ (RMBTConnectivityInterfaceInfo)getInterfaceInfo:(long)networkType;

@end
