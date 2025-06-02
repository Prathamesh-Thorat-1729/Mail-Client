import 'package:flutter/material.dart';
import "package:enough_mail/enough_mail.dart";
import 'package:intl/intl.dart';
import 'package:html/parser.dart' as html_parser;

class EmailDetailScreen extends StatelessWidget {
  final MimeMessage email;

  const EmailDetailScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final sender =
        email.from?.first?.personalName ??
        email.from?.first?.email ??
        'Unknown Sender';
    final senderEmail = email.from?.first?.email ?? '';
    final subject = email.decodeSubject() ?? 'No Subject';
    final date = email.decodeDate();
    final recipients = email.to?.map((addr) => addr.email).join(', ') ?? '';
    final cc = email.cc?.map((addr) => addr.email).join(', ') ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      'From',
                      '$sender${senderEmail.isNotEmpty ? ' <$senderEmail>' : ''}',
                    ),
                    if (recipients.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(context, 'To', recipients),
                    ],
                    if (cc.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(context, 'CC', cc),
                    ],
                    if (date != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        'Date',
                        DateFormat('MMM dd, yyyy at HH:mm').format(date),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Email Content Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEmailContent(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildEmailContent(BuildContext context) {
    String content = _extractEmailContent();

    if (content.isEmpty) {
      content = 'No content available';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Text(
        content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }

  String _extractEmailContent() {
    String content = '';

    // Try to get text content from various parts
    try {
      // First try to get plain text
      final plainText = email.decodeTextPlainPart();
      if (plainText != null && plainText.trim().isNotEmpty) {
        return plainText;
      }

      // Try to get HTML content and convert to text
      final htmlText = email.decodeTextHtmlPart();
      if (htmlText != null && htmlText.trim().isNotEmpty) {
        final document = html_parser.parse(htmlText);
        final textContent = document.body?.text ?? htmlText;
        if (textContent.trim().isNotEmpty) {
          return textContent;
        }
      }

      // Try to find text parts manually
      if (email.parts != null) {
        for (final part in email.parts!) {
          if (part.mediaType?.isText == true) {
            final partContent = part.decodeContentText();
            if (partContent != null && partContent.trim().isNotEmpty) {
              if (part.mediaType?.sub == MediaSubtype.textPlain) {
                return partContent;
              } else if (part.mediaType?.sub == MediaSubtype.textHtml) {
                final document = html_parser.parse(partContent);
                final textContent = document.body?.text ?? partContent;
                if (textContent.trim().isNotEmpty) {
                  return textContent;
                }
              }
            }
          }
        }
      }

      // Last resort: try to decode the main body
      if (email.body != null) {
        final bodyText = email.body!.bodyRaw;
        if (bodyText != null && bodyText.trim().isNotEmpty) {
          return bodyText;
        }
      }
    } catch (e) {
      print('Error extracting email content: $e');
    }

    return 'Unable to display email content';
  }
}
