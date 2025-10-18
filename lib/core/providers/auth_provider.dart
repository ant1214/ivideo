import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ivideo/core/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    // 获取当前用户
    _user = AuthService.currentUser;
    _isLoading = false;
    notifyListeners();

    // 监听认证状态变化
    AuthService.onAuthStateChange.listen((AuthState data) {
      final AuthState event = data;
      _user = event.session?.user;
      _isLoading = false;
      notifyListeners();
      
      if (_user != null) {
        if (kDebugMode) {
          print('✅ 用户已登录: ${_user!.email}');
        }
      } else {
        if (kDebugMode) {
          print('🔒 用户已退出登录');
        }
      }
    });
  }

  Future<void> logout() async {
    await AuthService.signOut();
    _user = null;
    notifyListeners();
  }

  // 更新用户信息（如果需要）
  void updateUser(User? user) {
    _user = user;
    notifyListeners();
  }
}