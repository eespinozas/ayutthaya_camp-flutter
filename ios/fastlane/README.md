fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios setup

```sh
[bundle exec] fastlane ios setup
```

ONE-TIME setup: register the App ID, create the App Store Connect app record, and generate signing assets.

### ios certificates

```sh
[bundle exec] fastlane ios certificates
```

Download signing certificates & provisioning profiles (read-only).

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload a new beta to TestFlight

### ios diagnose

```sh
[bundle exec] fastlane ios diagnose
```

Diagnostic: list apps & bundle IDs visible to the API key

### ios builds

```sh
[bundle exec] fastlane ios builds
```

List recent TestFlight builds and their processing state

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
