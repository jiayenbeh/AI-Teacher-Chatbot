import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:ai_teacher_chatbot/models/message.dart';
import 'package:chat_bubbles/bubbles/bubble_normal.dart';
import 'package:ai_teacher_chatbot/services/llmservice.dart';
import 'package:ai_teacher_chatbot/services/ocrservice.dart';
import 'package:ai_teacher_chatbot/services/pickcrop_image.dart';
import 'package:ai_teacher_chatbot/ui/widgets/navigation_drawer.dart';
import 'package:flutter/material.dart';

//Main ChatScreen widget class
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// State class for ChatScreen
class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final GroqAiService _groqaiservice = GroqAiService();
  final OCRService _ocrService = OCRService();
  final PickCropImageService _pickCropImageService = PickCropImageService();

  // State Variables
  List<Message> msgs = [];
  bool isTyping = false;
  File? _imageFile;
  File? _croppedFile;

  // Function to pick and crop image
  Future<void> _pickAndCropImage() async {
    _imageFile = await _pickCropImageService.pickImage();
    if (_imageFile != null) {
      _croppedFile = await _pickCropImageService.cropImage(_imageFile!);
      if (_croppedFile != null) {
        final imageMessage = Message(true, '', _croppedFile);
        setState(() {
          msgs.insert(0, imageMessage);
        });
        await _processImage(imageMessage);
      }
    }
  }

  // Function to process cropped image using OCR service to extract text
  Future<void> _processImage(Message imageMessage) async {
    if (_croppedFile == null) return;
    final extractedText = await _ocrService.processImage(_croppedFile!);
    setState(() {
      final index = msgs.indexOf(imageMessage);
      if (index != -1) {
        msgs[index] = Message(true, extractedText, _croppedFile);
      }
    });

    if (extractedText.isNotEmpty) {
      sendMsg(extractedText, fromImage: true);
    }
  }

  // Function to send message to LLM service and response handling
  void sendMsg(String prompt, {bool fromImage = false}) async {
    _controller.clear();

    if (prompt.isNotEmpty) {
      setState(() {
        if (!fromImage) {
          msgs.insert(0, Message(true, prompt, null));
        }
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
            msgs.insert(
              0,
              Message(
                false,
                responseBody["choices"][0]["message"]["content"]
                    .toString()
                    .trimLeft(),
                null,
              ),
            );
          });
          scrollController.animateTo(0.0,
              duration: const Duration(seconds: 1), curve: Curves.easeOut);
        } else {
          throw Exception('API response does not contain the expected "choices" field');
        }
      } else {
        throw Exception('Failed to get response from LLaMA3: ${response.body}');
      }
    }
  }

  // Get size of image file
  Future<Size> _getImageSize(File image) async {
    final Completer<Size> completer = Completer();
    final Image imageFile = Image.file(image);
    imageFile.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(info.image.width.toDouble(), info.image.height.toDouble()));
      }),
    );
    return completer.future;
  }

  // To show Image and dialog together on chat
  void _showImageDialog(File image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<Size>(
          future: _getImageSize(image),
          builder: (BuildContext context, AsyncSnapshot<Size> snapshot) {
            if (snapshot.hasData) {
              final Size imageSize = snapshot.data!;
              final double aspectRatio = imageSize.width / imageSize.height;
              return Dialog(
                insetPadding: const EdgeInsets.all(10),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: (MediaQuery.of(context).size.width * 0.8) / aspectRatio,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(image),
                      fit: BoxFit.contain,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  // Build method for Chat Screen widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavigationDrawerWidget(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
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
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: isTyping ? msgs.length + 1 : msgs.length,
                  shrinkWrap: true,
                  reverse: true,
                  itemBuilder: (context, index) {
                    //Typing indicator
                    if (isTyping && index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BubbleNormal(
                            text: "Typing...",
                            isSender: false,
                            color: Colors.grey.shade200,
                          ),
                        ],
                      );
                    } else {
                      final adjustedIndex = isTyping ? index - 1 : index;
                      final msg = msgs[adjustedIndex];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: msg.isSender
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (msg.image != null)
                              GestureDetector(
                                onTap: () => _showImageDialog(msg.image!),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Image.file(
                                    msg.image!,
                                    width: 150,
                                    height: 150,
                                  ),
                                ),
                              ),
                            if (msg.msg.isNotEmpty)
                              BubbleNormal(
                                text: msg.msg,
                                isSender: msg.isSender,
                                color: msg.isSender
                                    ? Colors.blue.shade100
                                    : Colors.grey.shade200,
                              ),
                          ],
                        ),
                      );
                    }
                  },
                ),
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
                              sendMsg(value);
                            },
                            textInputAction: TextInputAction.send,
                            showCursor: true,
                            decoration: const InputDecoration(
                                border: InputBorder.none, hintText: "Type a prompt"),
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      sendMsg(_controller.text);
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
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _pickAndCropImage,
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(30)),
                      child: const Icon(
                        Icons.image,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Display "pick image button" when there are no messages
          if (msgs.isEmpty)
            Center(
              child: ElevatedButton.icon(
                onPressed: _pickAndCropImage,
                icon: const Icon(Icons.image, size: 48),
                label: const Text("Pick Image", style: TextStyle(fontSize: 24)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
