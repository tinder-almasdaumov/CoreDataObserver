
//
//  TestsViewController.swift
//  CoreDataObserver
//
//  Created by Almas Daumov on 8/15/19.
//  Copyright © 2019 Almas Daumov. All rights reserved.
//

import UIKit
import CoreData

class TestsViewController: UIViewController {

    @IBOutlet var label: UILabel!

    let context = CoreDataInteractor.shared.context

    var deletesObserver: AnyObject?
    var insertsObserver: AnyObject?
    var updatesObserver: AnyObject?
    var allChangesObserver: AnyObject?

    var userInsertsObserver: AnyObject?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupObservers()
        deleteAllRecs()
        deleteAllUsers()
    }

    func setupObservers() {
        deletesObserver = CoreDataInteractor.shared.observeDeletes(type: Rec.self) { recs in
            let text = "Recs deletions observer: \(recs)"
            print(text)
            self.label.text = (self.label.text ?? "") + "\n" + text
        }

        insertsObserver = CoreDataInteractor.shared.observeInserts(type: Rec.self) { recs in
            let text = "Recs inserts observer: \(recs)"
            print(text)
            self.label.text = (self.label.text ?? "") + "\n" + text
        }

        updatesObserver = CoreDataInteractor.shared.observeUpdates(type: Rec.self) { recs in
            let text = "Recs updates observer: \(recs)"
            print(text)
            self.label.text = (self.label.text ?? "") + "\n" + text
        }

        allChangesObserver = CoreDataInteractor.shared.observeAllChanges(type: Rec.self) { changes in
            let text = "Recs all changes observer: \(changes)"
            print(text)
            self.label.text = (self.label.text ?? "") + "\n" + text
        }

        userInsertsObserver = CoreDataInteractor.shared.observeInserts(type: User.self) { users in
            let text = "User inserts observer: \(users)"
            print(text)
            self.label.text = (self.label.text ?? "") + "\n" + text
        }
    }
}

extension TestsViewController {
    @IBAction func addRecs() {
        label.text = nil
        for i in 0...0 {
            let rec = Rec(context: context)
            rec.first = "\(i) " + UUID().uuidString
            rec.last = "\(i) " + UUID().uuidString
            rec.title = "\(i) " + UUID().uuidString
        }

        try? context.save()
    }

    @IBAction func addUsers() {
        label.text = nil
        for i in 0...0 {
            let user = User(context: context)
            user.first = "\(i) " + UUID().uuidString
            user.last = "\(i) " + UUID().uuidString
            user.school = "\(i) " + UUID().uuidString
            user.age = 25
        }

        try? context.save()
    }

    func fetchAllRecs() {
        let request: NSFetchRequest<Rec> = Rec.fetchRequest()

        if let result = try? context.fetch(request) {
            result.forEach { print($0.first! + $0.last! + $0.title! ) }
        }
    }

    func deleteAllRecs() {
        let request: NSFetchRequest<Rec> = Rec.fetchRequest()

        if let result = try? context.fetch(request) {
            result.forEach { context.delete($0) }
        }

        try? context.save()
    }

    func deleteAllUsers() {
        let request: NSFetchRequest<User> = User.fetchRequest()

        if let result = try? context.fetch(request) {
            result.forEach { context.delete($0) }
        }

        try? context.save()
    }
}
