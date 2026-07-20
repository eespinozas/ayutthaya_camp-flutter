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

### ios promote

```sh
[bundle exec] fastlane ios promote
```

Envía a revisión de App Store el último build de TestFlight de la versión actual (sin recompilar)

### ios enable_push

```sh
[bundle exec] fastlane ios enable_push
```

Habilita Push Notifications en el App ID y regenera el perfil (match force)

### ios live

```sh
[bundle exec] fastlane ios live
```

Muestra la versión publicada (live) y la versión en preparación/revisión

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
