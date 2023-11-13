import 'dart:io';

import 'package:android_content_provider/android_content_provider.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _authority = 'com.ryanheise.audioserviceexample';
const _scheme = 'content';
const assetCopiesDirectory = '.asset_copies/';

@pragma('vm:entry-point')
void coverArtContentProviderEntrypoint() {
  CoverArtContentProvider.instance;
}

class CoverArtContentProvider extends AndroidContentProvider {
  static CoverArtContentProvider instance =
      CoverArtContentProvider._(_authority);

  CoverArtContentProvider._(super.authority);

  // Maps from content://.../asset.png -> asset/.../asset.png
  final _assetContentUriCache = <String, String>{};

  // Maps from content://.../asset.png to filepath for asset file
  final _assetFileUriCache = <String, String>{};
  final _copiedAssets = <String, Uri>{};

  Uri generateContentUriFromAsset(String asset) {
    final uri = Uri(
      scheme: _scheme,
      host: _authority,
      path: asset,
    );
    if (_assetContentUriCache.containsKey(uri.toString())) {
      return uri;
    }

    copyAssetToFiles(asset).then(
      (value) => _assetFileUriCache[uri.toString()] = value.toString(),
    );

    _assetContentUriCache[asset] = uri.toString();
    return uri;
  }

  @override
  Future<String?> openFile(String uri, String mode) async {
    print('Open file content provider $uri');
    if (_assetFileUriCache.containsKey(uri)) {
      print('Already cached uri $uri');
      return _assetFileUriCache[uri];
    }

    if (!_assetContentUriCache.containsKey(uri)) {
      print(
          'Asset path for uri $uri was not found. Please generate content uris with CoverArtContentProvider#generateContentUriFromAsset()');
      return null;
    }

    final fileUri = await copyAssetToFiles(_assetContentUriCache[uri]!);
    _assetFileUriCache[uri] = fileUri.toFilePath();
    print('Content uri $uri, file path: ${fileUri.toFilePath()}');
    return fileUri.toFilePath();
  }

  /// Copies an asset to the application documents directory so it can be used
  /// as a normal file and the uri to the file will be returned.
  ///
  /// Returns early, if file was already copied during this runtime.
  Future<Uri> copyAssetToFiles(String asset) async {
    if (_copiedAssets.containsKey(asset)) {
      print('Already copied asset "$asset" to "${_copiedAssets[asset]}"');
      return _copiedAssets[asset]!;
    }
    print('Copying asset "$asset" to files');

    final byteData = await rootBundle.load(asset);
    final buffer = byteData.buffer;
    Directory directory = await getApplicationSupportDirectory();
    final file = File('${directory.absolute.path}/$assetCopiesDirectory$asset');
    await file.create(recursive: true);
    await file.writeAsBytes(
      buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );

    _copiedAssets[asset] = file.uri;

    print('Copied asset "$asset" to "${file.uri}"');

    return file.uri;
  }

  // =====================
  // Unused, we don't care
  // =====================

  @override
  Future<int> delete(
      String uri, String? selection, List<String>? selectionArgs) {
    throw UnimplementedError();
  }

  @override
  Future<String?> getType(String uri) {
    throw UnimplementedError();
  }

  @override
  Future<String?> insert(String uri, ContentValues? values) {
    throw UnimplementedError();
  }

  @override
  Future<CursorData?> query(String uri, List<String>? projection,
      String? selection, List<String>? selectionArgs, String? sortOrder) {
    throw UnimplementedError();
  }

  @override
  Future<int> update(String uri, ContentValues? values, String? selection,
      List<String>? selectionArgs) {
    throw UnimplementedError();
  }
}
