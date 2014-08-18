#import "LSHTTPStubURLProtocol.h"
#import "LSNocilla.h"
#import "NSURLRequest+LSHTTPRequest.h"
#import "LSStubRequest.h"
#import "NSURLRequest+DSL.h"
#import "LSHTTPRequestDSLRepresentation.h"

@interface NSHTTPURLResponse(UndocumentedInitializer)
- (id)initWithURL:(NSURL*)URL statusCode:(NSInteger)statusCode headerFields:(NSDictionary*)headerFields requestTime:(double)requestTime;
@end

@implementation LSHTTPStubURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if( ![@[ @"http", @"https" ] containsObject:request.URL.scheme] )
        return NO;
    
    return [LSNocilla sharedInstance].catchAllRequests || [[LSNocilla sharedInstance] responseForRequest:request] != nil;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return NO;
}

- (void)startLoading {
    
    void(^loadingBlock)() = ^{
        NSURLRequest* request = [self request];
        id<NSURLProtocolClient> client = [self client];

        LSStubResponse* stubbedResponse = [[LSNocilla sharedInstance] responseForRequest:request];
        if(stubbedResponse == nil) {
            [NSException raise:@"NocillaUnexpectedRequest" format:@"An unexpected HTTP request was fired.\n\nUse this snippet to stub the request:\n%@\n", [[[LSHTTPRequestDSLRepresentation alloc] initWithRequest:request] description]];
        }

        if (stubbedResponse.shouldFail) {
            [client URLProtocol:self didFailWithError:stubbedResponse.error];
        } else {
            NSHTTPURLResponse* urlResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                      statusCode:stubbedResponse.statusCode
                                                    headerFields:stubbedResponse.headers
                                                     requestTime:0];
            NSData *body = stubbedResponse.body;

            [client URLProtocol:self didReceiveResponse:urlResponse
             cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            [client URLProtocol:self didLoadData:body];
            [client URLProtocolDidFinishLoading:self];
        }
    };
    
    double randDelay = [LSNocilla sharedInstance].minResponceDelay;
    double diff = [LSNocilla sharedInstance].maxResponceDelay - [LSNocilla sharedInstance].minResponceDelay;
    if (diff > 0) {
        randDelay += ((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff;
    }
    
    if (randDelay > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(randDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), loadingBlock);
    } else {
        loadingBlock();
    }
}

- (void)stopLoading {
}

@end
