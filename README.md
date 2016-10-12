# MOMenu

MOMenu is a menubar item with a plug-in architecture which allows admins to create anything that helps their fleet, from setting user preferences to reporting on machine status.

## Building

Requires [CocoaPods](https://cocoapods.org/) and [Xcode](https://developer.apple.com/xcode/downloads/) to compile.

Clone the repository, install necessary pods, then build the applications:

```
git clone https://github.com/google/macops-MOMenu
cd macops-MOMenu
pod install
xcodebuild -workspace MOMenu.xcworkspace -scheme MOMenu -configuration Release -derivedDataPath build
```

The built application will be in `./build/Build/Products/Release/MOMenu.app`

In order to use MOMenu, install suitable plugins to `/Library/MOMenu/PlugIns`.

An example Snake plugin is included in this repository.

To build and install the Snake plugin:

```
cd plugins/snake
xcodebuild
sudo mkdir -p /Library/MOMenu/PlugIns
sudo cp -r build/Release/Snake.bundle /Library/MOMenu/PlugIns
```

MOMenu and plugins must be codesigned with the same developer certificate in order to launch. To test the program without codesigning, launch it with the `nochecksignatures` flag:

```
../../build/Build/Products/Release/MOMenu.app/Contents/MacOS/MOMenu --nochecksignatures
```

MOMenu should appear in the menubar:

<img src="https://github.com/verycarefully/macops-MOMenu/raw/master/docs/momenu.png">

