import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/chat_room/chat_screen.dart';
import 'package:oneroom_finder/post/room_details_screen.dart';

class UserPostsDialog extends StatelessWidget {
  final String userId;

  const UserPostsDialog({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return AlertDialog(
      title: const Text('내 게시글'),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('posts')
              .where('authorId', isEqualTo: userId) // authorId로 필터링
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('게시글이 없습니다.'),
              );
            }

            final posts = snapshot.data!.docs;

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final postData = posts[index].data() as Map<String, dynamic>;
                final postId = posts[index].id;

                // selectedOptions를 postData에서 가져오는 로직 수정
                List<String> selectedOptions = [];
                if (postData['options'] != null &&
                    postData['options'] is List) {
                  selectedOptions = (postData['options'] as List)
                      .map((option) {
                        if (option is Map<String, dynamic> &&
                            option.containsKey('option')) {
                          return option['option']
                              as String; // Map에서 'option' 값을 가져옴
                        }
                        return ''; // 값이 없으면 빈 문자열 반환
                      })
                      .where((option) => option.isNotEmpty)
                      .toList(); // 빈 문자열 제외
                } else {
                  selectedOptions = []; // 데이터가 없으면 빈 리스트로 설정
                }

                final parkingAvailable = postData['parkingAvailable'] == false;
                final moveInDate = postData['moveInDate'] == false;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12.0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomDetailsScreen(
                            postId: postId,
                            selectedOptions: selectedOptions,
                            parkingAvailable: parkingAvailable, // 주차 가능 여부 전달
                            moveInDate: moveInDate, // 입주 가능 여부 전달
                            //optionIcons: optionIcons,
                          ),
                        ),
                      );
                    },
                    leading: postData['imageUrl'] != null &&
                            postData['imageUrl'].isNotEmpty
                        ? Image.network(
                            postData['imageUrl'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(
                            width: 100,
                            height: 100,
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (postData['tag'] != null &&
                            postData['tag'].isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              postData['tag'],
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          postData['title'] ?? '제목 없음',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${postData['location'] ?? '위치 없음'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          postData['content'] ?? '내용 없음',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '후기 ${postData['review'] ?? 0}개',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat),
                              onPressed: () {
                                // 고유한 채팅방 ID를 생성 (userId와 postId를 기반으로)
                                final chatRoomId = '${userId}_${postId}_${DateTime.now().millisecondsSinceEpoch}';
                                final recipientName = postData['authorName'] ?? 'Unknown User'; // 작성자 이름

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatRoomId: chatRoomId,
                                      recipientName: recipientName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
