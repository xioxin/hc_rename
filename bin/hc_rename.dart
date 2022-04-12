import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;

String green(String text) => '\x1B[32m$text\x1B[0m';
String red(String text) => '\x1B[31m$text\x1B[0m';

int minDistance(String s1, String s2) {
  final len1 = s1.length;
  final len2 = s2.length;
  List<List<int>> matrix =
      List.generate(len1 + 1, (index) => List.filled(len2 + 1, 0));
  for (int i = 0; i <= len1; i++) {
    for (int j = 0; j <= len2; j++) {
      if (i == 0) {
        matrix[i][j] = j;
      } else if (j == 0) {
        matrix[i][j] = i;
      } else {
        int cost = 0;
        if (s1[i - 1] != s2[j - 1]) {
          cost = 1;
        }
        final temp = matrix[i - 1][j - 1] + cost;
        matrix[i][j] =
            min(matrix[i - 1][j] + 1, min(matrix[i][j - 1] + 1, temp));
      }
    }
  }
  return matrix[len1][len2];
}

class MatchResult {
  File file;
  String targetName;
  double get score {
    return 1.0 - (minDistance(targetName, name) / targetName.length);
  }

  String get ext => path.extension(file.path, 2);
  String get name {
    final fileName = path.basename(file.path);
    return fileName.substring(0, fileName.length - ext.length);
  }

  @override
  toString() {
    final nameList = name.codeUnits;
    final targetNameList = targetName.codeUnits;
    final colorName = nameList
        .map((s) => targetNameList.contains(s)
            ? green(String.fromCharCode(s))
            : red(String.fromCharCode(s)))
        .join('');
    final colorTargetName = targetNameList
        .map((s) => nameList.contains(s)
            ? green(String.fromCharCode(s))
            : red(String.fromCharCode(s)))
        .join('');
    return "${score.toStringAsFixed(2)} $colorName$ext \n   => $colorTargetName \n";
  }

  MatchResult(this.file, this.targetName);
}

void main(List<String> arguments) {
  final rootPath = arguments.isNotEmpty ? arguments.first : '.';
  final dir = Directory(rootPath);

  List<FileSystemEntity> list = dir.listSync();

  List<File> nfoList = list
      .where((element) =>
          element is File &&
          path.extension(element.path, 2).toLowerCase() == '.nfo')
      .cast<File>()
      .toList();

  final needRenameExt = {
    '.mkv',
    '.mp4',
    '.cht.mp4',
    '.chs.mp4',
    '.cht.ass',
    '.chs.ass'
  };

  List<File> needRenameFileList = list
      .where((e) =>
          e is File &&
          needRenameExt.contains(path.extension(e.path, 2).toLowerCase()))
      .cast<File>()
      .toList();

  final List<MatchResult> modification = [];
  for (var file in needRenameFileList) {
    final matchList = nfoList
        .map((e) => MatchResult(file, path.basenameWithoutExtension(e.path)))
        .toList();
    matchList.sort((a, b) => b.score.compareTo(a.score));
    modification.add(matchList.first);
    print(matchList.first);
  }
  // todo 检查重命名后文件夹是否重复；
  stdout.write("是否继续？(Y/n)");
  final yn = stdin.readLineSync() ?? '';
  if (yn.toLowerCase() == 'y') {
    for (var match in modification) {
      final newPath = path.join(
          path.dirname(match.file.path), match.targetName + match.ext);
      match.file.renameSync(newPath);
    }
    print('重命名完成！');
    exit(0);
  }
  print('取消了');
  exit(1);
}
