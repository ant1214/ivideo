// search_history_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryCount = 10; // 最多保存10条记录

  // 获取搜索记录
  static Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_searchHistoryKey) ?? [];
      return history;
    } catch (e) {
      print('获取搜索记录失败: $e');
      return [];
    }
  }

  // 添加搜索记录
  static Future<void> addSearchHistory(String keyword) async {
    try {
      if (keyword.trim().isEmpty) return;
      
      final prefs = await SharedPreferences.getInstance();
      List<String> history = await getSearchHistory();
      
      // 移除重复的记录
      history.removeWhere((item) => item.toLowerCase() == keyword.toLowerCase());
      
      // 添加到开头
      history.insert(0, keyword.trim());
      
      // 限制记录数量
      if (history.length > _maxHistoryCount) {
        history = history.sublist(0, _maxHistoryCount);
      }
      
      await prefs.setStringList(_searchHistoryKey, history);
    } catch (e) {
      print('添加搜索记录失败: $e');
    }
  }

  // 清空搜索记录
  static Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
    } catch (e) {
      print('清空搜索记录失败: $e');
    }
  }

  // 删除单条搜索记录
  static Future<void> removeSearchHistory(String keyword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = await getSearchHistory();
      history.removeWhere((item) => item == keyword);
      await prefs.setStringList(_searchHistoryKey, history);
    } catch (e) {
      print('删除搜索记录失败: $e');
    }
  }
}