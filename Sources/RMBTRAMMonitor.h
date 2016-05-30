//
//  RMBTRAMMonitor.h
//  RMBT
//
//  Created by Benjamin Pucher on 16.12.14.
//  Copyright (c) 2014 Specure GmbH. All rights reserved.
//

#include <Foundation/Foundation.h>

#import <mach/mach.h>
#import <mach/mach_host.h>

@interface RMBTRAMMonitor : NSObject

- (NSArray *)getRAMUsage;
- (float)getRAMUsagePercentFree;

@end