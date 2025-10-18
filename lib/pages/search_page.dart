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
  List<Video> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
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
    }
  }

  void _onSearchPressed() {
    if (_searchController.text.trim().isNotEmpty) {
      _performSearch(_searchController.text);
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
      appBar: AppBar(
        title: const Text('搜索视频'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(
            child: _buildSearchContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索视频...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
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
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.blue),
            onPressed: _onSearchPressed,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: Colors.blue.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('搜索中...'),
          ],
        ),
      );
    }

    if (_searchQuery.isNotEmpty && _searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '没有找到相关视频',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final video = _searchResults[index];
          return VideoCard(video: video, onTap: () {  },);
        },
      );
    }

    return _buildSearchSuggestions();
  }

  Widget _buildSearchSuggestions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_searchHistory.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                '搜索历史',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearSearchHistory,
                child: const Text(
                  '清空',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._searchHistory.map((history) {
            return ListTile(
              leading: const Icon(Icons.history, size: 20),
              title: Text(history),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => _removeSearchHistory(history),
              ),
              onTap: () {
                _searchController.text = history;
                _performSearch(history);
              },
            );
          }),
          const SizedBox(height: 24),
        ],
        const Text(
          '热门搜索',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Flutter教程',
            'React前端',
            '编程教学',
            '技术分享',
          ].map((tag) {
            return ActionChip(
              label: Text(tag),
              onPressed: () {
                _searchController.text = tag;
                _performSearch(tag);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}