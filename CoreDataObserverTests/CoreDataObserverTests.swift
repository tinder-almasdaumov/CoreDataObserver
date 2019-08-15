//
//  CoreDataObserverTests.swift
//  CoreDataObserverTests
//
//  Created by Almas Daumov on 8/14/19.
//  Copyright © 2019 Almas Daumov. All rights reserved.
//

import XCTest
@testable import CoreDataObserver

class CoreDataObserverTests: XCTestCase {

    let context = CoreDataInteractor.shared.context

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

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

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
