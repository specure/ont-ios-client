//
//  RMBTTrafficCounter.h
//  RMBT
//
//  Created by Benjamin Pucher on 16.12.14.
//  Copyright (c) 2014 Specure GmbH. All rights reserved.
//

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