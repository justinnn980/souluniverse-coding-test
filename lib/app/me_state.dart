import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../repository/user_repository.dart';

/// 현재 로그인 사용자의 프로필·쿠키 잔액·즐겨찾기 상담사 목록을 관리합니다.
/// 앱 전역에서 MultiProvider로 제공되며, 여러 화면이 구독합니다.
class MeState extends ChangeNotifier {
  User? _user;
  int _cookie = 0;
  List<String> _favoriteCounselorIds = [];

  User? get user => _user;
  int get cookie => _cookie;
  List<String> get favoriteCounselorIds => _favoriteCounselorIds;

  Future<void> loadMe() async {
    final result = await UserRepository.instance.fetchMe();
    _user = result.user;
    _cookie = result.cookie;
    _favoriteCounselorIds = List.from(result.favoriteCounselorIds);
    notifyListeners();
  }

  Future<void> addFavoriteCounselor(String counselorId) async {
    _favoriteCounselorIds = [..._favoriteCounselorIds, counselorId];
    await UserRepository.instance.addFavorite(counselorId);
    notifyListeners();
  }

  Future<void> removeFavoriteCounselor(String counselorId) async {
    _favoriteCounselorIds = _favoriteCounselorIds
        .where((id) => id != counselorId)
        .toList();
    await UserRepository.instance.removeFavorite(counselorId);
    notifyListeners();
  }

  Future<void> updateNickname(String newNickname) async {
    _user = _user?.copyWith(nickname: newNickname);
    await UserRepository.instance.updateNickname(newNickname);
    notifyListeners();
  }

  void deductCookie(int amount) {
    _cookie -= amount;
    notifyListeners();
  }
}
