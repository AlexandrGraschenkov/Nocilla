#import <Foundation/Foundation.h>
#import "Nocilla.h"

@class LSStubRequest;
@class LSStubResponse;
@class LSHTTPClientHook;
@protocol LSHTTPRequest;

extern NSString * const LSUnexpectedRequest;

@interface LSNocilla : NSObject
+ (LSNocilla *)sharedInstance;

@property (nonatomic, strong, readonly) NSArray *stubbedRequests;
@property (nonatomic, assign) BOOL catchAllRequests; // default YES
@property (nonatomic, readonly) double maxResponceDelay;
@property (nonatomic, readonly) double minResponceDelay;

- (void)setResponceMinDelay:(double)minDelay maxDelay:(double)maxDelay;
- (void)start;
- (void)stop;
- (void)addStubbedRequest:(LSStubRequest *)request;
- (void)clearStubs;

- (void)registerHook:(LSHTTPClientHook *)hook;

- (LSStubResponse *)responseForRequest:(id<LSHTTPRequest>)request;
@end
