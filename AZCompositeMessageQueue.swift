// ******************************************************************************
//
// Copyright © 2015, Adam Zdara. All rights reserved.
//
// All rights reserved. This source code can be used only for purposes specified
// by the given license contract signed by the rightful deputy of Adam Zdara.
// This source code can be used only by the owner of the license.
//
// Any disputes arising in respect of this agreement (license) shall be brought
// before the Municipal Court of Prague.
//
// ******************************************************************************

import Foundation

///
/// Composite message queue allows to observation of multiple queues with single subscription (messages receiver)
///
public class AZCompositeMessageQueue: AZMessageQueue
{
  
  // MARK: Types

  ///
  /// Composite observer handles callbacks, message identifiers and child queue observers
  ///
  public class CompositeObserver: Equatable
  {
    /// Observed message kind identifier
    let messageIdentifier: String
    /// Callback thet is invoked when any child queue observes message with specified kind identifier
    let callback: AZMessageObserverClosure
    /// Child queue observers handlers
    var subscribedChildObservers = [ChildObserver]()
    /// Super-class subscription observer
    var superObserver: AnyObject!
    
    init(messageIdentifier: String, callback: AZMessageObserverClosure)
    {
      self.messageIdentifier = messageIdentifier
      self.callback = callback
    }
  }
  
  ///
  /// Child queue observer wrapper
  ///
  private class ChildObserver
  {
    /// Child queue
    var queue: AZMessageQueue!
    /// Child queue's observer
    var observer: AnyObject!
   
    ///
    /// Designated initializer that subscribes to queue for messages with messageIdentifier
    ///
    /// - Parameters:
    ///     - queue: Subscribed child message queue
    ///     - messageIdentifier: Observed messages kind identifier
    ///     - callback: Callback that is subscribed to queue
    ///
    init(queue: AZMessageQueue, messageIdentifier: String, callback: AZMessageObserverClosure)
    {
      self.queue = queue
      self.observer = queue.subscribeForMessagesWithIdentifier(messageIdentifier, callback: callback)
    }
    
    ///
    /// Unsubscribes observer from child queue
    ///
    func unsubscribeObserver()
    {
       self.queue.unsubscribeObserver(self.observer)
    }
  }

  // MARK: Properties
  
  /// Child message queue that are observed
  private var queues = [AZMessageQueue]()
  /// Subscribed observers (handles child queues observers)
  private var observers = [CompositeObserver]()
  /// Synchronization semaphore
  private var semaphore = dispatch_semaphore_create(1)
  
  // MARK: AZMessageQueue
  
  override public func subscribeForMessagesWithIdentifier(messageIdentifier: String, callback: AZMessageObserverClosure) -> AZMessageObserver
  {
    self.lock()
    let compositeObserver = CompositeObserver(messageIdentifier: messageIdentifier, callback: callback)
    compositeObserver.superObserver = super.subscribeForMessagesWithIdentifier(messageIdentifier, callback: callback)
    self.observers.append(compositeObserver)
    for queue in self.queues
    {
      let childObserver = ChildObserver(
        queue: queue,
        messageIdentifier: messageIdentifier,
        callback: callback)
      compositeObserver.subscribedChildObservers.append(childObserver)
    }
    self.unlock()
    return compositeObserver
  }
  
  override public func unsubscribeObserver(observer: AZMessageObserver) -> Bool
  {
    self.lock()
    var retVal = false
    if let compositeObserver = observer as? CompositeObserver,
      let removedCompositeObserver = self.observers.removeObject(compositeObserver)
    {
      for childObserver in removedCompositeObserver.subscribedChildObservers
      {
        childObserver.unsubscribeObserver()
      }
      super.unsubscribeObserver(compositeObserver.superObserver)
      retVal = true
    }
    self.unlock()
    return retVal
  }
  
  // MARK: General
  
  ///
  /// Add child (input) queue. When queue is added after subscription then
  /// observer of composite queue will still get notifications from the new child queue.
  /// - Parameter queue: Added child queue
  ///
  public func addChildQueue(queue: AZMessageQueue)
  {
    self.lock()
    self.queues.append(queue)
    for compositeObserver in self.observers
    {
      let childObserver = ChildObserver(
        queue: queue,
        messageIdentifier: compositeObserver.messageIdentifier,
        callback: compositeObserver.callback)
      compositeObserver.subscribedChildObservers.append(childObserver)
    }
    self.unlock()
  }
  
  ///
  /// Remove child (input) queue
  /// - Parameter queue: Child queue that wil be removed
  ///
  public func removeChildQueue(queue: AZMessageQueue)
  {
    self.lock()
    if let removedQueue = self.queues.removeObject(queue)
    {
      for compositeObserver in self.observers
      {
        for childObserver in compositeObserver.subscribedChildObservers
        {
          if childObserver.queue == removedQueue
          {
            childObserver.unsubscribeObserver()
          }
        }
      }
    }
    self.unlock()
  }
 
  // MARK: Locking

  private func lock()
  {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER)
  }
  
  private func unlock()
  {
    dispatch_semaphore_signal(self.semaphore)
  }
  
}

public func ==(lhs: AZCompositeMessageQueue.CompositeObserver, rhs: AZCompositeMessageQueue.CompositeObserver) -> Bool
{
  return lhs === rhs
}
