//
//  CloudInteractionManager.swift
//  Pods
//
//  Created by Matthew McCroskey on 4/8/17.
//
//

import Foundation
import CloudKit
import RealmSwift

internal class CloudInteractionManager {
    
    internal func refreshUserAndRelatedObjects() {
        
        CKContainer.default().accountStatus { (status, iCloudAccountStatusError) in
            
            DispatchQueue.global(qos: .background).async {
                
                func userAccountStatusForCKAccountStatus() -> UserAccountStatus {
                    
                    switch status {
                        
                    case .available: return .available
                    case .noAccount: return .unavailableNoConfiguredAccount
                    case .restricted: return .unavailableICloudUsageRestricted
                    case .couldNotDetermine: return .unavailableMiscellaneousICloudError
                        
                    }
                    
                }
                    
                func updateUserAccountStatus(_ newAccountStatus:UserAccountStatus, error:Error?) {
                    
                    Mist.userAccountStatus = newAccountStatus
                    
                    if let userAccountStatusChangedCallback = Mist.callbacks.userAccountStatusChanged {
                        userAccountStatusChangedCallback(newAccountStatus, Mist.currentUser, error)
                    }
                    
                }
                
                func updateCurrentUserAndAccountStatus(withAccountStatusError error:Error?, afterPerformingWriteBlock writeBlock:((Realm) -> User?)) {
                    
                    var newUser: User? = nil
                    
                    func updateCurrentUserAndAccountStatus() {
                        
                        Mist.currentUser = newUser
                        updateUserAccountStatus(userAccountStatusForCKAccountStatus(), error: error)
                        
                        
                    }
                    
                    do {
                        
                        let realm = try Realm()
                        let _ = realm.addNotificationBlock({ (notification, realm) in
                            
                            updateCurrentUserAndAccountStatus()
                            
                        })
                        
                        try realm.write {
                            
                            newUser = writeBlock(realm)
                            
                        }
                        
                    } catch let tryError {
                        
                        // TODO: Notify client that read/write error occurred
                        print("\(tryError)")
                        
                        updateCurrentUserAndAccountStatus()
                        
                    }
                    
                }
                
                func performActionsOnUserScopedDataStores(inRealm realm:Realm, actionsBlock:((Realm, ScopedDataStore) -> Void)) {
                    
                    if let currentUser = Mist.currentUser {
                        
                        let currentUserId = currentUser.id
                        
                        let userDatabaseScopes: [DatabaseScope] = [.private, .shared]
                        for userDatabaseScope in userDatabaseScopes {
                            
                            let predicate = NSPredicate(format: "databaseScopeRawValue == %d && userId == %@", userDatabaseScope.rawValue, currentUserId)
                            let currentUserScopedDataStores = realm.objects(ScopedDataStore.self).filter(predicate)
                            if currentUserScopedDataStores.count > 0 {
                                
                                guard currentUserScopedDataStores.count == 1, let currentUserScopedDataStore = currentUserScopedDataStores.first else {
                                    fatalError("There should be exactly one scoped data store for the current database scope")
                                }
                                
                                actionsBlock(realm, currentUserScopedDataStore)
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
                func performActionOnLatestAuthenticatedUser(_ block: @escaping ((CKRecord) -> Void)) {
                    
                    let container = CKContainer.default()
                    
                    container.fetchUserRecordID(completionHandler: { (userRecordID, userRecordIDFetchError) in
                        
                        guard let userRecordID = userRecordID else {
                            
                            updateUserAccountStatus(.unavailableMiscellaneousICloudError, error: userRecordIDFetchError)
                            return
                            
                        }
                        
                        let publicDb = container.publicCloudDatabase
                        publicDb.fetch(withRecordID: userRecordID, completionHandler: { (cloudUserRecord, userRecordFetchError) in
                            
                            guard let cloudUserRecord = cloudUserRecord else {
                                
                                updateUserAccountStatus(.unavailableMiscellaneousICloudError, error: userRecordFetchError)
                                return
                            }
                            
                            block(cloudUserRecord)
                            
                        })
                        
                    })
                
                }
                
                func ensureDataStoresExistForUser(withUserId userId:String, inRealm realm:Realm) {
                    
                    var scopedDataStoresToSave: [ScopedDataStore] = []
                    let userDatabaseScopes: [DatabaseScope] = [.private, .shared]
                    for userDatabaseScope in userDatabaseScopes {
                        
                        let scopedDataStore: ScopedDataStore
                        let scopedDataStorePredicate = NSPredicate(format: "databaseScopeRawValue == %d && userId == %@", userDatabaseScope.rawValue, userId)
                        if let extantScopedDataStore = realm.objects(ScopedDataStore.self).filter(scopedDataStorePredicate).first {
                            
                            scopedDataStore = extantScopedDataStore
                            
                        } else {
                            
                            scopedDataStore = ScopedDataStore(databaseScope: userDatabaseScope, userId: userId)
                            scopedDataStoresToSave.append(scopedDataStore)
                            
                        }
                        
                        SerializableConfigurationStorage.setScopedDataStoreId(scopedDataStore.id, forDatabaseWithScope: userDatabaseScope)
                        
                    }
                    
                    realm.add(scopedDataStoresToSave)
                    
                }
                
                func createTempUserAndAssociatedStores(inRealm realm:Realm) -> User {
                    
                    let tempUser = User()
                    
                    realm.add(tempUser)
                    
                    ensureDataStoresExistForUser(withUserId: tempUser.id, inRealm: realm)
                    
                    return tempUser
                    
                }
                
                func createCloudKitUser(fromCloudKitRecord cloudKitRecord:CKRecord, inRealm realm:Realm) -> User {
                    
                    let id = cloudKitRecord.recordID.recordName
                    let localUserRecord: User
                    if let extantLocalUserRecord = realm.object(ofType: User.self, forPrimaryKey: id) {
                        localUserRecord = extantLocalUserRecord
                    } else {
                        localUserRecord = User()
                        localUserRecord.id = id
                    }
                    
                    localUserRecord.updateWithContentsOfRemoteRecord(cloudKitRecord)
                    realm.add(localUserRecord)
                    
                    return localUserRecord
                    
                }
                
                func migrateTempUserData(toNewUser newUser:User, inRealm realm:Realm) {}
                
                func removeExistingUserData(forUser user:User, fromRealm realm:Realm) {
                    
                    performActionsOnUserScopedDataStores(inRealm: realm, actionsBlock: { (realm, scopedDataStore) in
                        
                        let recordZonesInScopedDataStore = scopedDataStore.recordZones
                        
                        for recordZoneInScopedDataStore in recordZonesInScopedDataStore {
                            
                            let recordRelationsInRecordZone = recordZoneInScopedDataStore.recordRelations
                            
                            for recordRelation in recordRelationsInRecordZone {
                                
                                if let relatedRecord = realm.dynamicObject(ofType: recordRelation.relatedRecordClassName, forPrimaryKey: recordRelation.relatedRecordId) {
                                    realm.delete(relatedRecord)
                                }
                                
                                realm.delete(recordRelation)
                                
                            }
                            
                            realm.delete(recordZoneInScopedDataStore)
                            
                        }
                        
                        realm.delete(scopedDataStore)
                        
                    })
                    
                }
                
                if Mist.userAccountStatus != .available && status != .available {
                    
                    /*
                     No logins ever, so:
                     
                     1. Create a temp User
                     2. Create Private & Shared Scoped Data Stores for that temp User
                     3. Update the scopedDataStoreIds for the private and shared databaseScopes
                     4/ Save the temp User and related Scoped Data Stores to local cache
                     
                     */
                    
                    updateCurrentUserAndAccountStatus(withAccountStatusError: iCloudAccountStatusError, afterPerformingWriteBlock: { (realm) -> User? in
                        
                        return createTempUserAndAssociatedStores(inRealm: realm)
                        
                    })
                    
                    
                } else if Mist.userAccountStatus != .available && status == .available {
                    
                    /*
                     
                     First login, so:
                     
                     1. Ensure new User object for this newly-authenticated User exists and is up to Date
                     2. Migrate all temp data from being owned by temp User to being owned by this new User
                     3. Remove temp User from local cache
                     4. Save new User to local cache
                     
                     */
                    
                    performActionOnLatestAuthenticatedUser({ (cloudUserRecord) in
                        
                        updateCurrentUserAndAccountStatus(withAccountStatusError: nil, afterPerformingWriteBlock: { (realm) -> User? in
                            
                            let id = cloudUserRecord.recordID.recordName
                            let localUserRecord = createCloudKitUser(fromCloudKitRecord: cloudUserRecord, inRealm: realm)
                            
                            performActionsOnUserScopedDataStores(inRealm: realm, actionsBlock: { (realm, scopedDataStore) in
                                
                                scopedDataStore.userId = id
                                realm.add(scopedDataStore)
                                
                            })
                            
                            if let tempUser = Mist.currentUser {
                                realm.delete(tempUser)
                            }
                            
                            return localUserRecord
                            
                        })
                        
                    })
                    
                } else if Mist.userAccountStatus == .available && status != .available {
                    
                    /*
                     
                     User has just logged out, so:
                     
                     1. Remove from local cache all data owned by currentUser
                     2. Don't remove currentUser herself, since she's one of the Users of the app?
                     
                     */
                    
                    updateCurrentUserAndAccountStatus(withAccountStatusError: iCloudAccountStatusError, afterPerformingWriteBlock: { (realm) -> User? in
                        
                        guard let currentUser = Mist.currentUser else {
                            fatalError("Mist.currentUser should never be nil when Mist.userAccountStatus is .available.")
                        }
                        
                        removeExistingUserData(forUser: currentUser, fromRealm: realm)
                        
                        let newTempUser = createTempUserAndAssociatedStores(inRealm: realm)
                        return newTempUser
                        
                    })
                    
                } else /* Mist.userAccountStatus == .available && status == .available */ {
                    
                    /*
                     
                     This means currentUser and newUser are both non-nil, meaning that User has switched accounts, so:
                     
                     1. Do case 3 above with currentUser
                     2. Do case 2 above with newUser
                     
                     */
                    
                    performActionOnLatestAuthenticatedUser({ (cloudUserRecord) in
                        
                        updateCurrentUserAndAccountStatus(withAccountStatusError: iCloudAccountStatusError, afterPerformingWriteBlock: { (realm) -> User? in
                            
                            guard let currentUser = Mist.currentUser else {
                                fatalError("Mist.currentUser should never be nil when Mist.userAccountStatus is .available.")
                            }
                            
                            removeExistingUserData(forUser: currentUser, fromRealm: realm)
                            
                            let localUserRecord = createCloudKitUser(fromCloudKitRecord: cloudUserRecord, inRealm: realm)
                            ensureDataStoresExistForUser(withUserId: localUserRecord.id, inRealm: realm)
                            
                            return nil
                            
                        })
                        
                    })
                    
                }
                
            }
            
        }
        
    }
    
}
