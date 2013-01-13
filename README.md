CredentialsStore
================

HFRCredentialsStore is a Wrapper Class for easier Keychain access. HFRCredentialsStore makes it easy to save, update, delete and access credentials. Credentials are always tied to a provider and have a username and password.  

Providers are unique values. To change a provider's associated username you have to delete the entry for the provider ans create a new entry.

HFRCredentialsStore sync with iCloud Key-Value storage. Changes to providers are propagated to all connected instances.


##License

This project uses the MIT license.
