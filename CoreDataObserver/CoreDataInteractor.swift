//
//  CoreData.swift
//  CoreDataObserver
//
//  Created by Almas Daumov on 8/13/19.
//  Copyright © 2019 Almas Daumov. All rights reserved.
//

import CoreData

final class CoreDataInteractor {

    static let shared =  CoreDataInteractor()

    private var deletesObservers: [WeakBox<ChangesObserver>] = []
    private var updatesObservers: [WeakBox<ChangesObserver>] = []
    private var insertsObservers: [WeakBox<ChangesObserver>] = []

    public func observeDeletes(type: NSManagedObject.Type,
                               closure: @escaping ([NSManagedObject]) -> Void) -> ChangesObserver {
        let observer = ChangesObserver(type: type, closure: closure)
        deletesObservers.append(WeakBox(observer))
        return observer
    }

    public func observeInserts(type: NSManagedObject.Type,
                               closure: @escaping ([NSManagedObject]) -> Void) -> ChangesObserver {
        let observer = ChangesObserver(type: type, closure: closure)
        insertsObservers.append(WeakBox(observer))
        return observer
    }

    public func observeUpdates(type: NSManagedObject.Type,
                               closure: @escaping ([NSManagedObject]) -> Void) -> ChangesObserver {
        let observer = ChangesObserver(type: type, closure: closure)
        updatesObservers.append(WeakBox(observer))
        return observer
    }

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextObjectsDidChange(notification:)),
                                               name: .NSManagedObjectContextObjectsDidChange,
                                               object: context)
    }

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreDataObserver")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

extension CoreDataInteractor {
    @objc
    private func managedObjectContextObjectsDidChange(notification: Notification) {
        if let deletes = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletes.isEmpty {
            process(deletes: deletes)
        }

        if let inserts = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>, !inserts.isEmpty {
            process(inserts: inserts)
        }

        if let updates = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updates.isEmpty {
            process(updates: updates)
        }
    }

    private func process(deletes: Set<NSManagedObject>) {
        process(changes: deletes, observers: deletesObservers)
    }

    private func process(inserts: Set<NSManagedObject>) {
        process(changes: inserts, observers: insertsObservers)
    }

    private func process(updates: Set<NSManagedObject>) {
        process(changes: updates, observers: updatesObservers)
    }

    private func process(changes: Set<NSManagedObject>, observers: [WeakBox<ChangesObserver>]) {
        let changedTypes = uniqueTypes(in: changes)
        let registeredTypes = uniqueRegisteredTypes(for: observers)

        for registeredType in registeredTypes {
            guard changedTypes.contains(where: { changedType in changedType == registeredType }) else { continue }

            let typedChangedObjects = cast(changes: changes, as: registeredType)

            // notify observers
            let typedObservers = observers.compactMap { $0.object }.filter { $0.type == registeredType }
            typedObservers.forEach { $0.closure(typedChangedObjects) }
        }
    }

    private func uniqueTypes(in changes: Set<NSManagedObject>) -> [NSManagedObject.Type] {
        let changedTypes = changes.compactMap { type(of: $0) }
        var uniqueChangesTypes: [NSManagedObject.Type] = []
        for type in changedTypes {
            if !uniqueChangesTypes.contains { type1 in type1 == type } {
                uniqueChangesTypes.append(type)
            }
        }

        return uniqueChangesTypes
    }

    private func uniqueRegisteredTypes(for observers: [WeakBox<ChangesObserver>]) -> [NSManagedObject.Type] {
        let registeredTypes = observers.compactMap { $0.object?.type }
        var uniqueRegisteredTypes: [NSManagedObject.Type] = []
        for type in registeredTypes {
            if !uniqueRegisteredTypes.contains { type1 in type1 == type } {
                uniqueRegisteredTypes.append(type)
            }
        }
        return uniqueRegisteredTypes
    }

    private func cast<T: NSManagedObject>(changes: Set<NSManagedObject>, as type: T.Type) -> [T] {
        return changes.compactMap { $0 as? T }
    }

}

public final class ChangesObserver {
    private(set) var type: NSManagedObject.Type
    private(set) var closure: ([NSManagedObject]) -> Void

    public init(type: NSManagedObject.Type, closure: @escaping ([NSManagedObject]) -> Void) {
        self.type = type
        self.closure = closure
    }
}

private struct WeakBox<T: AnyObject> {

    weak var object: T?

    init(_ object: T?) {
        self.object = object
    }
}
