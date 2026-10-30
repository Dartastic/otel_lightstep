// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_lightstep/otel_lightstep.dart';

/// Traces Lightstep calls with OpenTelemetry.
///
/// `otel_lightstep` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Lightstep call in
/// [tracedLightstepPush]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'lightstep-example');

  // Wraps a Lightstep (ServiceNow Cloud Observability) OTLP push in a PRODUCER span.
  final lightstepPushId = await tracedLightstepPush<String>(
    project: 'example',
    accessTokenTail: 'example',
    spanCount: 3,
    logCount: 3,
    invoke: () async {
      // Make the Lightstep call here, then report what it returned.
      return 'lightstep_8f3a2c';
    },
  );
  OTelLog.info('tracedLightstepPush returned $lightstepPushId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutLightstepInstrumentationAsync.
  await runWithoutLightstepInstrumentationAsync(
    () => tracedLightstepPush<String>(
      project: 'example',
      accessTokenTail: 'example',
      spanCount: 3,
      logCount: 3,
      invoke: () async {
        return 'lightstep_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
