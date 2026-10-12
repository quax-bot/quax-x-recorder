// ignore_for_file: avoid_print
//
// Screenshots the links of links.json containing a text, as capture.dart
// --only selects them, so the artifact shows what each fixture was recorded
// from. Copied into QuaX's tool/record/ to start Chrome exactly as capture.dart
// does, with the profile inject_cookies.dart logged in.
//
//   dart run tool/record/screenshot.dart <text> <output directory>
//
// The page is opened again after the capture: what it shows may differ a little
// from what the fixtures hold on a page that changes often.

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:puppeteer/puppeteer.dart';

import 'chrome.dart';

const _port = 9222;
final _profileDir = Directory('tool/record/.chrome-profile');
final _linksFile = File('tool/record/links.json');

const _pageTimeout = Duration(seconds: 15);

/// How long a tweet may take to appear. A page without any, such as a deleted
/// post, is still screenshotted once this runs out.
const _tweetTimeout = Duration(seconds: 15);

/// Lets the images of the tweets load once the text is there.
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
      // The whole page rather than the window: X scrolls to an opened tweet, which would leave the
      // tweets above it cut and the header across the middle of the picture.
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
