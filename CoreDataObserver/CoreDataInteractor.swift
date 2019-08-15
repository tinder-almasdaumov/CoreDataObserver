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
    private var allChangesObservers: [WeakBox<ChangesObserver>] = []

    typealias ObserverClosure = ([NSManagedObject]) -> Void

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
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

}

extension CoreDataInteractor {
    func observeDeletes(type: NSManagedObject.Type,
                        closure: @escaping ObserverClosure) -> ChangesObserver {
        let observer = ChangesObserver(type: type, closure: closure)
        deletesObservers.append(WeakBox(observer))
        return observer
    }

    func observeInserts(type: NSManagedObject.Type,
                        closure: @escaping ObserverClosure) -> ChangesObserver {
        let observer = ChangesObserver(type: type, closure: closure)
        insertsObservers.append(WeakBox(observer))
        return observer
    }

    func observeUpdates(type: NSManagedObject.Type,
                        closure: @escaping ObserverClosure) -> ChangesObserver {
        let observer = ChangesObserver(type: type, closure: closure)
        updatesObservers.append(WeakBox(observer))
        return observer
    }

    func observeAllChanges(type: NSManagedObject.Type,
                           closure: @escaping ObserverClosure) -> ChangesObserver {
        let observer = ChangesObserver(type: type, closure: closure)
        allChangesObservers.append(WeakBox(observer))
        return observer
    }
}

extension CoreDataInteractor {

    private struct Changes {
        var deletes: Set<NSManagedObject> = []
        var inserts: Set<NSManagedObject> = []
        var updates: Set<NSManagedObject> = []

        init(userInfo: [AnyHashable: Any]) {
            if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletes.isEmpty {
                self.deletes = deletes
            }

            if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !inserts.isEmpty {
                self.inserts = inserts
            }

            if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updates.isEmpty {
                self.updates = updates
            }
        }
    }

    @objc
    private func managedObjectContextObjectsDidChange(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        let changes = Changes(userInfo: userInfo)
        process(deletes: changes.deletes)
        process(inserts: changes.inserts)
        process(updates: changes.updates)
        process(allChanges: changes)
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

    private func process(allChanges: Changes) {
        let changes = allChanges.deletes
            .union(allChanges.inserts)
            .union(allChanges.updates)
        process(changes: changes, observers: allChangesObservers)
    }

    private func process(changes: Set<NSManagedObject>, observers: [WeakBox<ChangesObserver>]) {
        let changedTypes = uniqueTypes(in: changes)
        let registeredTypes = uniqueRegisteredTypes(for: observers)

        registeredTypes.forEach { registeredType in
            guard changedTypes.contains(type: registeredType) else { return }
            let typedChangedObjects = cast(changes: changes, as: registeredType)
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

extension Collection where Iterator.Element == NSManagedObject.Type {
    func contains(type: NSManagedObject.Type) -> Bool {
        return contains(where: { myType in myType == type })
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
