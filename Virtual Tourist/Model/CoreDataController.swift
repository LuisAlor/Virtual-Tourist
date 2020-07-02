//
//  CoreDataController.swift
//  Virtual Tourist
//
//  Created by Luis Angel Vazquez Alor on 30.06.2020.
//  Copyright © 2020 Luis Angel Vazquez Alor. All rights reserved.
//

import Foundation
import CoreData

class CoreDataController {
        
    //Properties
    let persistentContainer: NSPersistentContainer!
    var backgroundContext: NSManagedObjectContext!
    
    //Initialize the persistent container with modelname
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    ///Returns the managed object context associated with the main queue.
    var viewContext: NSManagedObjectContext{
        return persistentContainer.viewContext
    }
    
    ///Setups Merging Policies of backgroundContext and viewContext
    func setupContexts(){
        
        //Create a newly private managed object context.
        let backgroundContext = persistentContainer.newBackgroundContext()
        
        //Set context to automatically merge changes saved to its persistent store coordinator or parent context.
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        //Set merging policies
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    /// Instructs the persistent container to load the persistent stores
    func load(){
        //Instructs the persistent container to load the persistent stores.
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            //If error then quit load
            guard error == nil else { return }
            //Configure our context merging options
            self.setupContexts()
            //Auto save contexts
            self.autoSaveViewContext()
        }
        
    }
}

extension CoreDataController {
    
    /// Autosaves viewContext every interval of time, by default every 30 seconds.
    func autoSaveViewContext(interval: TimeInterval = 30){
        //If the interval is less than zero then quit
        guard interval > 0 else { return }
        
        //If there are changed commited in the viewContext then save
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        // Schedules to autosave viewContext every "interval" or every 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + interval){
            self.autoSaveViewContext(interval: interval)
        }
    }
}
