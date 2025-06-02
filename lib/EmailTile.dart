import 'package:flutter/material.dart';
import "package:enough_mail/enough_mail.dart";
import 'package:intl/intl.dart';

class EmailTile extends StatelessWidget {
  final MimeMessage email;
  final VoidCallback onTap;

  const EmailTile({super.key, required this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sender =
        email.from?.first?.personalName ??
        email.from?.first?.email ??
        'Unknown Sender';
    final subject = email.decodeSubject() ?? 'No Subject';
    final date = email.decodeDate();
    final isUnread = !email.isSeen;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            sender.isNotEmpty ? sender[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          sender,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              style: TextStyle(
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing:
            isUnread
                ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                )
                : null,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final emailDate = DateTime(date.year, date.month, date.day);

    if (emailDate == today) {
      return DateFormat('HH:mm').format(date);
    } else if (emailDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat('MMM dd').format(date);
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
