//
//  NSString+GetDNSIP.h
//  DNSTest
//
//  Created by Benjamin Pucher on 08.03.15.
//  Copyright (c) 2015 Benjamin Pucher. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <arpa/inet.h>

@interface GetDNSIP : NSObject

+(NSString *)getdnsip;
+(NSDictionary *)getdnsIPandPort;

@end