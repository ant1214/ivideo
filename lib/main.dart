
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ivideo/core/providers/auth_provider.dart';
import 'package:ivideo/core/supabase/supabase_client.dart';
import 'package:ivideo/features/home/home_page.dart' show HomePage;
import 'package:ivideo/features/auth/login_page.dart';
import 'package:ivideo/features/profile/profile_page.dart';
import 'package:ivideo/features/search/search_page.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 加载环境变量
  await dotenv.load(fileName: '.env');
  
  // 初始化Supabase
  await SupabaseService.initialize(); 
  developer.log('iVideo项目启动成功!', name: 'iVideo');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(), 
      child: MaterialApp(
        title: 'iVideo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[50],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.black),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[900],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
          ),
        ),
        debugShowCheckedModeBanner: false, 
        home: MainLayout(), 
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _selectedCategory = '全部';

  final List<CategoryItem> _categories = [
    CategoryItem(
      icon: Icons.grid_view_rounded,
      label: '全部',
      videoType: null,
    ),
    CategoryItem(
      icon: Icons.movie_rounded,
      label: '电影',
      videoType: '电影',
    ),
    CategoryItem(
      icon: Icons.tv_rounded,
      label: '电视剧',
      videoType: '电视剧',
    ),
    CategoryItem(
      icon: Icons.animation_rounded,
      label: '动漫',
      videoType: '动漫',
    ),
    CategoryItem(
      icon: Icons.mic_rounded,
      label: '综艺',
      videoType: '综艺',
    ),
    CategoryItem(
      icon: Icons.description_rounded,
      label: '纪录片',
      videoType: '纪录片',
    ),
    CategoryItem(
      icon: Icons.category_rounded,
      label: '其他',
      videoType: '其他',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        
        if (isMobile) {
          return _buildMobileLayout(authProvider);
        } else {
          return _buildDesktopLayout(authProvider);
        }
      },
    );
  }

  // 手机端布局
  Widget _buildMobileLayout(AuthProvider authProvider) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iVideo'),
        backgroundColor: const Color.fromARGB(255, 158, 193, 209),
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(authProvider.isLoggedIn 
                ? Icons.account_circle 
                : Icons.account_circle_outlined),
            onPressed: () {
              if (authProvider.isLoggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(
                      onLoginSuccess: () => setState(() {}),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      drawer: _buildMobileDrawer(authProvider),
      body: CategoryVideosPage(
        videoType: _categories
            .firstWhere((cat) => cat.label == _selectedCategory)
            .videoType,
      ),
    );
  }

  // 手机端抽屉菜单
  Widget _buildMobileDrawer(AuthProvider authProvider) {
    return Drawer(
      child: Column(
        children: [
          // 抽屉头部
          Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'iVideo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // 用户信息（如果已登录）
          if (authProvider.isLoggedIn && authProvider.user != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.user!.email!.split('@').first,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          authProvider.user!.email!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // 分类标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Text(
                  '视频分类',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // 分类列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final item = _categories[index];
                final isSelected = _selectedCategory == item.label;
                
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? const Color(0xFFFF6428) : Colors.grey[600],
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? const Color(0xFFFF6428) : Colors.grey[700],
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: const Color(0xFFFF6428).withOpacity(0.1),
                  onTap: () {
                    setState(() {
                      _selectedCategory = item.label;
                    });
                    Navigator.pop(context); // 关闭抽屉
                  },
                );
              },
            ),
          ),
          
          // 底部退出登录按钮（如果已登录）
          if (authProvider.isLoggedIn)
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    authProvider.logout();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('退出登录'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 桌面端布局
  Widget _buildDesktopLayout(AuthProvider authProvider) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧导航栏
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Logo区域
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.purple.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'iVideo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // 分类标题
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        '视频分类',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 分类菜单
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final item = _categories[index];
                      final isSelected = _selectedCategory == item.label;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategory = item.label;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? const Color(0xFFFF6428).withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFF6428).withOpacity(0.3)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 22,
                                    color: isSelected
                                        ? const Color(0xFFFF6428)
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected 
                                          ? FontWeight.w600 
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFFFF6428)
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // 底部留出一些空间
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // 右侧内容区域
          Expanded(
            child: Column(
              children: [
                // 顶部AppBar
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 24),
                      Expanded(
                        child: Container(
                          height: 40,
                          constraints: const BoxConstraints(maxWidth: 500),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SearchPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Icon(Icons.search, color: Colors.grey[500], size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  '搜索视频...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, color: Colors.grey[700]),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('暂无新通知')),
                          );
                        },
                        tooltip: '通知',
                      ),
                      IconButton(
                        icon: Icon(
                          authProvider.isLoggedIn
                              ? Icons.account_circle
                              : Icons.account_circle_outlined,
                          color: Colors.grey[700],
                        ),
                        onPressed: () {
                          if (authProvider.isLoggedIn) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(
                                  onLoginSuccess: () {
                                    setState(() {});
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        tooltip: authProvider.isLoggedIn ? '个人中心' : '登录',
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
                
                // 主内容区域
                Expanded(
                  child: CategoryVideosPage(
                    videoType: _categories
                        .firstWhere((cat) => cat.label == _selectedCategory)
                        .videoType,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItem {
  final IconData icon;
  final String label;
  final String? videoType;

  CategoryItem({
    required this.icon,
    required this.label,
    required this.videoType,
  });
}

// 根据分类显示视频的页面
class CategoryVideosPage extends StatelessWidget {
  final String? videoType;

  const CategoryVideosPage({
    super.key,
    this.videoType,
  });

  @override
  Widget build(BuildContext context) {
    return HomePage(videoType: videoType);
  }
}