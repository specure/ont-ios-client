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

#import "RMBTTrafficCounter.h"

#include <ifaddrs.h>
#include <net/if_dl.h>

@implementation RMBTTrafficCounter : NSObject

- (NSDictionary *)getTrafficCount {
    
    // see http://stackoverflow.com/questions/7946699/iphone-data-usage-tracking-monitoring/8014012#8014012
    
    BOOL   success;
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    const struct if_data *networkStatisc;
    
    int WiFiSent = 0;
    int WiFiReceived = 0;
    int WWANSent = 0;
    int WWANReceived = 0;
    
    NSString *name= [[NSString alloc] init];
    
    success = getifaddrs(&addrs) == 0;
    if (success)
    {
        cursor = addrs;
        while (cursor != NULL)
        {
            name = [NSString stringWithFormat:@"%s",cursor->ifa_name];
            //NSLog(@"ifa_name %s == %@\n", cursor->ifa_name,name);
            // names of interfaces: en0 is WiFi ,pdp_ip0 is WWAN
            
            if (cursor->ifa_addr->sa_family == AF_LINK)
            {
                // there are other interfaces as well...
                if ([name hasPrefix:@"en"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WiFiSent += networkStatisc->ifi_obytes;
                    WiFiReceived += networkStatisc->ifi_ibytes;
                    //NSLog(@"WiFiSent %d ==%d",WiFiSent,networkStatisc->ifi_obytes);
                    //NSLog(@"WiFiReceived %d ==%d",WiFiReceived,networkStatisc->ifi_ibytes);
                }
                
                if ([name hasPrefix:@"pdp_ip"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WWANSent += networkStatisc->ifi_obytes;
                    WWANReceived += networkStatisc->ifi_ibytes;
                    //NSLog(@"WWANSent %d ==%d",WWANSent,networkStatisc->ifi_obytes);
                    //NSLog(@"WWANReceived %d ==%d",WWANReceived,networkStatisc->ifi_ibytes);
                }
            }
            
            cursor = cursor->ifa_next;
        }
        
        freeifaddrs(addrs);
    }
    
    if (WiFiSent < 0)       WiFiSent = 0;
    if (WiFiReceived < 0)   WiFiReceived = 0;
    if (WWANSent < 0)       WWANSent = 0;
    if (WWANReceived < 0)   WWANReceived = 0;
    
    /*if (WiFiSent < 0 || WiFiReceived < 0 || WWANSent < 0 || WWANReceived < 0) {
        return nil;
    }*/
    
    NSDictionary *dict = @{
        @"wifi_sent": [NSNumber numberWithInt:WiFiSent],
        @"wifi_received": [NSNumber numberWithInt:WiFiReceived],
        @"wwan_sent": [NSNumber numberWithInt:WWANSent],
        @"wwan_received": [NSNumber numberWithInt:WWANReceived]
    };
    
    return dict;
}

- (NSDictionary *)getTrafficCount:(NSString *)interfaceName {
    
    int interfaceSent = 0;
    int interfaceReceived = 0;
    
    BOOL success;
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    const struct if_data *networkStat;
    
    success = getifaddrs(&addrs) == 0;
    if (success)
    {
        NSString *name= [[NSString alloc] init];
        
        cursor = addrs;
        while (cursor != NULL)
        {
            name = [NSString stringWithFormat:@"%s",cursor->ifa_name];
            
            if (cursor->ifa_addr->sa_family == AF_LINK)
            {
                if ([name hasPrefix: interfaceName])
                {
                    networkStat = (const struct if_data *) cursor->ifa_data;
                    interfaceSent += networkStat->ifi_obytes;
                    interfaceReceived += networkStat->ifi_ibytes;
                }
            }
            
            cursor = cursor->ifa_next;
        }
        
        freeifaddrs(addrs);
    }
    
    NSDictionary *dict = @{
        @"sent": [NSNumber numberWithInt: interfaceSent],
        @"received": [NSNumber numberWithInt: interfaceReceived]
    };
    
    return dict;
}

#pragma mark - Interface values

+ (RMBTConnectivityInterfaceInfo)getInterfaceInfo:(long)networkType {
    RMBTConnectivityInterfaceInfo result = {0,0};
    
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    const struct if_data *stats;
    
    if (getifaddrs(&addrs) == 0) {
        cursor = addrs;
        while (cursor != NULL) {
            NSString *name=[NSString stringWithCString:cursor->ifa_name encoding:NSASCIIStringEncoding];
            // en0 is WiFi, pdp_ip0 is WWAN
            if (cursor->ifa_addr->sa_family == AF_LINK && (
                                                           ([name hasPrefix:@"en"] && networkType == /*(long)RMBTNetworkTypeWiFi*/99) ||
                                                           ([name hasPrefix:@"pdp_ip"] && networkType == /*(long)RMBTNetworkTypeCellular*/105)
                                                           )) {
                stats = (const struct if_data *) cursor->ifa_data;
                result.bytesSent += stats->ifi_obytes;
                result.bytesReceived += stats->ifi_ibytes;
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return result;
}

@end
