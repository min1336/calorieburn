// lib/friends_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, String>? _searchedUser;
  bool _isSearching = false;

  void _searchUser() async {
    final nickname = _searchController.text.trim();
    if (nickname.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchedUser = null;
    });

    final appState = context.read<AppState>();
    final user = await appState.findUserByNickname(nickname);

    // 위젯이 마운트된 상태인지 확인
    if (!mounted) return;

    setState(() {
      _searchedUser = user;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    // 랭킹 데이터에서 현재 사용자를 제외한 친구 목록을 필터링
    final friendsList = appState.rankings.where((user) => appState.friends.contains(user['uid'])).toList();


    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 관리'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 친구 검색 섹션 ---
            Text('닉네임으로 친구 찾기', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: '친구 닉네임',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUser,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- 검색 결과 ---
            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_searchedUser != null)
              Card(
                child: ListTile(
                  title: Text(_searchedUser!['nickname']!),
                  trailing: ElevatedButton(
                    child: const Text('친구 추가'),
                    onPressed: () {
                      final friendUid = _searchedUser!['uid']!;
                      if (appState.friends.contains(friendUid)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('이미 추가된 친구입니다.'), backgroundColor: Colors.orange),
                        );
                      } else {
                        appState.addFriend(friendUid);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${_searchedUser!['nickname']}님을 친구로 추가했습니다.'), backgroundColor: Colors.green),
                        );
                      }
                    },
                  ),
                ),
              )
            else if (!_isSearching && _searchController.text.isNotEmpty && _searchedUser == null)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: Text('검색 결과가 없습니다.')),
                ),


            const Divider(height: 40),

            // --- 내 친구 목록 ---
            Text('내 친구 목록 (${friendsList.length})', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Expanded(
              child: friendsList.isEmpty
                  ? const Center(child: Text('아직 친구가 없습니다. 친구를 추가해보세요!'))
                  : ListView.builder(
                itemCount: friendsList.length,
                itemBuilder: (context, index) {
                  final friendData = friendsList[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(friendData['nickname'] ?? '이름 없음'),
                      subtitle: Text('Lv. ${friendData['userLevel'] ?? 1}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () {
                          appState.removeFriend(friendData['uid']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${friendData['nickname']}님을 친구에서 삭제했습니다.')),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}