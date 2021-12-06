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

#import "NSString+IPAddress.h"

#include <arpa/inet.h>

@implementation NSString (IPAddress)

-(BOOL)isValidIPAddress {
    const char *utf8 = [self UTF8String];
    int success;
    
    struct in_addr dst;
    success = inet_pton(AF_INET, utf8, &dst);
    if (success != 1) {
        struct in6_addr dst6;
        success = inet_pton(AF_INET6, utf8, &dst6);
    }
    
    return success == 1;
}

-(BOOL)isValidIPv4 {
    const char *utf8 = [self UTF8String];
    int success;
    
    struct in_addr dst;
    success = inet_pton(AF_INET, utf8, &dst);
    
    return success == 1;
}

-(BOOL)isValidIPv6 {
    const char *utf8 = [self UTF8String];
    int success;

    struct in6_addr dst6;
    success = inet_pton(AF_INET6, utf8, &dst6);
    
    return success == 1;
}

-(NSData *)convertIPToNSData {
    if ([self isValidIPv4]) {
        struct sockaddr_in ip;
        
        memset(&ip, 0, sizeof(ip));
        ip.sin_len = sizeof(ip);
        
        ip.sin_family = AF_INET;
        ip.sin_addr.s_addr = inet_addr([self UTF8String]);
        
        // inet_pton not working on ios 7.1
        //int success = inet_pton(AF_INET, /*[self UTF8String]*/"78.47.110.5", &ip.sin_addr);
        //NSLog(@"inet_pton success: %u", success);

        NSData *data = [NSData dataWithBytes:&ip length:ip.sin_len];
        
        return data;
    }
    
    if ([self isValidIPv6]) {
        struct sockaddr_in6 ip;
        
        memset(&ip, 0, sizeof(ip));
        ip.sin6_len = sizeof(ip);
        
        ip.sin6_family = AF_INET6;
        
        inet_pton(AF_INET6, [self UTF8String], &ip.sin6_addr.s6_addr);
        
        return [NSData dataWithBytes:&ip length:ip.sin6_len];
    }
    
    NSLog(@"returning nil");
    return nil;
}

@end
