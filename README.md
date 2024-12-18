# SwiftGodotIntegrate #

A simple macOS command line tool that can create new Godot projects with SwiftGodot or integrate Swift support into already existing ones.
***Pretty much work in progress, currently only supports debug builds and macos-arm64 architecure.***

## Installation:
> Right now SwiftGodotIntegrate can be used by manually building and copying executable to your project folder or directly from Xcode by setting custom working directory and launch arguments in scheme properties.

### Integrating SwiftGodot into existing project ###

```
cd /Path/To/Your/Project
./SwiftGodotIntegrate -a integrate
```

This will create and configure a SwiftPackage for your SwiftGodot code

### Creating new project ###

```
cd /Path/To/Your/Projects/Folder
mkdir YourProjectName
cd YourProjectName
./SwiftGodotIntegrate -a integrate --create-project --project-name YourProjectName
```

### Building and running ###

```
cd /Path/To/Your/Project
./SwiftGodotIntegrate -a build
```

This will build Swift package, copy all neccesary .dlyb files and create .gdextension file.
You can also use `./SwiftGodotIntegrate -a run` to build your game and run it right away.
