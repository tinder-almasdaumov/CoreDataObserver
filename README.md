# CoreDataObserver

This project is an attempt to improve our core data observers.

As of today CoreDataService uses NSFetchedResultsController for all observers, which might not be the most performant option for two reasons:
  1. It observes all changes - inserst, deletes, and updates; even when you are only interested in one type of change, for example deletes to do some additional clean up.
  2. It requires at least one sort descriptor, even though sometimes you might not necessarily care about the order of objects, therefore NSFetchedResultstController is doing all of that work for no reason.

The proposal is to utilize notifications that CoreData posts whenever changes happen:
  - `NSManagedObjectContextObjectsDidChange` and `NSManagedObjectContextDidSave`. 
  
  Both of those notifications have `userInfo` dictionary that contains all changes that happened to Core Data.
