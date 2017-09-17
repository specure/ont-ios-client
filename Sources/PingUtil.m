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

#import "PingUtil.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

@interface PingUtil ()

@property(nonatomic, copy, readwrite) NSData *hostAddress;
@property(nonatomic, assign, readwrite) uint16_t nextSequenceNumber;

-(void)readData;

-(void)closeSocket;

-(void)failWithError:(NSError *)error;

@end

////

@implementation PingUtil {
    CFHostRef _host;
    CFSocketRef _socket;
}

@synthesize host = _hostIP;
@synthesize hostAddress = _hostAddress;
@synthesize identifier = _identifier;
@synthesize nextSequenceNumber = _nextSequenceNumber;

-(id)initWithHost:(NSString *)host {
    self = [super init];
    if (self != nil) {
        
        self->_hostIP = [host copy];
        self->_identifier = (uint16_t) arc4random();
        self->_nextSequenceNumber = 1;
        
        if ([self->_hostIP isValidIPAddress]) {
            self->_hostAddress = [self->_hostIP convertIPToNSData];
        } else {
            self = nil; // fail
        }
    }
    
    return self;
}

-(void)dealloc {
    [self closeSocket];
    
    assert(self->_host == NULL);
    assert(self->_socket == NULL);
    
    //self.hostName = nil;
    self.hostAddress = NULL;
}

////////

+(PingUtil * _Nonnull)pingUtilWithHost:(NSString *)host { // _Nonnull fixes strange command line build bug
    return [[PingUtil alloc] initWithHost:host];
}

////////

-(void)sendPing:(uint8_t)ttl {
    
    ICMPHeader *icmpPtr;
    
    NSData *payload = [[NSString stringWithFormat:@"%28zd bottles of beer on the wall", (ssize_t) 99 - (size_t) (self.nextSequenceNumber % 100) ] dataUsingEncoding:NSASCIIStringEncoding];
    assert([payload length] == 56);
    
    NSMutableData * packet;
    packet = [NSMutableData dataWithLength:sizeof(*icmpPtr) + [payload length]];
    assert(packet != nil);
    
    icmpPtr = [packet mutableBytes];
    icmpPtr->type = kICMPTypeEchoRequest;
    icmpPtr->code = 0;
    icmpPtr->checksum = 0;
    icmpPtr->identifier     = OSSwapHostToBigInt16(self.identifier);
    icmpPtr->sequenceNumber = OSSwapHostToBigInt16(self.nextSequenceNumber);
    
    memcpy(&icmpPtr[1], [payload bytes], [payload length]);
    
    icmpPtr->checksum = in_cksum([packet bytes], [packet length]);
    
    int err = 0;
    ssize_t bytesSent;
    
    if (self->_socket == NULL) {
        bytesSent = -1;
        err = EBADF;
    } else {
        ////////////////// SET TTL (http://stackoverflow.com/questions/7437643/ios-ping-with-timeout/7444627#7444627)
        CFSocketNativeHandle sock = CFSocketGetNative(self->_socket);
        struct timeval tv;
        tv.tv_sec  = 0;
        tv.tv_usec = 100000; // 0.1 sec
        setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, (void *)&tv, sizeof(tv));
        
        socklen_t s_ttl = ttl;
        setsockopt(sock, IPPROTO_IP, IP_TTL, &s_ttl, sizeof(s_ttl));
        
//        NSLog(@"!! setting ttl to %u !!", ttl);
        ////////////////// SET TTL
        
        bytesSent = sendto(sock, [packet bytes], [packet length], 0, (struct sockaddr *) [self.hostAddress bytes], (socklen_t) [self.hostAddress length]);

        if (bytesSent < 0) {
            err = errno;
        }
    }
    
    if ((bytesSent > 0) && (((NSUInteger) bytesSent) == [packet length])) {
        
        // Complete success.  Tell the client.
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(pingUtil:didSendPacket:)] ) {
            [self.delegate pingUtil:self didSendPacket:packet];
        }
    } else {
        NSError *   error;
        
        // Some sort of failure.  Tell the client.
        
        if (err == 0) {
            err = ENOBUFS;          // This is not a hugely descriptor error, alas.
        }
        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
        /*if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(simplePing:didFailToSendPacket:error:)] ) {
            [self.delegate simplePing:self didFailToSendPacket:packet error:error];
        }*/
    }
    
    self.nextSequenceNumber += 1;
}

