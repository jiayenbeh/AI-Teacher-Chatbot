class Message {
  final bool isSender;
  final String msg;

  Message({required this.isSender, required this.msg});
}

List<Message> chatHistory = [];