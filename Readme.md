# Swift Struct Builder Generator Xcode Source Editor Extension

An Xcode extension (plugin) to generate struct builders automatically.

## Install Swift Struct Builder Generator Xcode Source Editor Extension

- Close Xcode if it is open
- Download the latest release [here](https://github.com/2mawi2/BuilderGenerator/releases)
- Copy the app to the `Applications` folder.
- Open the app
- Select OK for '"Swift Struct Builder Generator for Xcode" wants access to control "Xcode"'
- Go to `System Preferences -> Extensions -> Xcode Source Editor` and make sure `Builder Generator` is enabled.
- Open Xcode

**Please note if using manual project paths before v0.25 you will have to select your project path again.**

## How to create a new Swift builder

- Open a file which contains one more structs you wish to generate a builder for.

Example:
```
class Foo {
    var name: String?
}
```
- Click `Editor -> SourceEditorExtension -> Generate Builder`.

## Recommended: assign a shortcut

- Select preferences `⌘,` in Xcode.
- Choose 'Key Bindings'.
- Search for 'Generate Builder'.
- Choose your preferred shortcut.

## Usage example

Open a struct called Foo that we wish to generator a builder for:

```
struct Foo: Equatable {
    var isActive: Bool
    var city: String?
    var countryIsoCode: String? = Locale.current.regionCode
    let aboutMe: String?
    let quote: String?
}
```
Generate the builder:

```
struct FooBuilder {
	var isActive: Bool = false
	var city: String?
	var countryIsoCode: String?
	var aboutMe: String?
	var quote: String?
	func build() -> Foo {
		return Foo(
			isActive: isActive,
			city: city,
			countryIsoCode: countryIsoCode,
			aboutMe: aboutMe,
			quote: quote
		)
	}
}
```
Extract the generated builder into its own file if you like, or leave it close the original file.
Then use the builder like:
```
var foo: Foo = FooBuilder(isActive: true).build()
```

## Disable or remove the plugin

To disable:

Go to `System Preferences -> Extensions` and deselect the extension under `Xcode Source Editor`.

To remove:

Delete the app.