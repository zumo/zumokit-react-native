//
//  ZumoKitManager.m
//  Pods-Zumo
//
//  Created by Stephen Radford on 30/04/2019.
//

#import "ZumoKitManager.h"

@interface ZumoKitManager ()

@property (strong, nonatomic) ZumoKitImpl *zumoKit;

@end

@implementation ZumoKitManager

NSException *zumoKitNotInitializedException = [NSException
                                               exceptionWithName:@"ZumoKitNotInitialized"
                                               reason:@"ZumoKit has not been initialized"
                                               userInfo:nil];

+ (id)sharedManager {
    static ZumoKitManager *manager = nil;
    @synchronized(self) {
        if (manager == nil)
            manager = [[self alloc] init];
    }
    return manager;
}

- (void)initializeWithTxServiceUrl:(NSString *)txServiceUrl apiKey:(NSString *)apiKey appId:(NSString *)appId apiRoot:(NSString *)apiRoot {
    
    NSArray *appFolderPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *dbPath = [appFolderPath objectAtIndex:0];
    
    _zumoKit = [[ZumoKitImpl alloc] initWithDbPath:dbPath
                                  txServiceUrl:txServiceUrl
                                        apiKey:apiKey
                                         appId:appId
                                       apiRoot:apiRoot
            ];
}

- (void)authenticateWithEmail:(NSString *)email completionHandler:(AuthCompletionBlock)completionHandler {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    iOSAuthCallback *callback = [[iOSAuthCallback alloc]
                                 initWithCompletionHandler:completionHandler];
    
    [[_zumoKit zumoCore] auth:email callback:callback];
}

@end
