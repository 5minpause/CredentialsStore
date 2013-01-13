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
- (BOOL)isProviderAlreadyPresent:(NSString *)provider;

// iCloud
- (void)updateKeysFromiCloud:(NSArray *)keysArray;
- (void)sendDataToiCloud:(NSDictionary *)dictionary forKey:(NSString *)key;
@end

@implementation HFRCredentialsStore

#pragma mark - Helper
- (NSMutableDictionary *)basicDictionary
{
  NSMutableDictionary *values = [@{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                 (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked} mutableCopy];
  return values;
}

- (NSMutableDictionary *)newSearchDictionaryWithUsername:(NSString *)username forProvider:(NSString *)provider {
  NSMutableDictionary *values = [self basicDictionary];
  [values setObject:[username dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrAccount];
  [values setObject:[provider dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrService];
  return values;
}

#pragma mark - Instantiation
+ (id)sharedInstance
{
  static dispatch_once_t once;
  static id sharedInstance;
  dispatch_once(&once, ^{
    sharedInstance = [[self alloc] init];

    // Register for key-value notifications from iCloud
    NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
    if (store) {
      [NSNotificationCenter.defaultCenter addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                      object:store
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notification) {

        NSDictionary *userInfo = [notification userInfo];
        NSNumber *reason = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];

        if (reason) {
          NSInteger reasonValue = [reason integerValue];

          if ((reasonValue == NSUbiquitousKeyValueStoreServerChange) ||
              (reasonValue == NSUbiquitousKeyValueStoreInitialSyncChange)) {

            NSArray *keys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];

            [keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
              NSDictionary *credentialsDic = [store valueForKey:key];
              [sharedInstance savePassword:[credentialsDic valueForKey:@"password"] withUsername:[credentialsDic valueForKey:@"username"] forProvider:key];
            }];
          }
        }
      }];
    }
  });
  return sharedInstance;
}

- (void)dealloc
{
  NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
  [NSNotificationCenter.defaultCenter removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:store];
}

#pragma mark - Saving
- (BOOL)savePassword:(NSString *)password withUsername:(NSString *)username forProvider:(NSString *)provider;
{

  // Is provider already present for another username: don't update credentials. 
  if ([self isProviderAlreadyPresent:provider] && [[self getPasswordForUsername:username atProvider:provider] isEqualToString:@""]) {
    return NO;
  } else {
    NSMutableDictionary *values = [self newSearchDictionaryWithUsername:username forProvider:provider];

    /* Retrieve & delete password entry if already defined */
    if (![[self getPasswordForUsername:username atProvider:provider] isEqualToString:@"nil"]) {
      SecItemDelete((__bridge CFDictionaryRef)values);
    }

    OSStatus status = NULL;

    [values setValue:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];

    status = SecItemAdd((__bridge CFDictionaryRef)values, NULL);
    if (status != noErr) {
      NSError *error = [NSError errorWithDomain:@"de.HFDomain.hf" code:status userInfo:nil];
      NSLog(@"error while saving password: %@", error);
      return NO;
    }

    // Syncing to iCloud
    [self sendDataToiCloud:@{@"username" : [username dataUsingEncoding:NSUTF8StringEncoding],
                             @"password" : [password dataUsingEncoding:NSUTF8StringEncoding]}
                    forKey:provider];
    return YES;
  }
}

#pragma mark - Retrieving
- (NSArray *)listAllProviders;
{

  NSMutableDictionary *query = [self basicDictionary];
  [query setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
  [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];

  CFArrayRef resAr = NULL;
  OSStatus status = NULL;
  __block NSMutableArray *returnArray = [@[] mutableCopy];
  status = SecItemCopyMatching((__bridge CFMutableDictionaryRef)query, (CFTypeRef *)&resAr);
  
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

- (BOOL)isProviderAlreadyPresent:(NSString *)provider
{
  NSMutableDictionary *query = [self basicDictionary];
  [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
  [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
  [query setObject:[provider dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrService];

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

- (NSString *)getPasswordForUsername:(NSString *)username atProvider:(NSString *)provider;
{
  OSStatus status = NULL;
  NSMutableDictionary *query = [self basicDictionary];
  [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
  [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
  [query setObject:[provider dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrService];
  [query setObject:[username dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrAccount];

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

- (NSDictionary *)credentialsForProvider:(NSString *)provider;
{
  NSMutableDictionary *query = [self basicDictionary];
  [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
  [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
  [query setObject:[provider dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrService];

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
- (BOOL)deleteEntryForProvider:(NSString *)provider
{
  if ([self isProviderAlreadyPresent:provider]) {
    NSMutableDictionary *query = [self basicDictionary];
    [query setObject:[provider dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrService];

    if (SecItemDelete((__bridge CFDictionaryRef)query) == noErr) {
      NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
      [store removeObjectForKey:provider];
      [store synchronize];
      return YES;
    } else {
      return NO;
    }
  } else {
    return NO;
  }
}

#pragma mark - iCloud
- (void)updateKeysFromiCloud:(NSArray *)keysArray;
{
  NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
  NSDictionary *storeDictionary = [store dictionaryRepresentation];

  [keysArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
    NSDictionary *credentialsDic = [storeDictionary valueForKey:key];

    NSData *passwordData = [credentialsDic valueForKey:@"password"];
    NSString *password = [[NSString alloc] initWithBytes:[passwordData bytes]
                                                  length:[passwordData length]
                                                encoding:NSUTF8StringEncoding];

    NSData *usernameData = [credentialsDic valueForKey:@"username"];
    NSString *username = [[NSString alloc] initWithBytes:[usernameData bytes]
                                                  length:[usernameData length]
                                                encoding:NSUTF8StringEncoding];

    [self savePassword:password withUsername:username forProvider:key];
  }];
}

- (void)sendDataToiCloud:(NSDictionary *)dictionary forKey:(NSString *)key
{
  NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
  if (store) {
    [store setObject:dictionary forKey:key];
  }
  [store synchronize];
}

- (void)synchronizeAllEntries
{
  NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
  [store synchronize];
  NSDictionary *dic = [store dictionaryRepresentation];
  [self updateKeysFromiCloud:[dic allKeys]];
}
@end
