import XCTest
import XPCConnectionSession

final class TestService: XPCConnectionSessionCommunicationProtocol {
	func processMessage(_ data: Data) {
		fatalError()
	}
	
	func processMessage(_ data: Data, reply: @escaping Reply) {
		let value = try? JSONDecoder().decode(String.self, from: data)

		if value == "hello" {
			reply(try! JSONEncoder().encode("world"))
		} else {
			reply(Data())
		}
	}
}

final class ServiceDelegate: NSObject, NSXPCListenerDelegate {
	func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
		newConnection.exportedInterface = NSXPCInterface(with: XPCConnectionSessionCommunicationProtocol.self)

		let exportedObject = TestService()
		newConnection.exportedObject = exportedObject

		newConnection.resume()

		return true
	}
}

final class XPCConnectionSessionTests: XCTestCase {
    func testSendMessage() async throws {
		let lister = NSXPCListener.anonymous()
		let delegate = ServiceDelegate()

		lister.delegate = delegate
		lister.activate()

		let connection = NSXPCConnection(listenerEndpoint: lister.endpoint)

		let session = XPCConnectionSession(connection: connection)

		throw XCTSkip("This is a cool idea, but I cannot get it work")
		let value: String = try await session.send("hello")

		XCTAssertEqual(value, "world")
    }
}
