//
//  ViewController.swift
//  CoreDataObserver
//
//  Created by Almas Daumov on 8/13/19.
//  Copyright © 2019 Almas Daumov. All rights reserved.
//

import UIKit
import CoreData

class PerformanceTestingViewController: UIViewController {

    let context = CoreDataInteractor.shared.context

    var fetchedResultsController: NSFetchedResultsController<Rec>?

    var deletesObserver: AnyObject?
    var insertsObserver: AnyObject? 
    var updatesObserver: AnyObject?
    var allChangesObserver: AnyObject?

    override func viewDidLoad() {
        super.viewDidLoad()
        deleteAllRecs()
    }

    @IBOutlet var statusLabel: UILabel!
    private let insertsCount = 10000

    @IBAction
    func startNotificationExperiment() {
        fetchedResultsController = nil

        allChangesObserver = CoreDataInteractor.shared.observeAllChanges(type: Rec.self, closure: { changes in

        })

        let start = CFAbsoluteTimeGetCurrent()
        addRecs(count: insertsCount)

        let diff = CFAbsoluteTimeGetCurrent() - start
        let status = "Notifcation observer took \(diff) seconds"
        print(status)
        statusLabel.text = status

        fetchCount()
    }

    @IBAction
    func startFetchedResultsExperiment() {
        configureFetchResultsController()

        deletesObserver = nil
        insertsObserver = nil
        updatesObserver = nil
        allChangesObserver = nil

        let start = CFAbsoluteTimeGetCurrent()
        addRecs(count: insertsCount)

        let diff = CFAbsoluteTimeGetCurrent() - start

        let status = "NSFetchedResultsController took \(diff) seconds"
        print(status)
        statusLabel.text = status

        fetchCount()
    }
}

extension PerformanceTestingViewController {
    func configureFetchResultsController(){
        let sortDescriptor = NSSortDescriptor(key: "first", ascending: true)
        let fetchRequest: NSFetchRequest<Rec> = NSFetchRequest(entityName: "Rec")
        fetchRequest.sortDescriptors = [sortDescriptor]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: context,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        fetchedResultsController.delegate = self
        self.fetchedResultsController = fetchedResultsController
        try? fetchedResultsController.performFetch()
    }
}

private extension PerformanceTestingViewController {
    func addRecs(count: Int) {
        for i in 0..<count {
            let rec = Rec(context: context)
            rec.first = "\(i) " + UUID().uuidString
            rec.last = "\(i) " + UUID().uuidString
            rec.title = "\(i) " + UUID().uuidString
        }

        try? context.save()
    }

    func fetchCount() {
        let request: NSFetchRequest<Rec> = Rec.fetchRequest()
        if let count = try? context.count(for: request) {
            statusLabel.text = (statusLabel.text ?? "") + "\nRecs count: \(count)"
        }
    }

    @IBAction
    func deleteAllRecs() {
        let request: NSFetchRequest<Rec> = Rec.fetchRequest()

        if let result = try? context.fetch(request) {
            result.forEach { context.delete($0) }
        }

        try? context.save()
    }
}

extension PerformanceTestingViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
//        print("did change section")
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        print("didChangeContent")
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        print("didChangeObject")
    }
}
