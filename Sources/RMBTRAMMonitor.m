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

#import "RMBTRAMMonitor.h"

@implementation RMBTRAMMonitor : NSObject

- (NSArray *)getRAMUsage {
    
    // using host_statistics? vm_statistics?
    // see http://stackoverflow.com/questions/5012886/determining-the-available-amount-of-ram-on-an-ios-device/8540665#8540665
    
    // or http://stackoverflow.com/questions/20211650/total-ram-size-of-an-ios-device
    // or http://stackoverflow.com/questions/23935149/ios-application-memory-used
    // or http://stackoverflow.com/questions/5182924/where-is-my-ipad-runtime-memory-going
    // or http://stackoverflow.com/questions/11427761/total-ram-in-iphone
    
    /////////////////////////////////////////
    
    //// App RAM usage
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    
    natural_t mem_used_app = 0;
    if( kerr == KERN_SUCCESS ) {
        //NSLog(@"Memory in use (in bytes): %u", info.resident_size);
        mem_used_app = (natural_t) info.resident_size;
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
    //////////////////////////////////////////////////////
    // mem_total -> [NSProcessInfo processInfo].physicalMemory
    //NSLog(@"total physical memory: %llu", [NSProcessInfo processInfo].physicalMemory);
    
    // iPhone device RAM usage
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
    }
    
    /* Stats in bytes */
    natural_t mem_used = (vm_stat.active_count +
                          vm_stat.inactive_count +
                          vm_stat.wire_count) * (natural_t) pagesize;
    natural_t mem_free = vm_stat.free_count * (natural_t) pagesize;
    natural_t mem_total = mem_used + mem_free;
   // NSLog(@"used: %u free: %u total: %u", mem_used, mem_free, mem_total);
    
    NSArray *array = @[[NSNumber numberWithLongLong: mem_used],
                       [NSNumber numberWithLongLong: mem_free],
                       [NSNumber numberWithLongLong: mem_total],
                       [NSNumber numberWithLongLong: mem_used_app]];
    
    return array;
}

- (float)getRAMUsagePercentFree {
    NSArray *ramUsageArray = [self getRAMUsage];
    
    if (ramUsageArray) {
        float physicalMemory = [NSNumber numberWithUnsignedLongLong: [NSProcessInfo processInfo].physicalMemory].floatValue;
        
        return (((NSNumber *)ramUsageArray[0]).floatValue / physicalMemory) * 100.0;
    } else {
        return 0;
    }
}

@end
