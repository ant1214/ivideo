import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ivideo/core/supabase/supabase_client.dart';
import 'package:provider/provider.dart';
import 'package:ivideo/core/providers/auth_provider.dart';
import 'package:ivideo/shared/models/video_model.dart';
import 'package:ivideo/shared/widgets/video_card.dart';

class HomePage extends StatefulWidget {
  final String? videoType;

  const HomePage({
    super.key,
    this.videoType,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Video> _videos = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _hideWelcomeBanner = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _loadWelcomeBannerState();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoType != widget.videoType) {
      _loadVideos();
    }
  }

  Future<void> _loadWelcomeBannerState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hideWelcomeBanner = prefs.getBool('hide_welcome_banner') ?? false;
    });
  }

  Future<void> _saveWelcomeBannerState(bool hide) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_welcome_banner', hide);
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      var query = SupabaseService.client
          .from('videos')
          .select('*, video_tags(tags(name))');

      if (widget.videoType != null) {
        query = query.eq('video_type', widget.videoType!);
      }

      final response = await query.order('created_at', ascending: false);

      final data = response as List;
      setState(() {
        _videos = data.map((json) => Video.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: _buildBody(authProvider),
        );
      },
    );
  }

  Widget _buildBody(AuthProvider authProvider) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFFFF6428)),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadVideos,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6428),
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.videoType != null ? '暂无${widget.videoType}视频' : '暂无视频',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 欢迎横幅
        if (authProvider.isLoggedIn && !_hideWelcomeBanner)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.purple.shade50,
                ],
              ),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '欢迎回来!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        authProvider.user?.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _saveWelcomeBannerState(true);
                    setState(() {
                      _hideWelcomeBanner = true;
                    });
                  },
                  tooltip: '关闭',
                ),
              ],
            ),
          ),

        // 分类标题栏
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(widget.videoType),
                size: 24,
                color: const Color(0xFFFF6428),
              ),
              const SizedBox(width: 12),
              Text(
                widget.videoType ?? '全部视频',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6428).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_videos.length} 部',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFFF6428),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              
              // 手机端使用单列列表
              if (screenWidth < 600) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: VideoCard(video: _videos[index]),
                    );
                  },
                );
              } else {
                // Web端保持原来的网格布局
                int columns;
                double spacing;
                
                if (screenWidth < 900) {
                  columns = 2;
                  spacing = 20;
                } else {
                  columns = 3;
                  spacing = 24;
                }

                return GridView.builder(
                  padding: EdgeInsets.all(spacing / 2),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: 16/13,
                  ),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    return VideoCard(video: _videos[index]);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String? videoType) {
    switch (videoType) {
      case '电影':
        return Icons.movie_rounded;
      case '电视剧':
        return Icons.tv_rounded;
      case '动漫':
        return Icons.animation_rounded;
      case '综艺':
        return Icons.mic_rounded;
      case '纪录片':
        return Icons.description_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }
}
