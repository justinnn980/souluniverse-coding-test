import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/me_state.dart';

class _Counselor {
  final String id;
  final String name;
  final String specialty;
  const _Counselor({required this.id, required this.name, required this.specialty});
}

const _kCounselors = [
  _Counselor(id: 'counselor-1', name: '김지현 상담사', specialty: '불안·우울'),
  _Counselor(id: 'counselor-2', name: '이서준 상담사', specialty: '관계·소통'),
];

/// 홈 화면.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showNicknameDialog(BuildContext context) {
    final meState = context.read<MeState>();
    final controller = TextEditingController(text: meState.user?.nickname ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('닉네임 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '새 닉네임 입력',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                meState.updateNickname(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meState = context.watch<MeState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('소울유니버스'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: '닉네임 변경',
            onPressed: () => _showNicknameDialog(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '🍪 ${meState.cookie}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: meState.user == null
          ? const Center(child: CircularProgressIndicator())
          : const _HomeBody(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final meState = context.watch<MeState>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    meState.user!.nickname.substring(0, 1),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '안녕하세요, ${meState.user!.nickname}님!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '🍪 쿠키 ${meState.cookie}개 보유',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          '상담사 목록',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        ..._kCounselors.map(
          (c) => _CounselorCard(counselor: c, key: ValueKey(c.id)),
        ),
      ],
    );
  }
}

class _CounselorCard extends StatelessWidget {
  final _Counselor counselor;
  const _CounselorCard({required this.counselor, super.key});

  @override
  Widget build(BuildContext context) {
    final meState = context.watch<MeState>();
    final isFavorite = meState.favoriteCounselorIds.contains(counselor.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Text(
                counselor.name.substring(0, 1),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    counselor.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    counselor.specialty,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.redAccent,
              ),
              tooltip: isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
              onPressed: () {
                if (isFavorite) {
                  meState.removeFavoriteCounselor(counselor.id);
                } else {
                  meState.addFavoriteCounselor(counselor.id);
                }
              },
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: () => context.push(
                '/chat/demo-room?counselorName=${Uri.encodeComponent(counselor.name)}',
              ),
              child: const Text('채팅'),
            ),
          ],
        ),
      ),
    );
  }
}
