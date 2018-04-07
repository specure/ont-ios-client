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
    
    /*NSMutableString *addresses = [[NSMutableString alloc]initWithString:@"DNS Addresses \n"];
    
    res_state res = malloc(sizeof(struct __res_state));
    
    int result = res_ninit(res);
    
    if ( result == 0 ) {
        for ( int i = 0; i < res->nscount; i++ ) {
            NSString *s = [NSString stringWithUTF8String :  inet_ntoa(res->nsaddr_list[i].sin_addr)];
            [addresses appendFormat:@"%@\n",s];
            NSLog(@"%@",s);
        }
    } else {
        [addresses appendString:@" res_init result != 0"];
    }
    
    free(res);
     
    return addresses;*/
    
    NSString *address;
    
    res_state res = malloc(sizeof(struct __res_state));
    
    int result = res_ninit(res);
    
    if ( result == 0 ) {
//        for ( int i = 0; i < res->nscount; i++ ) {
        if (res->nscount > 0) {
            address = [NSString stringWithUTF8String: inet_ntoa(res->nsaddr_list[0].sin_addr)];
            NSLog(@"found dns server ip: %@, port: %u", address, htons(res->nsaddr_list[0].sin_port));
        }
//        }
    }/* else {
        
    }*/
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
        //        for ( int i = 0; i < res->nscount; i++ ) {
        if (res->nscount > 0) {
            address = [NSString stringWithUTF8String: inet_ntoa(res->nsaddr_list[0].sin_addr)];
            port = htons(res->nsaddr_list[0].sin_port);
            NSLog(@"found dns server ip: %@, port: %u", address, port);
        }
        //        }
    }/* else {
      
      }*/
    
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
