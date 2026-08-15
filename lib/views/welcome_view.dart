import 'package:admincraft/utils/url_utils.dart';
import 'package:flutter/material.dart';

/// Shown when no server has been configured yet.
///
/// A blank profile always exists so the connection getters have something to
/// read, and dropping straight into the workspace made that placeholder look
/// like a real server that simply would not connect. This says what Admincraft
/// needs before it can do anything, and offers the two ways of getting it.
class WelcomeView extends StatelessWidget {
  final VoidCallback onAddServer;
  final VoidCallback onImport;

  const WelcomeView({
    super.key,
    required this.onAddServer,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Centred because the column stretches its children, which
                // would otherwise force the image to the full width and
                // distort it once a fit is set.
                Center(
                  // BoxFit.fill is required, not cosmetic: the default is
                  // scaleDown, which never enlarges, so the 16px source
                  // rendered at 16px however large the box was asked to be.
                  // A multiple of 16 keeps the pixel grid exact.
                  child: Image.asset(
                    'assets/logo.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    isAntiAlias: false,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to Admincraft',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Admincraft manages Minecraft Bedrock and Java servers. '
                  'Add one to get started.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You will need', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        const _Requirement(
                          icon: Icons.dns_outlined,
                          text: 'A server address it can reach, over Tailscale, '
                              'a VPN or a LAN.',
                        ),
                        const _Requirement(
                          icon: Icons.key_outlined,
                          text: 'The bridge secret key, or the RCON password for '
                              'a direct Java connection.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAddServer,
                  icon: const Icon(Icons.add),
                  label: const Text('Add your first server'),
                ),
                const SizedBox(height: 10),
                // Second, because someone arriving from another device already
                // has everything and should not have to retype it.
                OutlinedButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Import from another device'),
                ),
                const SizedBox(height: 20),
                Text(
                  'No server yet?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () => UrlUtils.openDocumentation(),
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: const Text('Read the setup guide'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Requirement({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
