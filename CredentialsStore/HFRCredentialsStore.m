//
//  HFRCredentialsStore.m
//  CredentialsStore
//
//  Created by Holger Frohloff on 11.01.13.
//  Copyright (c) 2013 Holger Frohloff. All rights reserved.
//

#import "HFRCredentialsStore.h"
#import <Security/Security.h>
@interface HFRCredentialsStore ()
+ (BOOL)isProviderAlreadyPresent:(NSString *)provider;
@end

@implementation HFRCredentialsStore

#pragma mark - Helper
+ (NSMutableDictionary *)newSearchDictionaryWithUsername:(NSString *)username forProvider:(NSString *)provider {
  NSMutableDictionary *values = [@{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                 (__bridge id)kSecAttrAccount : [username dataUsingEncoding:NSUTF8StringEncoding],
                                 (__bridge id)kSecAttrService : [provider dataUsingEncoding:NSUTF8StringEncoding],
                                 (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked} mutableCopy];
  return values;
}

#pragma mark - Saving
+ (BOOL)savePassword:(NSString *)password withUsername:(NSString *)username forProvider:(NSString *)provider;
{

  if ([self isProviderAlreadyPresent:provider]) {
    return NO;
  } else {
    NSMutableDictionary *values = [self newSearchDictionaryWithUsername:username forProvider:provider];

    /* Retrieve & delte password entry if alread defined */
    if (![[self getPasswordForUsername:username atProvider:provider] isEqualToString:@"nil"]) {
      SecItemDelete((__bridge CFDictionaryRef)values);
    }

    OSStatus status = NULL;

    [values setValue:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];

    status = SecItemAdd((__bridge CFDictionaryRef)values, NULL);
    if (status != noErr) {
      NSError *error = [NSError errorWithDomain:@"de.HFDomain.hf" code:status userInfo:nil];
      NSLog(@"error while saving password: %@", error);
    }
    return YES;
  }
}

#pragma mark - Retrieving
+ (NSArray *)listAllProviders;
{
  NSDictionary *query = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                          (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitAll,
                          (__bridge id)kSecReturnAttributes : (__bridge id)kCFBooleanTrue,
                          (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked};

  CFArrayRef resAr = NULL;
  OSStatus status = NULL;
  __block NSMutableArray *returnArray = [@[] mutableCopy];
  status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&resAr);
  
  if (status == noErr) {
    NSArray *resultsArray = (__bridge_transfer NSArray *)resAr;
    [resultsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

      NSData *providerData = [obj valueForKey:(__bridge id)kSecAttrService];
      NSString *provider = [[NSString alloc] initWithBytes:[providerData bytes]
                                                    length:[providerData length]
                                                  encoding:NSUTF8StringEncoding];

      [returnArray addObject:provider];
    }];
  } else {
    if (status != errSecItemNotFound) {
      NSError *error = [NSError errorWithDomain:@"de.HFDomain.hf" code:status userInfo:nil];
      NSLog(@"error while retrieving providers: %@", error);
    }
  }
  return returnArray;
}

+ (BOOL)isProviderAlreadyPresent:(NSString *)provider
{
  NSDictionary *query = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                          (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne,
                          (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue,
                          (__bridge id)kSecAttrService : [provider dataUsingEncoding:NSUTF8StringEncoding],
                          (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked};

  CFDataRef results = NULL;
  OSStatus status = NULL;
  status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&results);

  if (status == noErr) {
    return YES;
  } else {
    if (status != errSecItemNotFound) {
      NSError *error = [NSError errorWithDomain:@"de.HFDomain.hf" code:status userInfo:nil];
      NSLog(@"error while checking provider: %@", error);
    }
    return NO;
  }
}

+ (NSString *)getPasswordForUsername:(NSString *)username atProvider:(NSString *)provider;
{
  OSStatus status = NULL;
  NSDictionary *query = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                          (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne,
                          (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue,
                          (__bridge id)kSecAttrAccount : [username dataUsingEncoding:NSUTF8StringEncoding],
                          (__bridge id)kSecAttrService : [provider dataUsingEncoding:NSUTF8StringEncoding],
                          (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked};

  CFDataRef results = NULL;
  status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&results);
  if (status == noErr) {

    NSData *passwordData = (__bridge_transfer NSData *)results;
    NSString *password = [[NSString alloc] initWithBytes:[passwordData bytes]
                                                   length:[passwordData length]
                                               encoding:NSUTF8StringEncoding];
    return password;

  } else {
    if (status != errSecItemNotFound) {
      NSError *error = [NSError errorWithDomain:@"de.HFDomain.hf" code:status userInfo:nil];
      NSLog(@"error while getting password: %@", error);
    }
		return @"";
  }
}

+ (NSDictionary *)credentialsForProvider:(NSString *)provider;
{
  NSDictionary *query = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                          (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne,
                          (__bridge id)kSecReturnAttributes : (__bridge id)kCFBooleanTrue,
                          (__bridge id)kSecAttrService : [provider dataUsingEncoding:NSUTF8StringEncoding],
                          (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked};

  CFDictionaryRef resDic = NULL;
  OSStatus status = NULL;
  __block NSMutableDictionary *returnDictionary = [@{} mutableCopy];
  status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&resDic);

  if (status == noErr) {
    NSDictionary *resultsDictionary = (__bridge_transfer NSDictionary *)resDic;
    NSData *usernameData = [resultsDictionary valueForKey:(__bridge id)kSecAttrAccount];
    NSString *username = [[NSString alloc] initWithBytes:[usernameData bytes]
                                                  length:[usernameData length]
                                                encoding:NSUTF8StringEncoding];

    NSString *password = [self getPasswordForUsername:username atProvider:provider];

    [returnDictionary setObject:username forKey:@"username"];
    [returnDictionary setObject:password forKey:@"password"];
    return returnDictionary;
  } else {
    if (status != errSecItemNotFound) {
      NSError *error = [NSError errorWithDomain:@"de.HFDomain.hf" code:status userInfo:nil];
      NSLog(@"error while getting password: %@", error);
    }
		return @{};
  }
}
#pragma mark - Deleting
+ (BOOL)deleteEntryForProvider:(NSString *)provider
{
  if ([self isProviderAlreadyPresent:provider]) {
    NSDictionary *query = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService : [provider dataUsingEncoding:NSUTF8StringEncoding]};
    if (SecItemDelete((__bridge CFDictionaryRef)query) == noErr) {
      return YES;
    } else {
      return NO;
    }
  } else {
    return NO;
  }
}
@end
