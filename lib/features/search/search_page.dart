import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ivideo/core/supabase/supabase_client.dart';
import 'package:ivideo/shared/models/video_model.dart';
import 'package:ivideo/shared/widgets/video_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Video> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    // 延迟聚焦，避免键盘弹出影响布局
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      debugPrint('加载搜索历史失败: $e');
    }
  }

  Future<void> _saveToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    try {
      _searchHistory.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
      _searchHistory.insert(0, query.trim());
      
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.sublist(0, 10);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', _searchHistory);
      
      setState(() {});
    } catch (e) {
      debugPrint('保存搜索历史失败: $e');
    }
  }

  Future<void> _clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
      setState(() {
        _searchHistory.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('已清空搜索历史'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('清空搜索历史失败: $e');
    }
  }

  Future<void> _removeSearchHistory(String query) async {
    try {
      _searchHistory.removeWhere((item) => item == query);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', _searchHistory);
      setState(() {});
    } catch (e) {
      debugPrint('删除搜索历史失败: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query.trim();
    });

    try {
      final response = await SupabaseService.client
          .from('videos')
          .select('*')
          .ilike('title', '%$_searchQuery%')
          .order('views_count', ascending: false);

      final data = response as List;
      setState(() {
        _searchResults = data.map((json) => Video.fromJson(json)).toList();
        _isSearching = false;
      });

      await _saveToSearchHistory(_searchQuery);
    } catch (e) {
      debugPrint('搜索失败: $e');
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('搜索失败: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _onSearchPressed() {
    if (_searchController.text.trim().isNotEmpty) {
      _performSearch(_searchController.text);
      _searchFocusNode.unfocus();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // 顶部搜索栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 返回按钮
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 22),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 搜索框 - 长椭圆形状
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              style: const TextStyle(fontSize: 15),
                              decoration: const InputDecoration(
                                hintText: '搜索视频...',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              onChanged: (value) {
                                setState(() {});
                                if (value.isEmpty) {
                                  setState(() {
                                    _searchResults = [];
                                    _searchQuery = '';
                                  });
                                }
                              },
                              onSubmitted: (value) => _performSearch(value),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              onPressed: _clearSearch,
                              padding: EdgeInsets.zero,
                            ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 搜索按钮
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6428),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: _onSearchPressed,
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 搜索内容区域
            Expanded(
              child: _buildSearchContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFFFF6428)),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              '搜索中...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchQuery.isNotEmpty && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '没有找到相关视频',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '试试其他关键词吧',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索结果标题
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.video_library_rounded,
                  color: Color(0xFFFF6428),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '搜索结果',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6428).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_searchResults.length} 个',
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
          
          // 搜索结果列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final video = _searchResults[index];
                return VideoCard(video: video);
              },
            ),
          ),
        ],
      );
    }

    return _buildSearchSuggestions();
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索历史
          if (_searchHistory.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  color: Colors.grey[700],
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  '搜索历史',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearSearchHistory,
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey[600]),
                  label: Text(
                    '清空',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._searchHistory.map((history) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.access_time_rounded,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                  title: Text(
                    history,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close, size: 20, color: Colors.grey[500]),
                    onPressed: () => _removeSearchHistory(history),
                  ),
                  onTap: () {
                    _searchController.text = history;
                    _performSearch(history);
                  },
                ),
              );
            }),
            const SizedBox(height: 32),
          ],
          
          // 热门搜索
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFFF6428),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                '热门搜索',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              'Flutter教程',
              'React前端',
              '编程教学',
              '技术分享',
              'Python入门',
              'Web开发',
            ].asMap().entries.map((entry) {
              final index = entry.key;
              final tag = entry.value;
              return InkWell(
                onTap: () {
                  _searchController.text = tag;
                  _performSearch(tag);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: index < 3
                        ? LinearGradient(
                            colors: [
                              const Color(0xFFFF6428).withOpacity(0.1),
                              const Color(0xFFFF6428).withOpacity(0.05),
                            ],
                          )
                        : null,
                    color: index >= 3 ? Colors.white : null,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: index < 3
                          ? const Color(0xFFFF6428).withOpacity(0.3)
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index < 3)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6428),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (index < 3) const SizedBox(width: 8),
                      Text(
                        tag,
                        style: TextStyle(
                          fontSize: 14,
                          color: index < 3 ? const Color(0xFFFF6428) : Colors.grey[700],
                          fontWeight: index < 3 ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}