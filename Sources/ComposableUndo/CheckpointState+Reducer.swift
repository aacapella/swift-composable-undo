import Combine
import ComposableArchitecture
import Foundation

extension Reducer {
  public func trackCheckpoints<Value>(
    of toHistory: WritableKeyPath<State, CheckpointState<Value>>,
    in toHistoryAction: CasePath<Action, CheckpointAction>
  ) -> Self {
    .combine(
      Reducer { state, action, _ in
        guard let historyAction = toHistoryAction.extract(from: action) else {
          return .none
        }
        let effect = state[keyPath: toHistory].reduce(action: historyAction)
        return effect.map(toHistoryAction.embed)
      },
      self
    )
  }
}

extension CheckpointState {
  func copy(of value: Value) -> Value {
    copier?(value) ?? value
  }

  fileprivate mutating func reduce(action: CheckpointAction) -> Effect<CheckpointAction, Never> {
    switch action {
    case let .register(label):
      stack.removeSubrange(stack.index(after: currentIndex)...)
      stack.append(.init(value: copy(of: wrappedValue), label: label))
      currentIndex = stack.index(after: currentIndex)
      manager?.registerUndo(label, with: managerActions)
      return .none
    case .undo:
      guard canUndo else {
        return .none
      }
      if let manager = manager {
        manager.undo()
        return .none
      } else {
        return .init(value: .finishedUndo)
      }
    case .redo:
      guard canRedo else {
        return .none
      }
      if let manager = manager {
        manager.redo()
        return .none
      } else {
        return .init(value: .finishedRedo)
      }
    case .removeAll:
      currentIndex = stack.startIndex
      stack.removeSubrange(stack.index(after: currentIndex)...)
      manager?.removeAllActions(withTarget: managerActions)
      return .none
    case .finishedUndo:
      currentIndex = stack.index(before: currentIndex)
      wrappedValue = copy(of: stack[currentIndex].value)
      return .none
    case .finishedRedo:
      currentIndex = stack.index(after: currentIndex)
      wrappedValue = copy(of: stack[currentIndex].value)
      return .none
    case let .attachManager(.some(manager)):
      self.manager = manager
      currentIndex = stack.startIndex
      stack.removeSubrange(stack.index(after: currentIndex)...)
      manager.groupsByEvent = false
      return managerActions.eraseToEffect().cancellable(id: manager)
    case .attachManager(.none), .detachManager:
      guard let manager = manager else {
        return .none
      }
      self.manager = nil
      manager.removeAllActions(withTarget: managerActions)
      return .cancel(id: manager)
    }
  }
}

extension UndoManager {
  fileprivate func registerUndo(_ label: String, with subject: PassthroughSubject<CheckpointAction, Never>) {
    beginUndoGrouping()
    defer { endUndoGrouping() }
    registerUndo(withTarget: subject) { [weak self] subject in
      subject.send(.finishedUndo)
      self?.registerRedo(label, with: subject)
    }
    setActionName(label)
  }

  fileprivate func registerRedo(_ label: String, with subject: PassthroughSubject<CheckpointAction, Never>) {
    beginUndoGrouping()
    defer { endUndoGrouping() }
    registerUndo(withTarget: subject) { [weak self] subject in
      subject.send(.finishedRedo)
      self?.registerUndo(label, with: subject)
    }
    setActionName(label)
  }
}
