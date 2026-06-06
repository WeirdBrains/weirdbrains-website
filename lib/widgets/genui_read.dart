import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart' show S;

import '../theme/app_theme.dart';

/// The portal's branded GenUI catalog + renderer.
///
/// The backend (`POST /portal/read`) returns an A2UI component tree built from
/// this small, on-brand vocabulary. The browser renders it blindly through the
/// catalog below, so a generative model can compose the "read" from WeirdBrains
/// building blocks instead of raw Material. Today the tree is deterministic;
/// in Phase 2 a model (qwen3 / Vertex) emits the same shape.

/// Renders an A2UI surface payload of shape
/// `{surfaceId, catalogId, components: [{id, type, properties}]}`.
class GenUiRead extends StatefulWidget {
  const GenUiRead({super.key, required this.surface});

  final Map<String, Object?> surface;

  @override
  State<GenUiRead> createState() => _GenUiReadState();
}

class _GenUiReadState extends State<GenUiRead> {
  late final SurfaceController _controller;
  late final String _surfaceId;

  @override
  void initState() {
    super.initState();
    _controller = SurfaceController(catalogs: [_wbCatalog]);
    _apply(widget.surface);
  }

  void _apply(Map<String, Object?> s) {
    _surfaceId = (s['surfaceId'] as String?) ?? 'read';
    final catalogId = (s['catalogId'] as String?) ?? 'wb';
    final raw = (s['components'] as List?) ?? const [];
    final components = raw.map((c) {
      final m = (c as Map).cast<String, Object?>();
      return Component(
        id: m['id'] as String,
        type: m['type'] as String,
        properties: (m['properties'] as Map).cast<String, Object?>(),
      );
    }).toList();

    // UpdateComponents first (defines the tree), then CreateSurface (shows it).
    _controller.handleMessage(
      UpdateComponents(surfaceId: _surfaceId, components: components),
    );
    _controller.handleMessage(
      CreateSurface(surfaceId: _surfaceId, catalogId: catalogId),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Surface(surfaceContext: _controller.contextFor(_surfaceId));
  }
}

// ---- Branded catalog ----

final Catalog _wbCatalog = Catalog(
  [_readRoot, _domainChip, _sectionTitle, _approachStep, _callout],
  catalogId: 'wb',
);

Map<String, Object?> _props(CatalogItemContext c) =>
    (c.data as Map).cast<String, Object?>();

/// Vertical container that stacks the read's children.
final _readRoot = CatalogItem(
  name: 'ReadRoot',
  dataSchema: S.object(
    description: 'Root container for the first-pass read.',
    properties: <String, S>{'children': S.list(items: S.string())},
    required: ['children'],
  ),
  widgetBuilder: (c) {
    final ids = ((_props(c)['children'] as List?) ?? const []).cast<String>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [for (final id in ids) c.buildChild(id)],
    );
  },
);

/// The detected domain, as a sky pill.
final _domainChip = CatalogItem(
  name: 'DomainChip',
  dataSchema: S.object(
    description: 'A pill showing the detected problem domain.',
    properties: <String, S>{'label': S.string()},
    required: ['label'],
  ),
  widgetBuilder: (c) {
    final label = _props(c)['label'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.sky.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.sky.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: AppTheme.body(13.5, color: AppTheme.sky, height: 1.0)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  },
);

/// A section heading inside the read.
final _sectionTitle = CatalogItem(
  name: 'SectionTitle',
  dataSchema: S.object(
    description: 'A section heading.',
    properties: <String, S>{'text': S.string()},
    required: ['text'],
  ),
  widgetBuilder: (c) {
    final text = _props(c)['text'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(text, style: AppTheme.heading(22)),
    );
  },
);

/// One step of the proposed approach: a gradient dot and a line of copy.
final _approachStep = CatalogItem(
  name: 'ApproachStep',
  dataSchema: S.object(
    description: 'A single step in the proposed approach.',
    properties: <String, S>{'index': S.integer(), 'text': S.string()},
    required: ['text'],
  ),
  widgetBuilder: (c) {
    final text = _props(c)['text'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: AppTheme.ctaGradient),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: AppTheme.body(15.5, height: 1.6)),
          ),
        ],
      ),
    );
  },
);

/// The "instant first pass, a human refines it" reassurance card.
final _callout = CatalogItem(
  name: 'Callout',
  dataSchema: S.object(
    description: 'A reassurance callout box.',
    properties: <String, S>{'text': S.string()},
    required: ['text'],
  ),
  widgetBuilder: (c) {
    final text = _props(c)['text'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.purple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.purple.withValues(alpha: 0.2)),
        ),
        child: Text(text, style: AppTheme.body(13.5, height: 1.5)),
      ),
    );
  },
);
