import 'dart:convert';

class CommandAuditEntry {
  final DateTime occurredAt;
  final String command;
  final String source;
  final String outcome;

  const CommandAuditEntry({
    required this.occurredAt,
    required this.command,
    required this.source,
    required this.outcome,
  });

  Map<String, dynamic> toJson() => {
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'command': command,
    'source': source,
    'outcome': outcome,
  };

  String encode() => jsonEncode(toJson());

  factory CommandAuditEntry.decode(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    return CommandAuditEntry(
      occurredAt: DateTime.parse(json['occurredAt'] as String).toLocal(),
      command: json['command'] as String? ?? '',
      source: json['source'] as String? ?? 'terminal',
      outcome: json['outcome'] as String? ?? 'sent',
    );
  }
}
