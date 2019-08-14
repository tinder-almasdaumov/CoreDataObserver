//
//  ViewController.swift
//  CoreDataObserver
//
//  Created by Almas Daumov on 8/13/19.
//  Copyright © 2019 Almas Daumov. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    let context = CoreDataInteractor.shared.context

    var fetchedResultsController: NSFetchedResultsController<Rec>?

    var deletesObserver: AnyObject?
    var insertsObserver: AnyObject?
    var updatesObserver: AnyObject?

    override func viewDidLoad() {
        super.viewDidLoad()
        addNotificationExperimentButton()
        addFetchedResultsControllerExperimentButton()
    }

    @objc
    func startNotificationExperiment() {
        fetchedResultsController = nil

        deletesObserver = CoreDataInteractor.shared.observeDeletes(type: Rec.self) { recs in
            //            print("deletion: \(recs)")
        }

        insertsObserver = CoreDataInteractor.shared.observeInserts(type: Rec.self) { recs in
            //            print("insertion: \(recs)")
        }

        updatesObserver = CoreDataInteractor.shared.observeUpdates(type: Rec.self) { recs in
            //            print("updates: \(recs)")
        }

        let start = CFAbsoluteTimeGetCurrent()
        addEntities(count: 20000)
        deleteAll()

        let diff = CFAbsoluteTimeGetCurrent() - start
        print("Notifcation observer took \(diff) seconds")
    }

    @objc
    func startFetchedResultsExperiment() {
        configureFetchResultsController()

        deletesObserver = nil
        insertsObserver = nil
        updatesObserver = nil

        let start = CFAbsoluteTimeGetCurrent()
        addEntities(count: 20000)
        deleteAll()

        let diff = CFAbsoluteTimeGetCurrent() - start
        print("NSFetchedResultsController took \(diff) seconds")
    }
}

extension ViewController {
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

extension ViewController {
    func addEntities(count: Int) {
//        print(#function)
        for i in 0...count {
            let rec = Rec(context: context)
            rec.first = "\(i) " + UUID().uuidString
            rec.last = "\(i) " + UUID().uuidString
            rec.title = "\(i) " + UUID().uuidString
        }

        try? context.save()
    }

    func fetchAll() {
//        print(#function)
        let request: NSFetchRequest<Rec> = Rec.fetchRequest()

        if let result = try? context.fetch(request) {
            result.forEach { print($0.first! + $0.last! + $0.title! ) }
        }
    }

    func deleteAll() {
//        print(#function)

        let request: NSFetchRequest<Rec> = Rec.fetchRequest()

        if let result = try? context.fetch(request) {
            result.forEach { context.delete($0) }
        }

        try? context.save()
    }
}

// Buttons
extension ViewController {
    func addNotificationExperimentButton() {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Run notification experiment", for: .normal)
        view.addSubview(button)

        button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
        button.topAnchor.constraint(equalTo: view.topAnchor, constant: 250).isActive = true

        button.addTarget(self, action: #selector(startNotificationExperiment), for: .touchUpInside)
    }

    func addFetchedResultsControllerExperimentButton() {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Run NSFetchedResultsController experiment", for: .normal)
        view.addSubview(button)

        button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
        button.topAnchor.constraint(equalTo: view.topAnchor, constant: 200).isActive = true

        button.addTarget(self, action: #selector(startFetchedResultsExperiment), for: .touchUpInside)
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        print("did change section")
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
