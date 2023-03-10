//
//  Persistence.swift
//  SwiftCal
//
//  Created by Thomas Prezioso Jr on 1/9/23.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    let dataBase = "SwiftCal.sqlite"
    var oldStoreURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(dataBase)
        
    }
    var sharedStoreURL: URL {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.Swifttom.SwiftCal")!
        return container.appendingPathExtension(dataBase)
    }

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        let startDate = Calendar.current.dateInterval(of: .month, for: .now)!.start
        for dayOffset in 0..<30 {
            let newDay = Day(context: viewContext)
            newDay.date = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate)
            newDay.didStudy = Bool.random()
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SwiftCal")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else if !FileManager.default.fileExists(atPath: oldStoreURL.path) {
            print("👴 old store doesn't exist. Using new shared URL")
            container.persistentStoreDescriptions.first!.url = sharedStoreURL
        }
        print("🕸️ container URL = \(container.persistentStoreDescriptions.first!.url!)")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        migrateStore(for: container)
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func migrateStore (for container: NSPersistentContainer) {
        print("➡️ went into migrateStore")
        let coordinator = container.persistentStoreCoordinator
        guard let oldStore = coordinator.persistentStore(for: oldStoreURL) else { return }
        print("🛡️ old store no longer exists")
        do {
           let _ = try coordinator.migratePersistentStore(oldStore, to: sharedStoreURL, type: .sqlite)
            print ("🏁 Migration successful")
        } catch {
            fatalError("Unable to migrate to shared store")
        }
        
        do {
            try FileManager.default.removeItem(at: oldStoreURL)
            print("🗑️ old store deleted")
        } catch {
            print("Unable to delete oldStore")
        }
    }
}
