//
//  NSString+IPAddress.h
//  RMBT
//
//  Created by Benjamin Pucher on 06.02.15.
//  Copyright (c) 2015 Specure GmbH. All rights reserved.
//

#include <Foundation/Foundation.h>

@interface NSString (IPAddress)

-(BOOL)isValidIPAddress;

-(BOOL)isValidIPv4;
-(BOOL)isValidIPv6;

-(NSData *)convertIPToNSData;

@end