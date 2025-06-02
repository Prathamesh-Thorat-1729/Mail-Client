import 'package:flutter/material.dart';
import "package:enough_mail/enough_mail.dart";
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maiit/EmailDetailScreen.dart';
import 'package:maiit/EmailService.dart';
import 'package:maiit/EmailTile.dart';
import 'package:maiit/LoginPage.dart';

class EmailListScreen extends StatefulWidget {
  final String username;
  final String password;
  EmailListScreen({super.key, required this.username, required this.password});

  @override
  State<EmailListScreen> createState() => _EmailListScreenState();
}

class _EmailListScreenState extends State<EmailListScreen> {
  final EmailService _emailService = EmailService();
  List<MimeMessage> _emails = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  final controller = ScrollController();
  int _currentPage = 1;
  int _batchSize = 10;

  @override
  void initState() {
    super.initState();
    _emailService.setUsernamePassword(widget.username, widget.password);

    _loadEmails();

    controller.addListener(() {
      if (controller.position.maxScrollExtent == controller.offset) {
        _currentPage++;
        _loadEmails();
      }
    });
  }

  Future<void> _loadEmails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final connected = await _emailService.connect();
      if (!connected) {
        throw Exception('Failed to connect to email server');
      }

      final emails = await _emailService.fetchEmails(
        page: _currentPage,
        batchSize: _batchSize,
      );
      if (emails.length < _batchSize) _hasMore = false;
      setState(() {
        _emails.addAll(emails);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            onPressed: () {
              FlutterSecureStorage().delete(key: "username");
              FlutterSecureStorage().delete(key: "password");

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_emails.isEmpty && _isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading emails...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load emails',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadEmails, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_emails.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64),
            SizedBox(height: 16),
            Text('No emails found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_isLoading) return;
        setState(() {
          _emails.clear();
          _currentPage = 1;
        });
        await _loadEmails();
      },
      child: ListView.builder(
        controller: controller,
        itemCount: _emails.length + 1,
        itemBuilder: (context, index) {
          if (index == _emails.length) {
            return Center(
              child: _hasMore ? CircularProgressIndicator() : Icon(Icons.block),
            );
          }

          final email = _emails[index];

          return EmailTile(
            email: email,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmailDetailScreen(email: email),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
