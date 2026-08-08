# CompatForge Core Bridge

Mac-Win keeps the current SwiftUI and legacy Wine execution path while migration proceeds. `RuntimeClient`, `BottleClient`, and `DiagnosticsClient` are the new frontend boundaries; new UI features should depend on these protocols instead of constructing `WineRunner` or editing Bottle JSON directly.

`CompatForgeRuntimeClient` loads an explicitly selected `libcompatforge_ffi.dylib` with `dlopen`. It verifies ABI major `1`, creates an opaque Core context, compiles versioned JSON into a LaunchPlan, retrieves structured failures, and releases every Rust-owned object through the matching ABI function.

The bridge currently performs planning only. It does not download a Runtime, start Wine, mutate a Bottle, or replace the legacy launcher. The next integration step is a smoke command/test that builds `CompatForge` for both macOS architectures and compares its LaunchPlan with the legacy runner inputs before any execution routing changes.
