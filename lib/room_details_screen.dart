import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'comment.dart';
import 'post_service.dart';

class RoomDetailsScreen extends StatelessWidget {
  final String postId;

  const RoomDetailsScreen({super.key, required this.postId});

  Stream<DocumentSnapshot> fetchPostDetails() {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('원룸 상세 정보'),
        backgroundColor: Colors.orange,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                // 수정 버튼 클릭 시 다이얼로그 열기
                showDialog(
                  context: context,
                  builder: (context) {
                    return StreamBuilder<DocumentSnapshot>(
                      stream: fetchPostDetails(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Center(child: Text('오류가 발생했습니다.'));
                        }

                        final post =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final TextEditingController titleController =
                            TextEditingController(text: post['title'] ?? '');
                        final TextEditingController contentController =
                            TextEditingController(text: post['content'] ?? '');

                        String? type = post['type'] ?? '월세';
                        String? roomType = post['roomType'] ?? '원룸';
                        String? currentImageUrl = post['imageUrl'];
                        File? newImage;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              title: const Text('게시글 수정'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: titleController,
                                      decoration: const InputDecoration(
                                          labelText: '제목'),
                                    ),
                                    const SizedBox(height: 8.0),
                                    TextField(
                                      controller: contentController,
                                      decoration: const InputDecoration(
                                          labelText: '내용'),
                                      maxLines: 4,
                                    ),
                                    const SizedBox(height: 8.0),
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: '거래 유형',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: type,
                                      items: ['월세', '전세']
                                          .map((item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          type = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8.0),
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: '타입 선택',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: roomType,
                                      items: ['원룸', '투룸', '쓰리룸']
                                          .map((item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          roomType = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8.0),
                                    TextButton(
                                      onPressed: () async {
                                        final pickedFile = await ImagePicker()
                                            .pickImage(
                                                source: ImageSource.gallery);
                                        if (pickedFile != null) {
                                          setState(() {
                                            newImage = File(pickedFile.path);
                                          });
                                        }
                                      },
                                      child: const Text('사진 변경'),
                                    ),
                                    if (newImage != null)
                                      Image.file(newImage!, height: 100)
                                    else if (currentImageUrl != null)
                                      Image.network(currentImageUrl,
                                          height: 100),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final newTitle = titleController.text;
                                    final newContent = contentController.text;

                                    if (newTitle.isNotEmpty &&
                                        newContent.isNotEmpty) {
                                      await PostService().updatePost(
                                        postId,
                                        newTitle,
                                        newContent,
                                        type,
                                        roomType,
                                        newImage,
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('게시글이 수정되었습니다.')),
                                      );
                                      Navigator.of(context).pop(); // 다이얼로그 닫기
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('제목과 내용을 입력해주세요.')),
                                      );
                                    }
                                  },
                                  child: const Text('수정'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              } else if (value == 'delete') {
                // 삭제 버튼 클릭 시 처리
                PostService().deletePost(postId).then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('게시글이 삭제되었습니다.')),
                  );
                }).catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('게시글 삭제 중 오류 발생: $e')),
                  );
                });
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('게시글 수정'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('게시글 삭제'),
                ),
              ];
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: fetchPostDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('게시글이 존재하지 않습니다.'));
          }

          final post = snapshot.data!.data() as Map<String, dynamic>;
          final String tag = post['tag'] ?? '태그 없음';
          final String title = post['title'] ?? '제목 없음';
          final String content = post['content'] ?? '내용 없음';
          final String author = post['author'] ?? '익명';
          final int likes = post['likes'] ?? 0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      const Icon(Icons.thumb_up, color: Colors.orange),
                      const SizedBox(width: 8.0),
                      Text('$likes명이 좋아합니다.'),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  const Divider(),
                  const Text(
                    '댓글',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // 댓글 입력 필드
                  CommentInputField(postId: postId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
