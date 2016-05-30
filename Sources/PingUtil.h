//
//  PingUtil.h
//  RMBT
//
//  Created by Benjamin Pucher on 06.02.15.
//  Copyright (c) 2015 Specure GmbH. All rights reserved.
//

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

check_compile_time(sizeof(IPHeader) == 20);
check_compile_time(offsetof(IPHeader, versionAndHeaderLength) == 0);
check_compile_time(offsetof(IPHeader, differentiatedServices) == 1);
check_compile_time(offsetof(IPHeader, totalLength) == 2);
check_compile_time(offsetof(IPHeader, identification) == 4);
check_compile_time(offsetof(IPHeader, flagsAndFragmentOffset) == 6);
check_compile_time(offsetof(IPHeader, timeToLive) == 8);
check_compile_time(offsetof(IPHeader, protocol) == 9);
check_compile_time(offsetof(IPHeader, headerChecksum) == 10);
check_compile_time(offsetof(IPHeader, sourceAddress) == 12);
check_compile_time(offsetof(IPHeader, destinationAddress) == 16);

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

check_compile_time(sizeof(ICMPHeader) == 8);
check_compile_time(offsetof(ICMPHeader, type) == 0);
check_compile_time(offsetof(ICMPHeader, code) == 1);
check_compile_time(offsetof(ICMPHeader, checksum) == 2);
check_compile_time(offsetof(ICMPHeader, identifier) == 4);
check_compile_time(offsetof(ICMPHeader, sequenceNumber) == 6);

