// Stub file for web platform - File and FileMode are not available on web
// This file is only used when dart:io is not available
// These classes are never actually used on web due to kIsWeb checks

// Stub classes to satisfy the compiler on web platform
// These will never be instantiated due to kIsWeb checks in the code
class File {
  File(String path);
  Future<bool> exists() => throw UnimplementedError();
  Future<void> writeAsString(String contents, {FileMode? mode}) => throw UnimplementedError();
  Future<File> create({bool recursive = false}) => throw UnimplementedError();
}

enum FileMode {
  write,
  append,
}

