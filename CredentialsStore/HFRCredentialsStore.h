//
//  HFRCredentialsStore.h
//  CredentialsStore
//
//  Created by Holger Frohloff on 11.01.13.
//  Copyright (c) 2013 Holger Frohloff. All rights reserved.
//

#import <Foundation/Foundation.h>

/** This class makes saving provider/username/password combinations to the keychain easy.

 */
@interface HFRCredentialsStore : NSObject

/**---------------------------------------------------------------------------------------
 * @name Instantiation
 *  ---------------------------------------------------------------------------------------
 */
/** Call this method to get a singleton instance of HFRCredentialsStrore.
 
 On the first call this method also takes care registering for iCloud Key-Value storage.
 If the local store is empty values from iCloud will be downloaded.

 @return The shared HFRCredentialsStore object.
 */
+ (id)sharedInstance;

/**---------------------------------------------------------------------------------------
 * @name Save Credentials
 *  ---------------------------------------------------------------------------------------
 */
/** Call this method to save a username/password combination for a specific provider.

 Results are dependent on values present within the HFRCredentialsStore:
 - If no entry for this provider exists the values are saved.
 - If an entry for this provider and username is present, the entry is updated.
 - If an entry for this provider exists with another username, it is not updated.

 @return If the entry for this provider was saved it returns YES, otherwise it returns NO.
 */
- (BOOL)savePassword:(NSString *)password withUsername:(NSString *)username forProvider:(NSString *)provider;

/**---------------------------------------------------------------------------------------
 * @name Retrieve credentials
 *  ---------------------------------------------------------------------------------------
 */
/** Call this method to get a list of all providers.

 The order of the NSArray is not defined.
 
 @param password The password you want to save.
 
 @param username The username you want associated with this provider.
 
 @param provider The provider for which username and password should be saved.

 @return Returns an NSArray with all providers as NSString objects.
 */

- (NSArray *)listAllProviders;

/** Use this method the get the password for a provider and username.

 If an entry exists for this specific provider/username combination the password is returned. Otherwise an empty NSString is returned.

 @return Returns an NSString. The contents depends on the provider/username combination.
 
 @see credentialsForProvider:
 */
- (NSString *)getPasswordForUsername:(NSString *)username atProvider:(NSString *)provider;

/** Retrieve username/password for a provider.

 Use this method if you want to get the credentials for a provider. The return value is an NSDictionary 
 where the username is under the key @"username" and the password under the key @"password".
 
 @param username The username for which the password should be retrieved.
 
 @param provider The provider for which the username matches.

 @return Returns an NSDictionary with username and password as key/value pairs.
 
 @see listAllProviders
 */
- (NSDictionary *)credentialsForProvider:(NSString *)provider;

/**---------------------------------------------------------------------------------------
 * @name Delete entries
 *  ---------------------------------------------------------------------------------------
 */
/** Delete credentials for a provider.

 Given a valid provider the entry is deleted. If the entry wasn't found or couldn't be deleted
 the return value will be NO. Otherwise it will be YES.
 
 @param provider The provider for which to delete the corresponding entry.

 @return A BOOL value describing the success of the deletion.
 */
- (BOOL)deleteEntryForProvider:(NSString *)provider;

/**---------------------------------------------------------------------------------------
 * @name iCloud Key-Value storage
 *  ---------------------------------------------------------------------------------------
 */
/** Synchronize the local store with iCloud storage.

 Sometimes a manual synchronization is desired. This method starts a complete synchronization process.
 Every local and remote key/value-pair is synchronized.
 */
- (void)synchronizeAllEntries;
@end
