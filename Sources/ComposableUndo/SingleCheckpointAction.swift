import ComposableArchitecture

public protocol SingleCheckpointAction {
  static func checkpoint(_: CheckpointAction) -> Self
}

extension Reducer {
  public func trackCheckpoints<Value>(
    of toHistory: WritableKeyPath<State, CheckpointState<Value>>
  ) -> Self where Action: SingleCheckpointAction {
    trackCheckpoints(of: toHistory, in: /Action.checkpoint)
  }
}

extension Effect where Output: SingleCheckpointAction {
  public static func checkpoint(_ action: CheckpointAction) -> Self {
    .init(value: (/Output.checkpoint).embed(action))
  }
}

#if DEBUG
extension TestStore where ScopedState: Equatable, Action: (Equatable & SingleCheckpointAction) {
  public func receiveCheckpoint<Value>(
    _ expectedAction: CheckpointAction,
    of toState: WritableKeyPath<ScopedState, CheckpointState<Value>>,
    file: StaticString = #file,
    line: UInt = #line,
    _ update: @escaping (inout ScopedState) throws -> Void = { _ in }
  ) async {
      await receiveCheckpoint(expectedAction, in: /Action.checkpoint, of: toState, file: file, line: line, update)
  }
}

extension TestStore where ScopedState: Equatable, ScopedAction: SingleCheckpointAction {
  public func sendCheckpoint<Value>(
    _ action: CheckpointAction,
    of toState: WritableKeyPath<ScopedState, CheckpointState<Value>>,
    file: StaticString = #file,
    line: UInt = #line,
    _ update: @escaping (inout ScopedState) throws -> Void = { _ in }
  ) {
      sendCheckpoint(action, in: /ScopedAction.checkpoint, of: toState, file: file, line: line, update)
  }
}

extension TestStore.Step where Action: SingleCheckpointAction {
  public static func receiveCheckpoint<Value>(
    _ action: CheckpointAction,
    of toState: WritableKeyPath<ScopedState, CheckpointState<Value>>,
    file: StaticString = #file,
    line: UInt = #line,
    _ update: @escaping (inout ScopedState) throws -> Void = { _ in }
  ) -> Self {
    .receiveCheckpoint(action, in: /Action.checkpoint, of: toState, file: file, line: line, update)
  }
}

extension TestStore.Step where ScopedAction: SingleCheckpointAction {
  public static func sendCheckpoint<Value>(
    _ action: CheckpointAction,
    of toState: WritableKeyPath<ScopedState, CheckpointState<Value>>,
    file: StaticString = #file,
    line: UInt = #line,
    _ update: @escaping (inout ScopedState) throws -> Void = { _ in }
  ) -> Self {
    .sendCheckpoint(action, in: /ScopedAction.checkpoint, of: toState, file: file, line: line, update)
  }
}
#endif
