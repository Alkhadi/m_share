import 'package:flutter/material.dart';

/// A simple bottom sheet to collect an input (e.g., email or phone number)
/// and invoke a callback when submitted.
class SendToSheet extends StatefulWidget {
  const SendToSheet(
      {super.key, required this.modeLabel, required this.onSubmit});

  final String modeLabel;
  final Future<void> Function(String) onSubmit;

  @override
  State<SendToSheet> createState() => _SendToSheetState();
}

class _SendToSheetState extends State<SendToSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send via ${widget.modeLabel}',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: widget.modeLabel.toLowerCase() == 'email'
                  ? TextInputType.emailAddress
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: widget.modeLabel,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final input = _controller.text.trim();
                  if (input.isEmpty) return;
                  await widget.onSubmit(input);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                child: const Text('Send'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
