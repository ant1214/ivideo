import 'package:ivideo/core/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // 邮箱注册
  static Future<AuthResponse> signUp(String email, String password) async {
    return await SupabaseService.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  // 邮箱登录
  static Future<AuthResponse> signIn(String email, String password) async {
    return await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 退出登录
  static Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  // 获取当前用户
  static User? get currentUser {
    return SupabaseService.client.auth.currentUser;
  }

  // 检查是否已登录
  static bool get isLoggedIn {
    return SupabaseService.client.auth.currentUser != null;
  }

  // 监听认证状态变化（新版本 API）
  static Stream<AuthState> get onAuthStateChange {
    return SupabaseService.client.auth.onAuthStateChange;
  }

  // 获取用户会话
  static Session? get currentSession {
    return SupabaseService.client.auth.currentSession;
  }
}