import Foundation

/// The raw communication protocol used to transfer data over an NSXPCConnection.
///
/// Both the remote and local systems must use this protocol.
@objc public protocol XPCConnectionSessionCommunicationProtocol {
	typealias Reply = @Sendable (Data) -> Void

	func processMessage(_ data: Data)
	func processMessage(_ data: Data, reply: @escaping Reply)
}

enum XPCConnectionSessionError: Error {
	case serviceTypeMismatch
	case replyDecodeFailure(Error)
}

private final class IncomingHandler {
	var messageHandler: (XPCReceivedConnectionMessage) -> (Encodable)?

	init() {
		self.messageHandler = { _ in return nil }
	}
}

extension IncomingHandler: XPCConnectionSessionCommunicationProtocol {
	func processMessage(_ data: Data) {
		let message = XPCReceivedConnectionMessage(data: data, replyHandler: { _ in
			print("warning: dropping unexpected reply")
		})

		let value = messageHandler(message)

		if value != nil {
			print("warning: returning non-nil from a message that does not expect a reply")
		}
	}

	func processMessage(_ data: Data, reply: @escaping XPCConnectionSessionCommunicationProtocol.Reply) {
		let message = XPCReceivedConnectionMessage(data: data, replyHandler: reply)

		let value = messageHandler(message)

		if value != nil {
			print("warning: returning non-nil from a message that does not expect a reply")
		}
	}
}

/// A class that emulates the behavior and API of `XPCSession`.
public final class XPCConnectionSession: @unchecked Sendable {
	private let connection: NSXPCConnection
	private let queue = DispatchQueue(label: "com.chimehq.XPCConnectionSession")
	private let channelHandler = IncomingHandler()
	
	public init(connection: NSXPCConnection) {
		self.connection = connection

		precondition(connection.exportedInterface == nil)
		precondition(connection.exportedObject == nil)
		precondition(connection.remoteObjectInterface == nil)

		queue.async {
			let interface = NSXPCInterface(with: XPCConnectionSessionCommunicationProtocol.self)

			self.connection.exportedInterface = interface
			self.connection.exportedObject = self.channelHandler
			self.connection.remoteObjectInterface = interface

			self.connection.interruptionHandler = {
				print("interruped?")
			}

			self.connection.activate()
		}
	}

	public func activate() throws {
		connection.activate()
	}

	public func cancel() {
		connection.invalidate()
	}
}

extension XPCConnectionSession {
	public func send<Message>(_ message: Message) throws where Message : Encodable {
		let messageData = try JSONEncoder().encode(message)
		
		queue.async {
			guard let channel = self.connection.remoteObjectProxy as? XPCConnectionSessionCommunicationProtocol else {
				return
			}
			
			channel.processMessage(messageData)
		}
	}
	
	public func send<Message, Reply>(_ message: Message, replyHandler: @Sendable @escaping (Result<Reply, Error>) -> Void) throws where Message : Encodable, Reply : Decodable {
		let messageData = try JSONEncoder().encode(message)
		
		queue.async {
			let proxy = self.connection.remoteObjectProxyWithErrorHandler { error in
				replyHandler(.failure(error))
			}
			
			guard let channel = proxy as? XPCConnectionSessionCommunicationProtocol else {
				replyHandler(.failure(XPCConnectionSessionError.serviceTypeMismatch))
				return
			}
			
			channel.processMessage(messageData) { data in
				do {
					let reply = try JSONDecoder().decode(Reply.self, from: data)
					
					replyHandler(.success(reply))
				} catch {
					replyHandler(.failure(XPCConnectionSessionError.replyDecodeFailure(error)))
				}
			}
		}
	}
}

extension XPCConnectionSession {
	public func setIncomingMessageHandler(_ incomingMessageHandler: @escaping (XPCReceivedConnectionMessage) -> (Encodable)?) {
		queue.async {
			// I'm not sure how, or even if it is possible to get rid of this warning and also maintain backwards compatibility
			self.channelHandler.messageHandler = incomingMessageHandler
		}
	}
}

extension XPCConnectionSession {
	/// Sends a message to the remote service.
	@_unsafeInheritExecutor
	public func send<Message: Encodable, Reply: Decodable & Sendable>(_ message: Message) async throws -> Reply {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Reply, any Error>) in
			do {
				try send(message) { continuation.resume(with: $0) }
			} catch {
				continuation.resume(throwing: error)
			}
		}
	}
}
