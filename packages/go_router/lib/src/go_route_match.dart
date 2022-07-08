// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'go_route.dart';
import 'go_route_information_parser.dart';
import 'path_parser.dart';

/// Each GoRouteMatch instance represents an instance of a GoRoute for a
/// specific portion of a location.
class GoRouteMatch {
  /// Constructor for GoRouteMatch, each instance represents an instance of a
  /// GoRoute for a specific portion of a location.
  GoRouteMatch({
    required this.route,
    required this.subloc,
    required this.fullpath,
    required this.encodedParams,
    required this.queryParams,
    required this.extra,
    required this.error,
    this.pageKey,
  })  : fullUriString = _addQueryParams(subloc, queryParams),
        assert(subloc.startsWith('/')),
        assert(Uri.parse(subloc).queryParameters.isEmpty),
        assert(fullpath.startsWith('/')),
        assert(Uri.parse(fullpath).queryParameters.isEmpty),
        assert(() {
          for (final MapEntry<String, String> p in encodedParams.entries) {
            assert(p.value == Uri.encodeComponent(Uri.decodeComponent(p.value)),
                'encodedParams[${p.key}] is not encoded properly: "${p.value}"');
          }
          return true;
        }());

  // ignore: public_member_api_docs
  static GoRouteMatch? match({
    required GoRoute route,
    required String restLoc, // e.g. person/p1
    required String parentSubloc, // e.g. /family/f2
    required String fullpath, // e.g. /family/:fid/person/:pid
    required Map<String, String> queryParams,
    required Object? extra,
  }) {
    assert(!route.path.contains('//'));

    final RegExpMatch? match = route.matchPatternAsPrefix(restLoc);
    if (match == null) {
      return null;
    }

    final Map<String, String> encodedParams = route.extractPathParams(match);
    final String pathLoc = patternToPath(route.path, encodedParams);
    final String subloc =
        GoRouteInformationParser.concatenatePaths(parentSubloc, pathLoc);
    return GoRouteMatch(
      route: route,
      subloc: subloc,
      fullpath: fullpath,
      encodedParams: encodedParams,
      queryParams: queryParams,
      extra: extra,
      error: null,
    );
  }

  /// The matched route.
  final GoRoute route;

  /// Matched sub-location.
  final String subloc; // e.g. /family/f2

  /// Matched full path.
  final String fullpath; // e.g. /family/:fid

  /// Parameters for the matched route, URI-encoded.
  final Map<String, String> encodedParams;

  /// Query parameters for the matched route.
  final Map<String, String> queryParams;

  /// An extra object to pass along with the navigation.
  final Object? extra;

  /// An exception if there was an error during matching.
  final Exception? error;

  /// Optional value key of type string, to hold a unique reference to a page.
  final ValueKey<String>? pageKey;

  /// The full uri string
  final String fullUriString; // e.g. /family/12?query=14

  static String _addQueryParams(String loc, Map<String, String> queryParams) {
    final Uri uri = Uri.parse(loc);
    assert(uri.queryParameters.isEmpty);
    return Uri(
            path: uri.path,
            queryParameters: queryParams.isEmpty ? null : queryParams)
        .toString();
  }

  /// Parameters for the matched route, URI-decoded.
  Map<String, String> get decodedParams => <String, String>{
        for (final MapEntry<String, String> param in encodedParams.entries)
          param.key: Uri.decodeComponent(param.value)
      };

  /// for use by the Router architecture as part of the GoRouteMatch
  @override
  String toString() => 'GoRouteMatch($fullpath, $encodedParams)';
}
