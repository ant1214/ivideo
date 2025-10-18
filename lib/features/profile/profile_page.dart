
import 'package:flutter/material.dart';
import 'package:ivideo/core/services/favorite_service.dart';
import 'package:ivideo/core/services/watch_history_service.dart';
import 'package:ivideo/core/supabase/supabase_client.dart';
import 'package:provider/provider.dart';
import 'package:ivideo/core/providers/auth_provider.dart';
import 'package:ivideo/shared/models/video_model.dart';
import 'package:ivideo/shared/widgets/video_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userMetadata;

  @override
  void initState() {
    super.initState();
    _loadUserMetadata();
  }

  void _loadUserMetadata() {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userMetadata = user.userMetadata;
      });
    }
  }

  String _getDisplayName() {
    final displayName = _userMetadata?['display_name'] as String?;
    return displayName?.isNotEmpty == true ? displayName! : '未命名用户';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isLoggedIn) {
            return _buildNotLoggedIn();
          }
          
          return Column(
            children: [
              _buildUserInfoCard(authProvider),
              _buildTabBar(),
              Expanded(
                child: _buildContent(authProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '尚未登录',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '登录后查看个人中心',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回首页'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(AuthProvider authProvider) {
    final displayName = _getDisplayName();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${_formatUserId(authProvider.user?.id)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '注册时间: ${_formatRegistrationTime(authProvider.user?.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTabItem('用户信息', 0),
          _buildTabItem('我的收藏', 1),
          _buildTabItem('观看历史', 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String text, int index) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AuthProvider authProvider) {
    switch (_selectedIndex) {
      case 0: return _buildUserInfo();
      case 1: return _buildFavorites();
      case 2: return _buildWatchHistory();
      default: return _buildUserInfo();
    }
  }

  Widget _buildUserInfo() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final displayName = _getDisplayName();
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoItem('显示名称', displayName),
            _buildInfoItem('用户ID', _formatUserId(user?.id)),
            _buildInfoItem('邮箱', user?.email ?? '未知'),
            _buildInfoItem('注册时间', _formatRegistrationTime(user?.createdAt)),
            _buildInfoItem('最后登录', _formatLastSignIn(user?.lastSignInAt)),
            _buildInfoItem('会员状态', '免费用户'),
            const SizedBox(height: 20),
            _buildActionButton('编辑资料', Icons.edit, _showEditProfileDialog),
            _buildActionButton('修改密码', Icons.lock, _showChangePasswordDialog),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog() {
    final displayName = _getDisplayName();
    final TextEditingController displayNameController = TextEditingController(text: displayName == '未命名用户' ? '' : displayName);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('编辑资料'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: '显示名称',
                    border: OutlineInputBorder(),
                    hintText: '请输入显示名称',
                    prefixIcon: Icon(Icons.person),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  '显示名称将在个人中心和评论中显示',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: displayNameController.text.trim().isEmpty ? null : () async {
                  final newDisplayName = displayNameController.text.trim();

                  // 显示加载
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  try {
                    // 更新用户元数据
                    final response = await SupabaseService.client.auth.updateUser(
                      UserAttributes(
                        data: {
                          'display_name': newDisplayName,
                        },
                      ),
                    );

                    Navigator.pop(context); // 关闭加载对话框

                    if (response.user != null) {
                      // 更新本地状态
                      setState(() {
                        _userMetadata = response.user?.userMetadata;
                      });
                      
                      Navigator.pop(context); // 关闭编辑对话框
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('资料更新成功')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('更新失败')),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context); // 关闭加载对话框
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('更新失败: $e')),
                    );
                  }
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFavorites() {
    return FutureBuilder<List<Video>>(
      future: FavoriteService.getUserFavoriteVideos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('加载失败', style: TextStyle(fontSize: 16, color: Colors.red)),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(), 
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        final favoriteVideos = snapshot.data ?? [];
        
        if (favoriteVideos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('暂无收藏', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                const Text(
                  '收藏你喜欢的视频，方便以后观看', 
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favoriteVideos.length,
          itemBuilder: (context, index) {
            final video = favoriteVideos[index];
            return VideoCard(
              video: video,
              onTap: () {
                // 添加点击处理
                print('点击收藏视频: ${video.title}');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWatchHistory() {
    return FutureBuilder<List<Video>>(
      future: WatchHistoryService.getUserWatchHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  '加载失败',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final historyVideos = snapshot.data ?? [];
        
        if (historyVideos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  '暂无观看历史',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  '观看视频后，历史记录会出现在这里',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return Column(
          children: [
            // 清空历史按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    '观看历史',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('清空历史'),
                    onPressed: _showClearHistoryDialog,
                  ),
                ],
              ),
            ),
            // 视频列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: historyVideos.length,
                itemBuilder: (context, index) {
                  final video = historyVideos[index];
                  return VideoCard(video: video, onTap: () {  },);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空观看历史'),
        content: const Text('确定要清空所有观看历史吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              // 先关闭对话框
              Navigator.pop(context);
              
              // 显示加载 SnackBar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('正在清空观看历史...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              
              try {
                final success = await WatchHistoryService.clearWatchHistory();
                
                // 无论成功与否，都刷新页面
                if (mounted) {
                  setState(() {});
                }
                
                // 隐藏加载 SnackBar
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('观看历史已清空'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('清空失败'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                // 隐藏加载 SnackBar 并显示错误
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('清空失败: $e'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(text),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onPressed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('退出登录', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    Navigator.pop(context);
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('播放设置'),
            Text('通知设置'),
            Text('隐私设置'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('修改密码'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: '新密码',
                    border: OutlineInputBorder(),
                    hintText: '至少6位字符',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: '确认新密码',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 8),
                if (newPasswordController.text.isNotEmpty &&
                    confirmPasswordController.text.isNotEmpty &&
                    newPasswordController.text != confirmPasswordController.text)
                  const Text('两次输入的密码不一致', style: TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              TextButton(
                onPressed: () async {
                  final newPassword = newPasswordController.text.trim();
                  final confirmPassword = confirmPasswordController.text.trim();

                  if (newPassword.isEmpty || newPassword.length < 6 || newPassword != confirmPassword) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请检查密码输入')),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    await SupabaseService.client.auth.updateUser(UserAttributes(password: newPassword));
                    Navigator.pop(context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码修改成功')));
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败: $e')));
                  }
                },
                child: const Text('确认修改'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 时间格式化方法
  String _formatRegistrationTime(String? createdAt) {
    if (createdAt == null) return '未知';
    try {
      final dateTime = DateTime.parse(createdAt);
      final localTime = dateTime.toLocal();
      return '${localTime.year}年${localTime.month}月${localTime.day}日 ${_formatTime(localTime)}';
    } catch (e) {
      return '未知';
    }
  }

  String _formatLastSignIn(String? lastSignInAt) {
    if (lastSignInAt == null) return '未知';
    try {
      final dateTime = DateTime.parse(lastSignInAt);
      final localTime = dateTime.toLocal();
      final now = DateTime.now();
      
      if (localTime.day == now.day && localTime.month == now.month && localTime.year == now.year) {
        return '今天 ${_formatTime(localTime)}';
      }
      
      final yesterday = now.subtract(const Duration(days: 1));
      if (localTime.day == yesterday.day && localTime.month == yesterday.month && localTime.year == yesterday.year) {
        return '昨天 ${_formatTime(localTime)}';
      }
      
      return '${localTime.year}年${localTime.month}月${localTime.day}日 ${_formatTime(localTime)}';
    } catch (e) {
      return '未知';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatUserId(String? userId) {
    if (userId == null || userId.isEmpty) return '未知';
    if (userId.length < 8) return userId;
    return '${userId.substring(0, 8)}...';
  }
}