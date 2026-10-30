// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_lightstep_suppression.dart';

const _tracerName = 'dartastic_otel_libs_lightstep';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps a Lightstep (ServiceNow Cloud Observability) OTLP push in
/// a PRODUCER span. Records the project, access token tail (for
/// support tickets — never the full token), and span/log counts.
Future<T> tracedLightstepPush<T>({
  required Future<T> Function() invoke,
  String? project,
  String? accessTokenTail,
  int? spanCount,
  int? logCount,
}) async {
  if (lightstepInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'lightstep.product': 'cloud_observability',
    'messaging.system': 'lightstep',
    'messaging.operation': 'publish',
  };
  if (project != null) m['lightstep.project'] = project;
  if (accessTokenTail != null) {
    m['lightstep.access_token.tail'] = accessTokenTail;
  }
  if (spanCount != null) m['lightstep.span_count'] = spanCount;
  if (logCount != null) m['lightstep.log_count'] = logCount;

  final span = _tracer().startSpan(
    'lightstep push',
    kind: SpanKind.producer,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
