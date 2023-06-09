#if canImport(XPC)
import XPC

#if compiler(>=5.9)
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension XPCSession {
	/// Sends a message over the session to the destination service asynchronously and returns the reply.
	@_unsafeInheritExecutor
	public func send<Message: Encodable, Reply: Decodable>(_ message: Message) async throws -> Reply {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Reply, any Error>) in
			do {
				try send(message) { continuation.resume(with: $0) }
			} catch {
				continuation.resume(throwing: error)
			}
		}
	}
}
#endif
#endif
