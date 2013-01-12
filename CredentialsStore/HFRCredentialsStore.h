//
//  HFRCredentialsStore.h
//  CredentialsStore
//
//  Created by Holger Frohloff on 11.01.13.
//  Copyright (c) 2013 Holger Frohloff. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HFRCredentialsStore : NSObject

// Save credentials
+ (BOOL)savePassword:(NSString *)password withUsername:(NSString *)username forProvider:(NSString *)provider;

// Retrieve credentials
+ (NSArray *)listAllProviders;
+ (NSString *)getPasswordForUsername:(NSString *)username atProvider:(NSString *)provider;
+ (NSDictionary *)credentialsForProvider:(NSString *)provider;

// Delete
+ (BOOL)deleteEntryForProvider:(NSString *)provider;
@end
