# Contributing guidelines

## Generate Protobuf

Using [Apple's `swift-protobuf`](https://github.com/apple/swift-protobuf/),
you can generate Swift code from [Protobuf files](https://developers.google.com/protocol-buffers/).

To generate schema definitions in Swift, you need to
[install `protoc`](https://github.com/apple/swift-protobuf/#building-and-installing-the-code-generator-plugin) first.
Then, run:

```sh
cd Sources/Format/Protobuf
protoc \
	--swift_opt=Visibility=Public \
	--swift_out=. schema.proto
```

> **Note:** We commented out `package biscuit.format.schema;` to avoid generating name prefixes
> like `struct Biscuit_Format_Schema_Biscuit` instead of `struct Biscuit`
