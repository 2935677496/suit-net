String matchBetween(String inputtedString, String start, String end) {
  if (inputtedString.isEmpty) {
    throw ArgumentError('matchBetween: 输入字符串不能为空');
  }

  final pattern = '${RegExp.escape(start)}(.*?)${RegExp.escape(end)}';
  final reg = RegExp(pattern, dotAll: true);
  final match = reg.firstMatch(inputtedString);

  if (match != null) {
    return match.group(1)!;
  }
  //return之后不会继续执行
  throw StateError('matchBetween: 未找到匹配内容 (start="$start", end="$end")');
}
