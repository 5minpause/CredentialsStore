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
  NSArray *providers = [HFRCredentialsStore.sharedInstance listAllProviders];
  [providers enumerateObjectsUsingBlock:^(NSString *provider, NSUInteger idx, BOOL *stop) {
    [HFRCredentialsStore.sharedInstance deleteEntryForProvider:provider];
  }];
}

- (void)saveTwoEntries
{
  BOOL result1 = [HFRCredentialsStore.sharedInstance savePassword:kHFRCredentialsStoreTestsPassword
                                                     withUsername:kHFRCredentialsStoreTestsUsername
                                                      forProvider:kHFRCredentialsStoreTestsProvider];
  BOOL result2 = [HFRCredentialsStore.sharedInstance savePassword:@"secondPassword"
                                                     withUsername:@"secondUsername"
                                                      forProvider:@"secondProvider"];

  STAssertTrue(result1, @"First Save successful");
  STAssertTrue(result2, @"Second Save successful");
}

#pragma mark - Tests

- (void)testDeleteProviders
{
  [HFRCredentialsStore.sharedInstance savePassword:kHFRCredentialsStoreTestsPassword
                                      withUsername:kHFRCredentialsStoreTestsUsername
                                       forProvider:kHFRCredentialsStoreTestsProvider];

  NSString *savedPassword = [HFRCredentialsStore.sharedInstance getPasswordForUsername:kHFRCredentialsStoreTestsUsername
                                                                            atProvider:kHFRCredentialsStoreTestsProvider];

  STAssertEqualObjects(kHFRCredentialsStoreTestsPassword, savedPassword, @"Saved password matches retrieved password.");

  [HFRCredentialsStore.sharedInstance deleteEntryForProvider:kHFRCredentialsStoreTestsProvider];
  NSDictionary *result = [HFRCredentialsStore.sharedInstance credentialsForProvider:kHFRCredentialsStoreTestsProvider];
  STAssertEqualObjects(@{}, result, @"Result is empty after provider was deleted.");
}

- (void)testListAllProviders
{
  [self cleanCredentialsStore];
  [self saveTwoEntries];
//
  NSArray *providers = [HFRCredentialsStore.sharedInstance listAllProviders];
  NSArray *compareProviders = @[kHFRCredentialsStoreTestsProvider, @"secondProvider"];
  STAssertEqualObjects(providers, compareProviders, @"List of all providers is accurate.");
}

- (void)testSavingAndRetrievingPasswords
{
  [self cleanCredentialsStore];
  [self saveTwoEntries];

  NSString *savedPassword = [HFRCredentialsStore.sharedInstance getPasswordForUsername:kHFRCredentialsStoreTestsUsername
                                                                            atProvider:kHFRCredentialsStoreTestsProvider];

  STAssertEqualObjects(kHFRCredentialsStoreTestsPassword, savedPassword, @"Saved password matches retrieved password.");
}

- (void)testUpdatingPassword
{
  [self cleanCredentialsStore];
  [HFRCredentialsStore.sharedInstance savePassword:kHFRCredentialsStoreTestsPassword
                                      withUsername:kHFRCredentialsStoreTestsUsername
                                       forProvider:kHFRCredentialsStoreTestsProvider];

  [HFRCredentialsStore.sharedInstance savePassword:@"newPassword"
                                      withUsername:kHFRCredentialsStoreTestsUsername
                                       forProvider:kHFRCredentialsStoreTestsProvider];

  NSString *savedPassword = [HFRCredentialsStore.sharedInstance getPasswordForUsername:kHFRCredentialsStoreTestsUsername
                                                                            atProvider:kHFRCredentialsStoreTestsProvider];

  STAssertEqualObjects(@"newPassword", savedPassword, @"Retrieved password matches updated password.");
}

- (void)testFetchCredentialsForProvider
{
  [self cleanCredentialsStore];
  [HFRCredentialsStore.sharedInstance savePassword:kHFRCredentialsStoreTestsPassword
                                      withUsername:kHFRCredentialsStoreTestsUsername
                                       forProvider:kHFRCredentialsStoreTestsProvider];

  NSDictionary *resultsDic = [HFRCredentialsStore.sharedInstance credentialsForProvider:kHFRCredentialsStoreTestsProvider];
  NSString *username = [resultsDic valueForKey:@"username"];
  NSString *password = [resultsDic valueForKey:@"password"];
  STAssertEqualObjects(username, kHFRCredentialsStoreTestsUsername, @"Usernames match.");
  STAssertEqualObjects(password, kHFRCredentialsStoreTestsPassword, @"Passwords match.");
}

- (void)testProviderCannotBeUsedTwice
{
  [self cleanCredentialsStore];
  BOOL result1 = [HFRCredentialsStore.sharedInstance savePassword:kHFRCredentialsStoreTestsPassword
                                                     withUsername:kHFRCredentialsStoreTestsUsername
                                                      forProvider:kHFRCredentialsStoreTestsProvider];
  BOOL result2 = [HFRCredentialsStore.sharedInstance savePassword:@"Another Password"
                                                     withUsername:@"Another Username"
                                                      forProvider:kHFRCredentialsStoreTestsProvider];

  STAssertTrue(result1, @"First Save successful");
  STAssertFalse(result2, @"Second Save NOT successful");
}

- (void)testUpdatingViaiCloud
{
  // Setup
  [self cleanCredentialsStore];

  // No providers after fresh start
  NSArray *providers = [HFRCredentialsStore.sharedInstance listAllProviders];
  NSArray *compareProviders = @[];
  STAssertEqualObjects(providers, compareProviders, @"No providers present yet.");

  // Create entry for a provider and sync to iCloud
  [HFRCredentialsStore.sharedInstance savePassword:kHFRCredentialsStoreTestsPassword
                                      withUsername:kHFRCredentialsStoreTestsUsername
                                       forProvider:kHFRCredentialsStoreTestsProvider];

  // Manually deleting entry from HFRCredentialsStore w/o sync to iCloud
  NSMutableDictionary *query = [@{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                 (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked} mutableCopy];
  [query setObject:[kHFRCredentialsStoreTestsProvider dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrService];

  SecItemDelete((__bridge CFDictionaryRef)query);

  // Make sure deletion went through
  NSArray *providersAfterDelete = [HFRCredentialsStore.sharedInstance listAllProviders];
  NSArray *compareProvidersAfterDelete = @[];
  STAssertEqualObjects(providersAfterDelete, compareProvidersAfterDelete, @"No providers present anymore.");

  // Sync with iCloud and populate HFRCredentialStore again
  dispatch_sync(dispatch_get_global_queue(0, 0), ^{
    [HFRCredentialsStore.sharedInstance synchronizeAllEntries];
  });
  NSArray *providersAfterSync = [HFRCredentialsStore.sharedInstance listAllProviders];
  NSArray *compareProvidersAfterSync = @[kHFRCredentialsStoreTestsProvider];
  STAssertEqualObjects(providersAfterSync, compareProvidersAfterSync, @"Providers present again.");
}

@end
