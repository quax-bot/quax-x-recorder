// ignore_for_file: avoid_print
//
// Logs the recording profile in to X with the cookies of the recording account,
// so capture.dart finds a session and never asks for a login. Copied into
// QuaX's tool/record/ to start Chrome exactly as capture.dart does and to
// resolve puppeteer from QuaX's dependencies.
//
// X_COOKIES is the "cookie" request header of a logged-in x.com tab, whole:
// every cookie the browser had, rather than a guess at which ones X needs.

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:puppeteer/protocol/network.dart' show TimeSinceEpoch;
import 'package:puppeteer/puppeteer.dart';

import 'chrome.dart';

const _port = 9222;
final _profileDir = Directory('tool/record/.chrome-profile');

Future<void> main() async {
  final cookies = _parse(Platform.environment['X_COOKIES'] ?? '');
  if (!cookies.any((cookie) => cookie.name == 'auth_token')) {
    print('X_COOKIES holds no auth_token: copy the cookie header of a logged-in x.com tab.');
    exit(1);
  }

  final chrome = await startChrome(profile: _profileDir, port: _port);
  final browser = await connectChrome(_port);
  final page = (await browser.pages).firstOrNull ?? await browser.newPage();
  await page.setCookies(cookies);
  // A clean shutdown is what writes the cookies to the profile; a killed
  // Chrome may lose them.
  await browser.close();
  await chrome.exitCode.timeout(const Duration(seconds: 30));
  print('${cookies.length} cookies saved to ${_profileDir.path}: ${cookies.map((c) => c.name).join(', ')}');
}

/// "name=value; name=value", as a request header carries them.
List<CookieParam> _parse(String header) => header
    .split(';')
    .map((pair) => pair.trim())
    .where((pair) => pair.contains('='))
    .map((pair) => _cookie(pair.substring(0, pair.indexOf('=')), pair.substring(pair.indexOf('=') + 1)))
    .toList();

/// Persistent, unlike a cookie without expiry, which Chrome drops on shutdown.
CookieParam _cookie(String name, String value) => CookieParam(
      name: name,
      value: value,
      domain: '.x.com',
      path: '/',
      secure: true,
      expires: TimeSinceEpoch(DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch / 1000),
    );
