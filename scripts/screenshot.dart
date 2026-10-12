// ignore_for_file: avoid_print
//
// Screenshots the links of links.json containing <text>. Copied into QuaX's tool/record/.
//
//   dart run tool/record/screenshot.dart <text> <output directory>

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:puppeteer/puppeteer.dart';

import 'chrome.dart';

const _port = 9222;
final _profileDir = Directory('tool/record/.chrome-profile');
final _linksFile = File('tool/record/links.json');

const _pageTimeout = Duration(seconds: 15);
const _tweetTimeout = Duration(seconds: 15);
const _imagesDelay = Duration(seconds: 3);

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    print('Usage: dart run tool/record/screenshot.dart <text> <output directory>');
    exit(1);
  }
  final [only, outPath] = args;
  final links = jsonDecode(_linksFile.readAsStringSync()) as Map<String, dynamic>;
  final urls = (links['scenarios'] as List<dynamic>)
      .map((entry) => (entry as Map<String, dynamic>)['url'] as String)
      .where((url) => url.contains(only))
      .toList();
  if (urls.isEmpty) {
    print('No link of ${_linksFile.path} contains "$only".');
    exit(1);
  }

  final outDir = Directory(outPath)..createSync(recursive: true);
  final chrome = await startChrome(profile: _profileDir, port: _port);
  final browser = await connectChrome(_port);
  final page = (await browser.pages).firstOrNull ?? await browser.newPage();

  var failures = 0;
  for (final url in urls) {
    try {
      await page.goto(url, wait: Until.domContentLoaded, timeout: _pageTimeout);
      try {
        await page.waitForSelector('article', timeout: _tweetTimeout);
      } on Exception {
        print('  no tweet on $url after ${_tweetTimeout.inSeconds} s');
      }
      await Future.delayed(_imagesDelay);
      final file = File('${outDir.path}/${_nameFor(url)}.png');
      // X scrolls to an opened tweet: a window-sized picture would cut the tweets above it.
      file.writeAsBytesSync(await page.screenshot(fullPage: true));
      print('Saved ${file.path}');
    } on Exception catch (error) {
      print('Could not screenshot $url: $error');
      failures++;
    }
  }

  await browser.close();
  await chrome.exitCode.timeout(const Duration(seconds: 30), onTimeout: () {
    chrome.kill();
    return 0;
  });
  if (failures > 0) exitCode = 1;
}

/// https://x.com/quax_tests/media?filter=photo -> quax_tests-media-filter-photo
String _nameFor(String url) => url
    .replaceFirst(RegExp(r'^https://x\.com/'), '')
    .replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');
