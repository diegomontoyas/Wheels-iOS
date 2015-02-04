//
//  JCDHTTPConnection.m
//  Created by Justin Driscoll on 11/26/11.
//

#import "WrappedNSURLConnection.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WrappedNSURLConnection () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, readonly) NSString *body;

@property (nonatomic, copy) OnCompletion onCompletion;

@end


@implementation WrappedNSURLConnection

- (id)initWithRequest:(NSURLRequest *)urlRequest
{
    self = [super init];
    if (self) {
        self.request = urlRequest;
    }
    return self;
}

- (NSString *)body
{
    return [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
}

- (BOOL)executeRequestAndOnCompletion:(OnCompletion)onCompletion
{
    self.onCompletion = onCompletion;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
    [connection start];
    return connection != nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)aResponse
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)aResponse;
    self.response = httpResponse;
    
    self.data = [NSMutableData data];
    [self.data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)bytes
{
    [self.data appendData:bytes];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (self.onCompletion)
        self.onCompletion(self.response, self.data, error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (self.onCompletion)
        self.onCompletion(self.response, self.data, nil);
}

-(NSCachedURLResponse *)connection:(NSURLConnection *)connection
                 willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (self.certificateData)
    {
        BOOL trusted = NO;
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
        {
            CFDataRef certDataRef = (__bridge_retained CFDataRef)self.certificateData;
            SecCertificateRef cert = SecCertificateCreateWithData(NULL, certDataRef);
            SecPolicyRef policyRef = SecPolicyCreateBasicX509();
            SecCertificateRef certArray[1] = { cert };
            CFArrayRef certArrayRef = CFArrayCreate(NULL, (void *)certArray, 1, NULL);
            SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
            SecTrustSetAnchorCertificates(serverTrust, certArrayRef);
            SecTrustResultType trustResult;
            SecTrustEvaluate(serverTrust, &trustResult);
            trusted = (trustResult == kSecTrustResultUnspecified);
            CFRelease(certArrayRef);
            CFRelease(policyRef);
            CFRelease(cert);
            CFRelease(certDataRef);
        }
        if (trusted)
        {
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        }
        else
        {
            [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
        }
    }
}

@end
