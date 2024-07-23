import 'dart:convert';
import 'package:ai_teacher_chatbot/models/message.dart';
import 'package:chat_bubbles/bubbles/bubble_normal.dart';
import 'package:ai_teacher_chatbot/services/llmservice.dart';
import 'package:flutter/material.dart';
 
class HomeView extends StatefulWidget {
  const HomeView({super.key});
  
  @override
  State<HomeView> createState() => _HomeViewState();
}
 
class _HomeViewState extends State<HomeView> {
  final TextEditingController _controller = TextEditingController();
  ScrollController scrollController = ScrollController();
  final GroqAiService _groqaiservice = GroqAiService();
  
  List<Message> chatHistory = [];
  bool isTyping = false;
 
  void sendMsg() async {
    String prompt = _controller.text;
    _controller.clear();

    if (prompt.isNotEmpty) {
      setState(() {
        chatHistory.insert(0, Message(isSender: true, msg: prompt));
        isTyping = true;
      });
      scrollController.animateTo(0.0,
          duration: const Duration(seconds: 1), curve: Curves.easeOut);
      final response = await _groqaiservice.getLLaMA3Response(prompt);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody.containsKey('choices')) {
          setState(() {
              isTyping = false;
              chatHistory.insert(
                  0,
                  Message(
                      isSender: false,
                      msg: responseBody["choices"][0]["message"]["content"]
                          .toString()
                          .trimLeft()));
            });
            scrollController.animateTo(0.0,
                duration: const Duration(seconds: 1), curve: Curves.easeOut);
        } else {
          throw Exception('API response does not contain the expected "prompt" field');
        }
      } else {
        throw Exception('Failed to get response from LLaMA3: ${response.body}');
      }
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed : (){
                // Action to expand the navigation panel
                // Closed by default 
              },
            ),
            const Expanded(
              child: Center(
                child: 
                  Text(
                    "TeacherHelper",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      // fontFamily: ,
                      fontSize: 24,
                    )
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.edit_square),
              disabledColor: Colors.grey,
              onPressed : (){
                // Action to create new chat
                // Disabled when it is the new screen
              },
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        ),
      body: Column(
        children: [
          const SizedBox(
            height: 8,
          ),
          Expanded(
            child: ListView.builder(
                controller: scrollController,
                itemCount: chatHistory.length,
                shrinkWrap: true,
                reverse: true,
                itemBuilder: (context, index) {
                  return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: isTyping && index == 0
                          ? Column(
                              children: [
                                BubbleNormal(
                                  text: chatHistory[0].msg,
                                  isSender: true,
                                  color: Colors.blue.shade100,
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 16, top: 4),
                                  child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text("Typing...")),
                                )
                              ],
                            )
                          : BubbleNormal(
                              text: chatHistory[index].msg,
                              isSender: chatHistory[index].isSender,
                              color: chatHistory[index].isSender
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade200,
                            ));
                }),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (value) {
                          sendMsg();
                        },
                        textInputAction: TextInputAction.send,
                        showCursor: true,
                        decoration: const InputDecoration(
                            border: InputBorder.none, hintText: "Type a prompt..."),
                      ),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  sendMsg();
                },
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(30)),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              )
            ],
          ),
        ],
      ),
    );
  }
}
