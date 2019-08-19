
//
//  TestsViewController.swift
//  CoreDataObserver
//
//  Created by Almas Daumov on 8/15/19.
//  Copyright © 2019 Almas Daumov. All rights reserved.
//

import UIKit
import CoreData

class ObserversTestingViewController: UIViewController {

    @IBOutlet var textView: UITextView!

    let context = CoreDataInteractor.shared.context

    var recsDeletesObserver: AnyObject?
    var recsInsertsObserver: AnyObject?
    var recsUpdatesObserver: AnyObject?
    var recsAllChangesObserver: AnyObject?

    var userDeletesObserver: AnyObject?
    var userInsertsObserver: AnyObject?
    var userUpdatesObserver: AnyObject?
    var userAllChangesObserver: AnyObject?


    override func viewDidLoad() {
        super.viewDidLoad()
        setupObservers()
    }

    func setupObservers() {
        recsDeletesObserver = CoreDataInteractor.shared.observeDeletes(type: Rec.self) { recs in
            self.log(text: "\nRec deletions: \(recs.count)")
        }

        recsInsertsObserver = CoreDataInteractor.shared.observeInserts(type: Rec.self) { recs in
            self.log(text: "\nRec inserts: \(recs.count)")
        }

        recsUpdatesObserver = CoreDataInteractor.shared.observeUpdates(type: Rec.self) { recs in
            self.log(text: "\nRec updates: \(recs.count)")
        }

        recsAllChangesObserver = CoreDataInteractor.shared.observeAllChanges(type: Rec.self) { changes in
            self.log(text: "\nRec all changes: deletes: \(changes.deletes.count), inserts: \(changes.inserts.count), updates: \(changes.updates.count)")
        }

        userDeletesObserver = CoreDataInteractor.shared.observeDeletes(type: User.self) { users in
            self.log(text: "\nUser deletions: \(users.count)")
        }

        userInsertsObserver = CoreDataInteractor.shared.observeInserts(type: User.self) { users in
            self.log(text: "\nUser inserts: \(users.count)")
        }

        userUpdatesObserver = CoreDataInteractor.shared.observeUpdates(type: User.self) { users in
            self.log(text: "\nUser updates: \(users.count)")
        }

        userAllChangesObserver = CoreDataInteractor.shared.observeAllChanges(type: User.self) { changes in
            self.log(text: "\nUser all changes: deletes: \(changes.deletes.count), inserts: \(changes.inserts.count), updates: \(changes.updates.count)")
        }
    }

    private func log(text: String) {
        print(text)
        let separator = "---------------"
        textView.text = (textView.text ?? "") + "\n" + separator + text
        let bottom = CGPoint(x: 0, y: textView.contentSize.height -
            textView.bounds.height +
            textView.contentInset.bottom)
        textView.setContentOffset(bottom, animated: true)
    }
}

extension ObserversTestingViewController {

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


extension ObserversTestingViewController {
    @IBAction func insertUser() {
        let user = User(context: context)
        user.first = UUID().uuidString
        user.last = UUID().uuidString
        user.school = UUID().uuidString
        user.age = 25
        try? context.save()
    }

    @IBAction func deleteUser() {
        let request: NSFetchRequest<User> = .init(entityName: "User")
        request.fetchLimit = 1
        if let user = try? context.fetch(request).first {
            context.delete(user)
            try? context.save()
        }
    }

    @IBAction func updateUser() {
        let request: NSFetchRequest<User> = .init(entityName: "User")
        request.fetchLimit = 1
        if let user = try? context.fetch(request).first {
            user.first = UUID().uuidString
            user.last = UUID().uuidString
            try? context.save()
        }
    }

    @IBAction func insertRec() {
        let rec = Rec(context: context)
        rec.first = UUID().uuidString
        rec.last = UUID().uuidString
        rec.title = UUID().uuidString
        try? context.save()
    }

    @IBAction func deleteRec() {
        let request: NSFetchRequest<Rec> = .init(entityName: "Rec")
        request.fetchLimit = 1
        if let rec = try? context.fetch(request).first {
            context.delete(rec)
            try? context.save()
        }
    }

    @IBAction func updateRec() {
        let request: NSFetchRequest<Rec> = .init(entityName: "Rec")
        request.fetchLimit = 1
        if let rec = try? context.fetch(request).first {
            rec.first = UUID().uuidString
            rec.last = UUID().uuidString
            try? context.save()
        }
    }

    @IBAction func insertRecInBackground() {
        DispatchQueue.global().async {
            let bContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            bContext.parent = self.context

            let rec = Rec(context: bContext)
            rec.first = UUID().uuidString
            rec.last = UUID().uuidString
            rec.title = UUID().uuidString
            try? bContext.save()
        }
    }

    @IBAction func deleteRecInBackground() {
        DispatchQueue.global().async {
            let bContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            bContext.parent = self.context

            let request: NSFetchRequest<Rec> = .init(entityName: "Rec")
            request.fetchLimit = 1
            if let rec = try? bContext.fetch(request).first {
                bContext.delete(rec)
                try? bContext.save()
            }
        }
    }
}