-(void)readData {
    //NSLog(@"READ DATA");
    
    int                     err;
    struct sockaddr_storage addr;
    socklen_t               addrLen;
    ssize_t                 bytesRead;
    void *                  buffer;
    enum { kBufferSize = 65535 };
    
    // 65535 is the maximum IP packet size, which seems like a reasonable bound
    // here (plus it's what <x-man-page://8/ping> uses).
    
    buffer = malloc(kBufferSize);
    assert(buffer != NULL);
    
    // Actually read the data.
    
    addrLen = sizeof(addr);
    bytesRead = recvfrom(CFSocketGetNative(self->_socket), buffer, kBufferSize, 0, (struct sockaddr *) &addr, &addrLen);
    err = 0;
    if (bytesRead < 0) {
        err = errno;
    }
    
    // Process the data we read.
    
    if (bytesRead > 0) {
        NSMutableData *packet;
        
        packet = [NSMutableData dataWithBytes:buffer length:(NSUInteger) bytesRead];
        assert(packet != nil);
        
        ////
        
        const ICMPHeader *icmpPtr;
        icmpPtr = [PingUtil icmpInPacket:packet];
        
        const struct IPHeader * ipPtr;
        
        NSString *ipString = @"*";
        
        if ([packet length] >= (sizeof(IPHeader) + sizeof(ICMPHeader))) {
            ipPtr = (const IPHeader *) [packet bytes];
            
            // TODO: IPV6!!!
            
            ipString = [NSString stringWithFormat:@"%u.%u.%u.%u", ipPtr->sourceAddress[0], ipPtr->sourceAddress[1], ipPtr->sourceAddress[2], ipPtr->sourceAddress[3]];
            
//            NSLog(@"!! answer packet TTL: %u, type: %u !!", ipPtr->timeToLive, icmpPtr->type);
        }
        
        ////
        
        // We got some data, pass it up to our client.
        if ((self.delegate != nil) && [self.delegate respondsToSelector:@selector(pingUtil:didReceivePingResponsePacket:withType:fromIp:)]) {
            [self.delegate pingUtil:self didReceivePingResponsePacket:packet withType:icmpPtr->type fromIp:ipString];
        }
        
        /*if ( [self isValidPingResponsePacket:packet] ) {
            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(simplePing:didReceivePingResponsePacket:)] ) {
                [self.delegate simplePing:self didReceivePingResponsePacket:packet];
            }
        } else {
            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(simplePing:didReceiveUnexpectedPacket:)] ) {
                [self.delegate simplePing:self didReceiveUnexpectedPacket:packet];
            }
        }*/
    } else {
        
        // We failed to read the data, so shut everything down.
        
        if (err == 0) {
            err = EPIPE;
        }
        [self failWithError:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
    }
    
    free(buffer);
    
    // Note that we don't loop back trying to read more data.  Rather, we just
    // let CFSocket call us again.
}

/////////////////
+ (NSUInteger)icmpHeaderOffsetInPacket:(NSData *)packet
// Returns the offset of the ICMPHeader within an IP packet.
{
    NSUInteger              result;
    const struct IPHeader * ipPtr;
    size_t                  ipHeaderLength;
    
    result = NSNotFound;
    if ([packet length] >= (sizeof(IPHeader) + sizeof(ICMPHeader))) {
        ipPtr = (const IPHeader *) [packet bytes];
        assert((ipPtr->versionAndHeaderLength & 0xF0) == 0x40);     // IPv4
        assert(ipPtr->protocol == 1);                               // ICMP
        ipHeaderLength = (ipPtr->versionAndHeaderLength & 0x0F) * sizeof(uint32_t);
        if ([packet length] >= (ipHeaderLength + sizeof(ICMPHeader))) {
            result = ipHeaderLength;
        }
    }
    return result;
}

+ (const struct ICMPHeader *)icmpInPacket:(NSData *)packet
// See comment in header.
{
    const struct ICMPHeader *   result;
    NSUInteger                  icmpHeaderOffset;
    
    result = nil;
    icmpHeaderOffset = [self icmpHeaderOffsetInPacket:packet];
    if (icmpHeaderOffset != NSNotFound) {
        result = (const struct ICMPHeader *) (((const uint8_t *)[packet bytes]) + icmpHeaderOffset);
    }
    return result;
}
///////////////

/////

-(void)start {
    
    int err = 0;
    int fd = -1;
    const struct sockaddr *addrPtr;
    
    addrPtr = (const struct sockaddr *) [self.hostAddress bytes];
    
    fd = socket(addrPtr->sa_family, SOCK_DGRAM, IPPROTO_ICMP);
    if (fd < 0) {
        err = errno;
    }
    
    if (err != 0) {
        [self failWithError:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
    } else {
        CFSocketContext     context = {0, (__bridge void *)(self), NULL, NULL, NULL};
        CFRunLoopSourceRef  rls;
        
        self->_socket = CFSocketCreateWithNative(NULL, fd, kCFSocketReadCallBack, SocketReadCallback, &context);
        //assert(self->_socket != NULL);
        
        assert( CFSocketGetSocketFlags(self->_socket) & kCFSocketCloseOnInvalidate );
        fd = -1;
        
        rls = CFSocketCreateRunLoopSource(NULL, self->_socket, 0);
        assert(rls != NULL);
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
        
        CFRelease(rls);
        //CFRunLoopRun();
        
        if ((self.delegate != nil) && [self.delegate respondsToSelector:@selector(pingUtil:didStartWithAddress:)]) {
            [self.delegate pingUtil:self didStartWithAddress:self.hostAddress];
        }
    }
    assert(fd == -1);
}

-(void)closeSocket {
    if (self->_socket != NULL) {
        CFSocketInvalidate(self->_socket);
        CFRelease(self->_socket);
        self->_socket = NULL;
    }
}

-(void)failWithError:(NSError *)error {
    NSLog(@"FAIL WITH ERROR");
    
    if ((self.delegate != nil) && [self.delegate respondsToSelector:@selector(pingUtil:didFailWithError:)]) {
        [self.delegate pingUtil:self didFailWithError:error];
    }
}

- (void)failWithHostStreamError:(CFStreamError)streamError {
    NSDictionary *userInfo;
    
    if (streamError.domain == kCFStreamErrorDomainNetDB) {
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInteger:streamError.error], kCFGetAddrInfoFailureKey, nil];
    } else {
        userInfo = nil;
    }
    
    NSError *error = [NSError errorWithDomain:(NSString *)kCFErrorDomainCFNetwork code:kCFHostErrorUnknown userInfo:userInfo];
    //assert(error != nil);
    
    [self failWithError:error];
}

