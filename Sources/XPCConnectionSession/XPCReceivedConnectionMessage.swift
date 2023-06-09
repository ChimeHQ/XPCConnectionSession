import Foundation

/// Emulates the behavior of `XPCReceivedMessage`.
public struct XPCReceivedConnectionMessage {
	private let data: Data
	private let replyHandler: XPCConnectionSessionCommunicationProtocol.Reply
	public let expectsReply: Bool
	public let isSync: Bool

	init(data: Data, replyHandler: @escaping XPCConnectionSessionCommunicationProtocol.Reply, expectsReply: Bool = true, isSync: Bool = false) {
		self.data = data
		self.replyHandler = replyHandler
		self.expectsReply = expectsReply
		self.isSync = isSync
	}

	public func decode<T>(as type: T.Type = T.self) throws -> T where T : Decodable {
		return try JSONDecoder().decode(type, from: data)
	}

	public func reply<Message>(_ object: Message) where Message : Encodable {
		do {
			let content = try JSONEncoder().encode(object)
			
			replyHandler(content)
		} catch {
			print("failed to encode \(object): \(error)")
		}
	}
}
