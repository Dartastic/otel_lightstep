// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_lightstep/otel_lightstep.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_lightstep-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('push records PRODUCER span', () async {
    await tracedLightstepPush<String>(
      project: 'app-prod',
      accessTokenTail: 'abcd',
      spanCount: 100,
      logCount: 50,
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('lightstep push')!);
    expect(a['lightstep.product'], 'cloud_observability');
    expect(a['lightstep.project'], 'app-prod');
    expect(a['lightstep.access_token.tail'], 'abcd');
    expect(a['lightstep.span_count'], 100);
    expect(a['lightstep.log_count'], 50);
  });

  test('suppression skips spans', () async {
    await runWithoutLightstepInstrumentationAsync(() async {
      await tracedLightstepPush<String>(invoke: () async => 'ok');
    });
    expect(spans.findSpansStartingWith('lightstep '), isEmpty);
  });
}
