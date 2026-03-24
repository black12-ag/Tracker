class SyncWriteResult {
  const SyncWriteResult({required this.queued, required this.message});

  const SyncWriteResult.synced([this.message = 'Saved successfully.'])
    : queued = false;

  const SyncWriteResult.queued([
    this.message =
        'Saved offline. It will sync automatically when internet returns.',
  ]) : queued = true;

  final bool queued;
  final String message;
}
