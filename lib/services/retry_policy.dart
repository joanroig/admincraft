import 'package:admincraft/services/connection_failure.dart';

/// What to do after a failed connection attempt, and what to say about it.
class RetryDecision {
  /// How long to wait before trying again, or null to stop.
  final Duration? delay;

  /// The whole message for the user: the diagnosis, plus what happens next.
  final String message;

  const RetryDecision({required this.delay, required this.message});

  bool get willRetry => delay != null;
}

/// Decides whether trying again is worth it.
///
/// Only failures that might pass on their own are retried. Everything else
/// needs a person: retrying a rejected key or a misspelled address just buries
/// the explanation under repeated attempts, which is what the app used to do
/// for every failure alike, reporting all of them as "connection lost".
RetryDecision decideRetry({
  required ConnectionFailure failure,
  required int attemptsMade,
  int maxRetries = 3,
}) {
  if (!failure.isTransient) {
    return RetryDecision(delay: null, message: failure.message);
  }

  if (attemptsMade >= maxRetries) {
    return RetryDecision(
      delay: null,
      message: '${failure.message} Gave up after ${maxRetries + 1} attempts.',
    );
  }

  final attempt = attemptsMade + 1;
  // Backing off rather than hammering: a server coming back up needs a moment,
  // and three attempts three seconds apart tell the user nothing new.
  final delay = Duration(seconds: 3 * attempt);
  return RetryDecision(
    delay: delay,
    message: '${failure.message} Retrying in ${delay.inSeconds}s '
        '($attempt of $maxRetries).',
  );
}
