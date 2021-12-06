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

#import "NSString+IPAddress.h"

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#include <AssertMacros.h>

@protocol PingUtilDelegate;

/////

@interface PingUtil : NSObject

+(PingUtil * _Nonnull)pingUtilWithHost:(NSString * _Nullable)host; // _Nonnull fixes strange command line build bug

@property(nonatomic, /*weak,*/ nullable, readwrite) id<PingUtilDelegate> delegate;

@property(nonatomic, copy,   nullable, readonly) NSString *host;
@property(nonatomic, copy,   nullable, readonly) NSData *hostAddress;
@property(nonatomic, assign, readonly) uint16_t identifier;
@property(nonatomic, assign, readonly) uint16_t nextSequenceNumber;

-(void)start;
-(void)sendPing:(uint8_t)ttl;

+ (const struct ICMPHeader * _Nullable)icmpInPacket:(NSData * _Nullable)packet;

@end

/////

@protocol PingUtilDelegate <NSObject>

@optional

-(void)pingUtil:(PingUtil * _Nonnull)pingUtil didFailWithError:(NSError * _Nullable)error;

-(void)pingUtil:(PingUtil * _Nonnull)pingUtil didStartWithAddress:(NSData * _Nonnull)address;

-(void)pingUtil:(PingUtil * _Nonnull)pingUtil didSendPacket:(NSData * _Nonnull)packet;

-(void)pingUtil:(PingUtil * _Nonnull)pingUtil didReceivePingResponsePacket:(NSData * _Nonnull)packet withType:(uint8_t)type fromIp:(NSString * _Nonnull)ip;

@end

/////

// IP header structure:

struct IPHeader {
    uint8_t     versionAndHeaderLength;
    uint8_t     differentiatedServices;
    uint16_t    totalLength;
    uint16_t    identification;
    uint16_t    flagsAndFragmentOffset;
    uint8_t     timeToLive;
    uint8_t     protocol;
    uint16_t    headerChecksum;
    uint8_t     sourceAddress[4];
    uint8_t     destinationAddress[4];
    // options...
    // data...
};
typedef struct IPHeader IPHeader;

__Check_Compile_Time(sizeof(IPHeader) == 20);
__Check_Compile_Time(offsetof(IPHeader, versionAndHeaderLength) == 0);
__Check_Compile_Time(offsetof(IPHeader, differentiatedServices) == 1);
__Check_Compile_Time(offsetof(IPHeader, totalLength) == 2);
__Check_Compile_Time(offsetof(IPHeader, identification) == 4);
__Check_Compile_Time(offsetof(IPHeader, flagsAndFragmentOffset) == 6);
__Check_Compile_Time(offsetof(IPHeader, timeToLive) == 8);
__Check_Compile_Time(offsetof(IPHeader, protocol) == 9);
__Check_Compile_Time(offsetof(IPHeader, headerChecksum) == 10);
__Check_Compile_Time(offsetof(IPHeader, sourceAddress) == 12);
__Check_Compile_Time(offsetof(IPHeader, destinationAddress) == 16);

// ICMP type and code combinations:

enum {
    kICMPTypeEchoReply   = 0,           // code is always 0
    kICMPTypeEchoRequest = 8,            // code is always 0
    
    kICMPTypeTTLExceeded = 11, // bp
    kICMPTypeDestinationUnreachable = 3 // bp
};

// ICMP header structure:

struct ICMPHeader {
    uint8_t     type;
    uint8_t     code;
    uint16_t    checksum;
    uint16_t    identifier;
    uint16_t    sequenceNumber;
    // data...
};
typedef struct ICMPHeader ICMPHeader;

__Check_Compile_Time(sizeof(ICMPHeader) == 8);
__Check_Compile_Time(offsetof(ICMPHeader, type) == 0);
__Check_Compile_Time(offsetof(ICMPHeader, code) == 1);
__Check_Compile_Time(offsetof(ICMPHeader, checksum) == 2);
__Check_Compile_Time(offsetof(ICMPHeader, identifier) == 4);
__Check_Compile_Time(offsetof(ICMPHeader, sequenceNumber) == 6);

