# XPCConnectionSession
Backwards-compatible implementation of XPCSession

The idea here is to make a version of the new [XPCSession][xpcsession] class that can be used on older OSes. With this you can migrate your code to new structure without needing to bump your minimum OS version. When that time finally does come, minimal code changes should be required to move over to the real `XPCSession`.

This thing is still pretty young, and is missing a lot of features. Plus, `XPCSession` is still in beta, and the API could change. But, I figured why not.

Features:

- Compatible with existing `NSXPCConnection` instances
- Swift concurrency support
- `XPCSession` extensions to add Swift concurrency support where possible

Note:

The wire protocol used here is not compatible with `XPCSession`. This means you cannot mix the two.

## Usage

```swift
let connection = NSXPCConnection(serviceName: "com.yourcompany.YourService")
let session = XPCConnectionSession(connection: connection)

Task {
    let reply: String? = try? await session.send("hello")

    print("got back: \(reply)")
}
```

## Suggestions or Feedback

We'd love to hear from you! Get in touch via an issue or pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

[xpcsession]: https://developer.apple.com/documentation/xpc/xpcsession
