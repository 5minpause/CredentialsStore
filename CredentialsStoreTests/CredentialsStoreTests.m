//
//  CredentialsStoreTests.m
//  CredentialsStoreTests
//
//  Created by Holger Frohloff on 11.01.13.
//  Copyright (c) 2013 Holger Frohloff. All rights reserved.
//

#import "../CredentialsStore/HFRCredentialsStore.h"
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

- (void)testListAllProviders
{
  [HFRCredentialsStore savePassword:kHFRCredentialsStoreTestsPassword
                       withUsername:kHFRCredentialsStoreTestsUsername
                        forProvider:kHFRCredentialsStoreTestsProvider];
  NSArray *providers = [HFRCredentialsStore listAllProviders];
  STAssertEqualObjects(@[kHFRCredentialsStoreTestsProvider], providers, @"List of all providers is accurate.");
}

- (void)testSavingAndRetrievingPasswords
{
  [HFRCredentialsStore savePassword:kHFRCredentialsStoreTestsPassword
                       withUsername:kHFRCredentialsStoreTestsUsername
                        forProvider:kHFRCredentialsStoreTestsProvider];
  NSString *savedPassword = [HFRCredentialsStore getPasswordForUsername:kHFRCredentialsStoreTestsUsername atProvider:kHFRCredentialsStoreTestsProvider];
  STAssertEqualObjects(kHFRCredentialsStoreTestsPassword, savedPassword, @"Saved password matches retrieved password.");
}

@end
