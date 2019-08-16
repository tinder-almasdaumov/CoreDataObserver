//
//  CoreDataObserverTests.swift
//  CoreDataObserverTests
//
//  Created by Almas Daumov on 8/14/19.
//  Copyright © 2019 Almas Daumov. All rights reserved.
//

import XCTest
@testable import CoreDataObserver
import CoreData

class CoreDataObserverTests: XCTestCase {

    let context = CoreDataInteractor.shared.context

    private var onObjectDidChange: ((NSManagedObject) -> Void)?

    override func setUp() {
        deleteAllUsers()
    }

    override func tearDown() {}

    func testDeletes() {
        let rec = Rec(context: context)
        rec.first = "testDeletes"

        let deleteExpectation = XCTestExpectation(description: "delete")

        let observer = CoreDataInteractor.shared.observeDeletes(type: Rec.self) { recs in
            XCTAssertTrue(recs.count == 1)
            let deletedRec = recs[0] as! Rec
            XCTAssertTrue(deletedRec.first == "testDeletes")
            deleteExpectation.fulfill()
        }

        context.delete(rec)

        wait(for: [deleteExpectation], timeout: 1)
    }

    func testInserts() {
        let observer = CoreDataInteractor.shared.observeInserts(type: Rec.self) { recs in

        }
    }

    func testUpdates() {
        let observer = CoreDataInteractor.shared.observeUpdates(type: Rec.self) { recs in

        }
    }

    func testAllChanges() {
        let observer = CoreDataInteractor.shared.observeAllChanges(type: Rec.self) { changes in

        }
    }

    func testOtherObserversDontTrigger() {
        let user = User(context: context)
        user.first = "test"

        let recsObserver = CoreDataInteractor.shared.observeInserts(type: Rec.self) { recs in
            XCTFail("Deleting users should not trigger Rec observer")
        }

        let expectation = XCTestExpectation(description: "delete")

        let usersObserver = CoreDataInteractor.shared.observeInserts(type: User.self) { users in
            let user = users[0] as! User
            XCTAssertTrue(user.first == "test")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)

        context.delete(user)
    }

    func testFetchedResultsControllerPerformance() {

        let expection = XCTestExpectation(description: "test")

        onObjectDidChange = { object in
            expection.fulfill()
        }

        let fetchRequest: NSFetchRequest<User> = NSFetchRequest(entityName: "User")
        let sortDescriptor = NSSortDescriptor(key: "first", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: context,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()

        self.measure {
            addUsers(count: 25000)
            deleteAllUsers()
        }

        wait(for: [expection], timeout: 1)
    }

    func testNotificationObserverPerformance() {

        let expectation = XCTestExpectation(description: "test")

        let observer = CoreDataInteractor.shared.observeDeletes(type: User.self) { changes in
            expectation.fulfill()
        }

        self.measure {
            addUsers(count: 25000)
            deleteAllUsers()
        }

        wait(for: [expectation], timeout: 1)
    }

    private func addUsers(count: Int) {
        for _ in 0..<count {
            let user = User(context: context)
            user.first = UUID().uuidString
            user.last = UUID().uuidString
            user.age = 25
        }

        try? context.save()
    }

    private func deleteAllUsers() {
        do {
            let fetchRequest: NSFetchRequest<User> = NSFetchRequest(entityName: "User")
            let users = try context.fetch(fetchRequest)
            for user in users {
                context.delete(user)
            }
            try context.save()
        } catch {
            XCTFail("Failed to delete Users")
        }

    }

}

extension CoreDataObserverTests: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        if let object = anObject as? NSManagedObject {
            onObjectDidChange?(object)
        }
    }
}
