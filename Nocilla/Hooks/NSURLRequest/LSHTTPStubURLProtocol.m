#import "LSHTTPStubURLProtocol.h"
#import "LSNocilla.h"
#import "NSURLRequest+LSHTTPRequest.h"
#import "LSStubRequest.h"
#import "NSURLRequest+DSL.h"

@interface NSHTTPURLResponse(UndocumentedInitializer)
- (id)initWithURL:(NSURL*)URL statusCode:(NSInteger)statusCode headerFields:(NSDictionary*)headerFields requestTime:(double)requestTime;
@end

@implementation LSHTTPStubURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if( ![@[ @"http", @"https" ] containsObject:request.URL.scheme] )
        return NO;
    
    if([LSNocilla sharedInstance].catchAllRequests)
        return YES;
    
    BOOL result = NO;
    @try {
        result = nil != [[LSNocilla sharedInstance] responseForRequest:request];
    }
    @catch (NSException *exception) { /* sometimes we don't need catch exeptions */ }
    
    return result;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return NO;
}

- (void)startLoading {
    NSURLRequest* request = [self request];
	id<NSURLProtocolClient> client = [self client];

    LSStubResponse* stubbedResponse = [[LSNocilla sharedInstance] responseForRequest:request];

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
}

- (void)stopLoading {
}

@end
