import "package:enough_mail/enough_mail.dart";

class EmailService {
  static const String _imapServer = 'qasid.iitk.ac.in';
  static const int _imapPort = 993;
  static String username = '';
  static String password = '';

  ImapClient? _imapClient;
  bool _isConnected = false;

  setUsernamePassword(String _username, String _password) {
    username = _username;
    password = _password;
  }

  Future<bool> connect() async {
    try {
      _imapClient = ImapClient(isLogEnabled: false);
      await _imapClient!.connectToServer(
        _imapServer,
        _imapPort,
        isSecure: true,
      );
      await _imapClient!.login(username, password);
      _isConnected = true;
      return true;
    } catch (e) {
      print('Connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<List<MimeMessage>> fetchEmails({
    int page = 0,
    int batchSize = 10,
  }) async {
    if (!_isConnected || _imapClient == null) {
      throw Exception('Not connected to server');
    }

    try {
      final mailbox = await _imapClient!.selectInbox();

      // Get the last 'batchSize' messages
      final totalMessages = mailbox.messagesExists;
      final startIndex =
          totalMessages > batchSize
              ? totalMessages - (page * batchSize)
              : totalMessages;
      final endIndex = startIndex + batchSize - 1;

      final sequenceToFetch = MessageSequence.fromRange(startIndex, endIndex);

      final fetchResult = await _imapClient!.fetchMessages(
        sequenceToFetch,
        'BODY.PEEK[]',
      );

      return fetchResult.messages.reversed
          .toList(); // Reverse to show newest first
    } catch (e) {
      print('Fetch error: $e');
      return [];
    }
  }

  Future<void> disconnect() async {
    if (_isConnected && _imapClient != null) {
      await _imapClient!.logout();
      _isConnected = false;
    }
  }
}
