//
//  HFRCredentialsStore.m
//  CredentialsStore
//
//  Created by Holger Frohloff on 11.01.13.
//  Copyright (c) 2013 Holger Frohloff. All rights reserved.
//

#import "HFRCredentialsStore.h"
#import <Security/Security.h>

static NSString *kHFRPassword = @"kHFRPassword";
static NSString *kHFRProvider = @"kHFRProvider";
static NSString *kHFRUsername = @"kHFRUsername";

@implementation HFRCredentialsStore

+ (void)savePassword:(NSString *)password withUsername:(NSString *)username forProvider:(NSString *)provider;
{
  NSDictionary *values = @{kHFRPassword : password,
                           kHFRProvider : provider,
                           kHFRUsername : username};
  SecItemAdd((__bridge CFDictionaryRef)values, NULL);
}

+ (NSArray *)listAllProviders;
{
  return @[];
}

+ (NSString *)getPasswordForUsername:(NSString *)username atProvider:(NSString *)provider;
{
  NSDictionary *query = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword};
  SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);

}
@end
