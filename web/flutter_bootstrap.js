// Custom bootstrap so that Flutter's own service worker is not registered.
//
// That worker is deprecated and now unregisters itself on activation, which
// would fight with the one registered from index.html at the same scope.
// Omitting serviceWorkerSettings leaves ours as the only registration.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load();
