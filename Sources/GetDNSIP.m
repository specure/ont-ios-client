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

#import "GetDNSIP.h"

#include <ifaddrs.h>
#include <resolv.h>
#include <dns.h>

@implementation GetDNSIP

// http://stackoverflow.com/questions/10999612/iphone-get-3g-dns-host-name-and-ip-address

+(NSString *)getdnsip {
    NSString *address;
    
    res_state res = malloc(sizeof(struct __res_state));
    
    int result = res_ninit(res);
    
    if ( result == 0 ) {
        union res_9_sockaddr_union *addr_union = malloc(res->nscount * sizeof(union res_9_sockaddr_union));
        res_getservers(res, addr_union, res->nscount);
        
        for (int i = 0; i < res->nscount; i++) {
            if (addr_union[i].sin.sin_family == AF_INET) {
                char ip[INET_ADDRSTRLEN];
                inet_ntop(AF_INET, &(addr_union[i].sin.sin_addr), ip, INET_ADDRSTRLEN);
                address = [NSString stringWithUTF8String: ip];
                break;
            } else if (addr_union[i].sin6.sin6_family == AF_INET6) {
                char ip[INET6_ADDRSTRLEN];
                inet_ntop(AF_INET6, &(addr_union[i].sin6.sin6_addr), ip, INET6_ADDRSTRLEN);
                address = [NSString stringWithUTF8String: ip];
                break;
            }
        }
        
        free(addr_union);
    }
    
    res_ndestroy(res);
    free(res);
    
    return address;
}

+(NSDictionary *)getdnsIPandPort {
    
    NSString *address;
    uint16_t port = 0;
    
    res_state res = malloc(sizeof(struct __res_state));
    
    int result = res_ninit(res);
    
    if ( result == 0 ) {
        union res_9_sockaddr_union *addr_union = malloc(res->nscount * sizeof(union res_9_sockaddr_union));
        res_getservers(res, addr_union, res->nscount);
        
        for (int i = 0; i < res->nscount; i++) {
            if (addr_union[i].sin.sin_family == AF_INET) {
                char ip[INET_ADDRSTRLEN];
                inet_ntop(AF_INET, &(addr_union[i].sin.sin_addr), ip, INET_ADDRSTRLEN);
                NSString *dnsIP = [NSString stringWithUTF8String: ip];
                port = htons(addr_union[i].sin.sin_port);
                address = dnsIP;
                break;
            } else if (addr_union[i].sin6.sin6_family == AF_INET6) {
                char ip[INET6_ADDRSTRLEN];
                inet_ntop(AF_INET6, &(addr_union[i].sin6.sin6_addr), ip, INET6_ADDRSTRLEN);
                NSString *dnsIP = [NSString stringWithUTF8String: ip];
                port = htons(addr_union[i].sin6.sin6_port);
                address = dnsIP;
                break;
            }
        }
        
        free(addr_union);
    }
    
    res_ndestroy(res);
    free(res);
    
    if (address) {
        return @{
                 @"host": address,
                 @"port": [NSNumber numberWithUnsignedShort: port]
                 };
    } else {
        return nil;
    }
}

@end
