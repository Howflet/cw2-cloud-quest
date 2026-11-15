import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/challenge_service.dart';
import '../services/coach_service.dart';
import '../services/reward_service.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key, required this.user});
  final User user;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late Future<Challenge> _challenge;
  late final Stream<Progress> _progress;
  late final Stream<Progress> _progressForButton;

  final _question = TextEditingController();
  bool _completing = false;
  bool _askingCoach = false;
  String? _coachReply;
  bool _coachError = false;

  @override
  void initState() {
    super.initState();
    _challenge = loadChallenge();
    _progress = watchMyProgress(widget.user.uid);
    _progressForButton = watchMyProgress(widget.user.uid);
  }

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _complete() async {
    setState(() => _completing = true);
    try {
      final result = await completeChallenge();
      if (!mounted) return;
      // An earlier hint described the old progress; clear it so it isn't stale.
      setState(() => _coachReply = null);
      _toast(
        result.alreadyCompleted
            ? 'Already completed. Your ${result.points} points and badge are unchanged.'
            : 'Quest complete! +${result.points} points and the "${result.badgeId}" badge.',
      );
    } on FirebaseFunctionsException catch (error) {
      debugPrint('completeToday failed: ${error.code}');
      if (mounted) {
        _toast(
          error.code == 'unauthenticated'
              ? 'Sign in again to complete the challenge.'
              : 'Couldn\'t complete the challenge right now. Try again.',
        );
      }
    } catch (error) {
      debugPrint('completeToday failed: $error');
      if (mounted) _toast('Couldn\'t reach the server. Try again.');
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _askCoach() async {
    if (_question.text.trim().isEmpty) {
      _toast('Type a question for the coach first.');
      return;
    }
    setState(() => _askingCoach = true);
    try {
      final reply = await getQuestHint(_question.text);
      if (!mounted) return;
      setState(() {
        _coachReply = reply;
        _coachError = false;
      });
    } on FirebaseFunctionsException catch (error) {
      debugPrint('Quest Coach request failed: ${error.code} ${error.message}');
      if (!mounted) return;
      setState(() {
        _coachReply = 'The coach is unavailable. Try again.';
        _coachError = true;
      });
    } catch (error) {
      debugPrint('Quest Coach request failed: $error');
      if (!mounted) return;
      setState(() {
        _coachReply = 'The coach is unavailable. Try again.';
        _coachError = true;
      });
    } finally {
      if (mounted) setState(() => _askingCoach = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Quest'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: logOut,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _challenge = loadChallenge());
            await _challenge.catchError(
              (_) => const Challenge(title: '', prompt: ''),
            );
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Signed in as ${widget.user.email ?? widget.user.uid}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              StreamBuilder<Progress>(
                stream: _progress,
                builder: (context, snap) =>
                    _ProgressCard(progress: snap.data, error: snap.hasError),
              ),
              const SizedBox(height: 16),
              FutureBuilder<Challenge>(
                future: _challenge,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.error_outline),
                        title: const Text('Couldn\'t load today\'s challenge'),
                        subtitle: const Text('Pull down to retry.'),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () =>
                              setState(() => _challenge = loadChallenge()),
                        ),
                      ),
                    );
                  }
                  final challenge = snap.data!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s challenge',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            challenge.title,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            challenge.prompt,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              StreamBuilder<Progress>(
                stream: _progressForButton,
                builder: (context, snap) {
                  final done = snap.data?.completed ?? false;
                  return FilledButton.icon(
                    key: const Key('complete'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: Icon(done ? Icons.check_circle : Icons.flag),
                    label: Text(
                      _completing
                          ? 'Completing…'
                          : done
                          ? 'Completed (tap to re-check)'
                          : 'Complete challenge',
                    ),
                    onPressed: _completing ? null : _complete,
                  );
                },
              ),
              const SizedBox(height: 28),
              Text('Quest Coach', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'The coach reads only your own quest and can\'t change points. '
                'You decide when to press Complete.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('question'),
                controller: _question,
                maxLength: maxQuestionLength,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _askingCoach ? null : _askCoach(),
                decoration: const InputDecoration(
                  labelText: 'Ask the Quest Coach for a hint',
                  border: OutlineInputBorder(),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('hint'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.lightbulb_outline),
                onPressed: _askingCoach ? null : _askCoach,
                label: Text(_askingCoach ? 'Thinking…' : 'Get hint'),
              ),
              if (_coachReply != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: _coachError
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    // Rendered as plain text, never as markup or a link.
                    child: SelectableText(_coachReply!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.error});
  final Progress? progress;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (error) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.error_outline),
          title: Text('Couldn\'t load your progress'),
        ),
      );
    }
    final p = progress;
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              p?.badgeId != null ? Icons.military_tech : Icons.stars_outlined,
              size: 36,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p == null ? 'Loading progress…' : '${p.points} points',
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    p?.badgeId == null
                        ? 'No badge yet'
                        : 'Badge: First Quest (${p!.badgeId})',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
