//
//  JCDHTTPConnection.h
//  Created by Justin Driscoll on 11/26/11.
//

#import <Foundation/Foundation.h>


typedef void (^OnCompletion) (NSURLResponse *response, NSData *data, NSError *error);

@interface WrappedNSURLConnection : NSObject

@property (nonatomic) NSData *certificateData;

- (id)initWithRequest:(NSURLRequest *)urlRequest;

- (BOOL)executeRequestAndOnCompletion:(OnCompletion)onCompletionBlock;

@end
