#if DEBUG
import Foundation
import ComposableArchitecture
import UIKit


extension TestStore where ScopedState: Equatable, Action: Equatable {
  public func receiveCheckpoint<Value>(
    _ expectedAction: CheckpointAction,
    in toAction: CasePath<Action, CheckpointAction>,
    of toState: WritableKeyPath<ScopedState, CheckpointState<Value>>,
    file: StaticString = #file,
    line: UInt = #line,
    _ update: @escaping (inout ScopedState) throws -> Void = { _ in }
  ) async {
      await receive(toAction.embed(expectedAction), timeout:nil, { state in
          try update(&state)
          state[keyPath: toState].applyForTest(action: expectedAction)
      }, file: file, line: line)
  }
}

extension TestStore where ScopedState: Equatable {
  public func sendCheckpoint<Value>(
    _ action: CheckpointAction,
    in toAction: CasePath<ScopedAction, CheckpointAction>,
    of toState: WritableKeyPath<ScopedState, CheckpointState<Value>>,
    file: StaticString = #file,
    line: UInt = #line,
    _ update: @escaping (inout ScopedState) throws -> Void = { _ in }
  ) {
      send(toAction.embed(action), { state in
          try update(&state)
          state[keyPath: toState].applyForTest(action: action)
      }, file: file, line: line)
  }
}

extension TestStore.Step {
  public static func receiveCheckpoint<Value>(
    _ action: CheckpointAction,
    in toAction: CasePath<Action, CheckpointAction>,
    of toState: WritableKeyPath<ScopedState, CheckpointState<Value>>,
    file: StaticString = #file,
    line: UInt = #line,
    _ update: @escaping (inout ScopedState) throws -> Void = { _ in }
  ) -> Self {
    .receive(toAction.embed(action), file: file, line: line) { state in
      try update(&state)
      state[keyPath: toState].applyForTest(action: action)
    }
  }

  public static func sendCheckpoint<Value>(
    _ action: CheckpointAction,
    in toAction: CasePath<ScopedAction, CheckpointAction>,
    of toState: WritableKeyPath<ScopedState, CheckpointState<Value>>,
    file: StaticString = #file,
    line: UInt = #line,
    _ update: @escaping (inout ScopedState) throws -> Void = { _ in }
  ) -> Self {
    .send(toAction.embed(action), file: file, line: line) { state in
      try update(&state)
      state[keyPath: toState].applyForTest(action: action)
    }
  }
}

extension CheckpointState {
  fileprivate mutating func applyForTest(action: CheckpointAction) {
    switch action {
    case let .register(label):
      stack.removeSubrange(stack.index(after: currentIndex)...)
      stack.append(.init(value: copy(of: wrappedValue), label: label))
      currentIndex = stack.index(after: currentIndex)
    case .undo:
      return
    case .redo:
      return
    case .removeAll:
      currentIndex = stack.startIndex
      stack.removeSubrange(stack.index(after: currentIndex)...)
    case .finishedUndo:
      currentIndex = stack.index(before: currentIndex)
      wrappedValue = copy(of: stack[currentIndex].value)
    case .finishedRedo:
      currentIndex = stack.index(after: currentIndex)
      wrappedValue = copy(of: stack[currentIndex].value)
    case .attachManager:
      return
    case .detachManager:
      return
    }
  }
}
#endif
