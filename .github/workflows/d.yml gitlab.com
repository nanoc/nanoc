# This workflow uses actions that are not certified by GitHub.
# They are provided by a third-party and are governed by
# separate terms of service, privacy policy, and support
# documentation.
name: D

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
    - uses: dlang-community/setup-dlang@7c3e57bdc1ff2d8994f00e61b3ef400e67d2d7ac

    - name: 'Build & Test'
      run: |
        # Build the project, with its main file included, without unittests
        dub build --compiler=$DC
        # Build and run tests, as defined by `unittest` configuration
        # In this mode, `mainSourceFile` is excluded and `version (unittest)` are included
        # See https://dub.pm/package-format-json.html#configurations
        dub test --compiler=$DC
