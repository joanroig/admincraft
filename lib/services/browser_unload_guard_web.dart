import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.EventListener? _beforeUnloadListener;

/// Uses the browser's own leave-page confirmation because a Flutter dialog
/// cannot run after a tab reload or close has already started.
void setBrowserUnloadGuard(bool enabled) {
  if (enabled && _beforeUnloadListener == null) {
    void warnBeforeUnload(web.Event event) {
      event.preventDefault();
      (event as web.BeforeUnloadEvent).returnValue = '';
    }

    _beforeUnloadListener = warnBeforeUnload.toJS;
    web.window.addEventListener('beforeunload', _beforeUnloadListener);
    return;
  }

  if (!enabled && _beforeUnloadListener != null) {
    web.window.removeEventListener('beforeunload', _beforeUnloadListener);
    _beforeUnloadListener = null;
  }
}
