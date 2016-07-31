//
//  ViewController.swift
//  CloudBug
//
//  Created by Kaveh on 5/25/16.
//  Copyright © 2016 treepi. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController {
   
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase

    override func viewDidLoad() {
        super.viewDidLoad()

        // Authentication with iCloud
        CKContainer.defaultContainer().accountStatusWithCompletionHandler { (accountStatus, error) in
            if accountStatus == CKAccountStatus.NoAccount {
                let alert = UIAlertController(title: "Sign in to iCloud", message: "Sign in to your iCloud account to write records. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on. If you don't have an iCloud account, tap Create a new Apple ID.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: { })
            } else {
                self.batchPerRecord()
            }
        }
        
        // Print current iCloud User ID
        iCloudUserIDAsync() {
            recordID, error in
            if let userID = recordID {
                print("received iCloudID \(userID)")
            } else {
                print("Fetched iCloudID was nil")
            }
        }
        
    }
    
    func saveSampleRecord() {
        
        
        let artistRecordID = CKRecordID(recordName:"2")
        let artistRecord = CKRecord(recordType: "Artist", recordID: artistRecordID)
        artistRecord["name" ] = "Arash"
        artistRecord["age"] = "33"
        
        publicDatabase.saveRecord(artistRecord) { (record, error) in }
        
//        let artworkRecordID = CKRecordID(recordName:"123456")
        let artworkRecord = CKRecord(recordType: "Artwork")
        artworkRecord["title" ] = "Swift"
        artworkRecord["address"] = "Melbourne"
        
        // Add artist reference to artwork
        let artistReference = CKReference(recordID: artistRecordID, action: .None)
        artworkRecord["artist"] = artistReference
        
        publicDatabase.saveRecord(artworkRecord) { (record, error) in }
    }
    
    func fetchRecordId() {
        let artworkRecordId = CKRecordID(recordName: "666")
        self.publicDatabase.fetchRecordWithID(artworkRecordId, completionHandler: {
            artworkRecord, error in
            if error != nil {
                print("Error - fetch record Id !!")
            }
            else {
                print("The fetch result is:\(artworkRecord)")
                //Modify and save the record to the database
                artworkRecord?.setObject("Kaveh", forKey: "artist")
                self.publicDatabase.saveRecord(artworkRecord!) { (record, error) in }
            }
        })
    }
    
    func fetchOneToOne() {
        
        let artworkRecordID = CKRecordID(recordName: "2DE16D5D-A5D9-4645-A807-A8BF4222F695")
        self.publicDatabase.fetchRecordWithID(artworkRecordID, completionHandler: {
            artworkRecord, error in
            if error != nil {
                print("Error - fetch record Id !!")
            }
            else {
//                print("The fetch result is:\(artworkRecord)")
                let referenceToArtist = artworkRecord?.objectForKey("artist")
                let artistRecordID = (referenceToArtist as! CKReference).recordID
                self.publicDatabase.fetchRecordWithID(artistRecordID, completionHandler: {
                    artistRecord, error in
                    if error != nil {
                        print("Error - fetch record Id !!")
                    }
                    else {
                        print("The fetch result is:\(artistRecord)")
                        
                    }
                })
                
            }
        })
    }
    
    func fetchoneToMany() {
        let artistRecordId = CKRecordID(recordName: "2")
        let predicate = NSPredicate(format: "artist = %@",artistRecordId)
        let query = CKQuery(recordType: "Artwork", predicate: predicate)
        self.publicDatabase.performQuery(query, inZoneWithID: nil, completionHandler: {
            results, error in
            
            if error != nil {
                print("Error - query for records !!")
            }
            else {
                for result in results! {
                    print("$$$ Query result:\(result)")
                }
            }
        })
    }
    
    func queryForRecords() {
        let recordArray = ["Dr","Arash","Kaveh"]
        let predicate = NSPredicate(format: "artist IN %@",recordArray)
        let query = CKQuery(recordType: "Artwork", predicate: predicate)
        self.publicDatabase.performQuery(query, inZoneWithID: nil, completionHandler: {
            results, error in
            
            if error != nil {
                print("Error - query for records !!")
            }
            else {
                for result in results! {
                    print("@@@ Query result:\(result)")
                }
            }
        })
    }
    
    func batchPerRecord() {
        let recordIDsArray:[CKRecordID] = [CKRecordID(recordName: "1"),CKRecordID(recordName: "2")]
        let fetchRecordsOperation = CKFetchRecordsOperation(recordIDs: recordIDsArray)
        
        fetchRecordsOperation.perRecordCompletionBlock = {
            record, recordID, error in
            if error != nil {
                print("ERROR")
            }
            else {
                print("@@@@@ perRecordCompletionBlock \(record)")
                
            }
        }
        
        fetchRecordsOperation.database = CKContainer.defaultContainer().publicCloudDatabase
        fetchRecordsOperation.start()
        
    }
    
    func fetchrecords() {
        let recordIDsArray:[CKRecordID] = [CKRecordID(recordName: "1"),CKRecordID(recordName: "2")]
        let fetchRecordsOperation = CKFetchRecordsOperation(recordIDs: recordIDsArray)
        
        fetchRecordsOperation.fetchRecordsCompletionBlock = {
            records, error in
            if error != nil {
                print("ERROR")
            }
            else {
                for record in records ?? [:]{
                    print("perRecordCompletionBlock \(record)")
                }
                
            }
        }
        
        fetchRecordsOperation.database = CKContainer.defaultContainer().publicCloudDatabase
        fetchRecordsOperation.start()
        
    }
    
    /// async gets iCloud record name of logged-in user
    func iCloudUserIDAsync(complete: (instance: CKRecordID?, error: NSError?) -> ()) {
        let container = CKContainer.defaultContainer()
        container.fetchUserRecordIDWithCompletionHandler() {
            recordID, error in
            if error != nil {
                print(error!.localizedDescription)
                complete(instance: nil, error: error)
            } else {
                print("fetched ID \(recordID?.recordName)")
                complete(instance: recordID, error: nil)
            }
        }
    }
    
//    func loadCoverPhoto(completion:(photo: UIImage!) -> ()) {
//        // 1
//        dispatch_async(
//            dispatch_get_global_queue(
//                DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
//                    var image: UIImage!
//                    // 2
//                    if let asset = self.record.objectForKey("CoverPhoto") as? CKAsset {
//                        // 3
//                        if let url = asset.fileURL {
//                            let imageData = NSData(contentsOfFile: url.path!)!
//                            // 4
//                            image = UIImage(data: imageData) 
//                        }
//                    }
//                    // 5
//                    completion(photo: image) 
//        }
//    }
    

}