////////////////
// Callbacks
////////////////

static void SocketReadCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    PingUtil *obj;
    
    obj = (__bridge PingUtil *) info;
    assert([obj isKindOfClass:[PingUtil class]]);
    
//#pragma unused(s)
//    assert(s == obj->_socket);
//#pragma unused(type)
//    assert(type == kCFSocketReadCallBack);
//#pragma unused(address)
//    assert(address == nil);
//#pragma unused(data)
//    assert(data == nil);
    
    //NSLog(@"SOCKET READ CALLBACK");
    [obj readData];
}

static uint16_t in_cksum(const void *buffer, size_t bufferLen)
// This is the standard BSD checksum code, modified to use modern types.
{
    size_t              bytesLeft;
    int32_t             sum;
    const uint16_t *    cursor;
    union {
        uint16_t        us;
        uint8_t         uc[2];
    } last;
    uint16_t            answer;
    
    bytesLeft = bufferLen;
    sum = 0;
    cursor = buffer;
    
    /*
     * Our algorithm is simple, using a 32 bit accumulator (sum), we add
     * sequential 16 bit words to it, and at the end, fold back all the
     * carry bits from the top 16 bits into the lower 16 bits.
     */
    while (bytesLeft > 1) {
        sum += *cursor;
        cursor += 1;
        bytesLeft -= 2;
    }
    
    /* mop up an odd byte, if necessary */
    if (bytesLeft == 1) {
        last.uc[0] = * (const uint8_t *) cursor;
        last.uc[1] = 0;
        sum += last.us;
    }
    
    /* add back carry outs from top 16 bits to low 16 bits */
    sum = (sum >> 16) + (sum & 0xffff);	/* add hi 16 to low 16 */
    sum += (sum >> 16);			/* add carry */
    answer = (uint16_t) ~sum;   /* truncate to 16 bits */
    
    return answer;
}

@end
