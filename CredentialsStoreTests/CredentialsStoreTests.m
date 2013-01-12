//
//  CredentialsStoreTests.m
//  CredentialsStoreTests
//
//  Created by Holger Frohloff on 11.01.13.
//  Copyright (c) 2013 Holger Frohloff. All rights reserved.
//

#import "../CredentialsStore/HFRCredentialsStore.h"
#import <Security/Security.h>
#import <SenTestingKit/SenTestingKit.h>

static NSString *kHFRCredentialsStoreTestsProvider = @"HFRCredentialsStoreTestProvider";
static NSString *kHFRCredentialsStoreTestsUsername = @"HFRCredentialsStoreTestUsername";
static NSString *kHFRCredentialsStoreTestsPassword = @"HFRCredentialsStoreTestPassword";

@interface CredentialsStoreTests : SenTestCase

@end

@implementation CredentialsStoreTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)cleanCredentialsStore
{
  NSArray *providers = [HFRCredentialsStore listAllProviders];
  [providers enumerateObjectsUsingBlock:^(NSString *provider, NSUInteger idx, BOOL *stop) {
    [HFRCredentialsStore deleteEntryForProvider:provider];
  }];
}

- (void)saveTwoEntries
{
  BOOL result1 = [HFRCredentialsStore savePassword:kHFRCredentialsStoreTestsPassword
                                      withUsername:kHFRCredentialsStoreTestsUsername
                                       forProvider:kHFRCredentialsStoreTestsProvider];
  BOOL result2 = [HFRCredentialsStore savePassword:@"secondPassword"
                                      withUsername:@"secondUsername"
                                       forProvider:@"secondProvider"];

  STAssertTrue(result1, @"First Save successful");
  STAssertTrue(result2, @"Second Save successful");
}

#pragma mark - Tests

- (void)testDeleteProviders
{
  [HFRCredentialsStore savePassword:kHFRCredentialsStoreTestsPassword
                       withUsername:kHFRCredentialsStoreTestsUsername
                        forProvider:kHFRCredentialsStoreTestsProvider];

  NSString *savedPassword = [HFRCredentialsStore getPasswordForUsername:kHFRCredentialsStoreTestsUsername atProvider:kHFRCredentialsStoreTestsProvider];

  STAssertEqualObjects(kHFRCredentialsStoreTestsPassword, savedPassword, @"Saved password matches retrieved password.");

  [HFRCredentialsStore deleteEntryForProvider:kHFRCredentialsStoreTestsProvider];
  NSDictionary *result = [HFRCredentialsStore credentialsForProvider:kHFRCredentialsStoreTestsProvider];
  STAssertEqualObjects(@{}, result, @"Result is empty after provider was deleted.");
}

- (void)testListAllProviders
{
  [self cleanCredentialsStore];
  [self saveTwoEntries];
//
  NSArray *providers = [HFRCredentialsStore listAllProviders];
  NSArray *compareProviders = @[kHFRCredentialsStoreTestsProvider, @"secondProvider"];
  STAssertEqualObjects(providers, compareProviders, @"List of all providers is accurate.");
}

- (void)testSavingAndRetrievingPasswords
{
  [self cleanCredentialsStore];
  [self saveTwoEntries];

  NSString *savedPassword = [HFRCredentialsStore getPasswordForUsername:kHFRCredentialsStoreTestsUsername atProvider:kHFRCredentialsStoreTestsProvider];

  STAssertEqualObjects(kHFRCredentialsStoreTestsPassword, savedPassword, @"Saved password matches retrieved password.");
}

- (void)testFetchCredentialsForProvider
{
  [self cleanCredentialsStore];
  [HFRCredentialsStore savePassword:kHFRCredentialsStoreTestsPassword
                       withUsername:kHFRCredentialsStoreTestsUsername
                        forProvider:kHFRCredentialsStoreTestsProvider];

  NSDictionary *resultsDic = [HFRCredentialsStore credentialsForProvider:kHFRCredentialsStoreTestsProvider];
  NSString *username = [resultsDic valueForKey:@"username"];
  NSString *password = [resultsDic valueForKey:@"password"];
  STAssertEqualObjects(username, kHFRCredentialsStoreTestsUsername, @"Usernames match.");
  STAssertEqualObjects(password, kHFRCredentialsStoreTestsPassword, @"Passwords match.");
}

- (void)testProviderCannotBeUsedTwice
{
  [self cleanCredentialsStore];
  BOOL result1 = [HFRCredentialsStore savePassword:kHFRCredentialsStoreTestsPassword
                       withUsername:kHFRCredentialsStoreTestsUsername
                        forProvider:kHFRCredentialsStoreTestsProvider];
  BOOL result2 = [HFRCredentialsStore savePassword:@"Another Password"
                       withUsername:@"Another Username"
                        forProvider:kHFRCredentialsStoreTestsProvider];

  STAssertTrue(result1, @"First Save successful");
  STAssertFalse(result2, @"Second Save NOT successful");
}

- (void)testUpdatingViaiCloud
{
  // Setup
  [self cleanCredentialsStore];
  [HFRCredentialsStore synchronize];
  NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
  if (store) {
    [NSNotificationCenter.defaultCenter addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:store queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
      [HFRCredentialsStore synchronize];
    }];
  }

  // No providers after fresh start
  NSArray *providers = [HFRCredentialsStore listAllProviders];
  NSArray *compareProviders = @[];
  STAssertEqualObjects(providers, compareProviders, @"No providers present yet.");

  // Create entry for a provider and sync to iCloud
  [HFRCredentialsStore savePassword:kHFRCredentialsStoreTestsPassword
                       withUsername:kHFRCredentialsStoreTestsUsername
                        forProvider:kHFRCredentialsStoreTestsProvider];

  // Manually deleting entry from HFRCredentialsStore w/o sync to iCloud
  NSMutableDictionary *query = [@{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                 (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked} mutableCopy];
  [query setObject:[kHFRCredentialsStoreTestsProvider dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrService];

  SecItemDelete((__bridge CFDictionaryRef)query);

  // Make sure deletion went through
  NSArray *providersAfterDelete = [HFRCredentialsStore listAllProviders];
  NSArray *compareProvidersAfterDelete = @[];
  STAssertEqualObjects(providersAfterDelete, compareProvidersAfterDelete, @"No providers present anymore.");

  // Sync with iCloud and populate HFRCredentialStore again
  [HFRCredentialsStore synchronize];
  NSArray *providersAfterSync = [HFRCredentialsStore listAllProviders];
  NSArray *compareProvidersAfterSync = @[kHFRCredentialsStoreTestsProvider];
  STAssertEqualObjects(providersAfterSync, compareProvidersAfterSync, @"Providers present again.");
}

@end
