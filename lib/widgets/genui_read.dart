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
  [
    _readRoot,
    _domainChip,
    _sectionTitle,
    _approachStep,
    _callout,
    _phaseCard,
    _effortSignal,
    _bullet,
    _altCard,
  ],
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

/// A phase in the rough plan: a small label chip, a title, and a line of copy.
final _phaseCard = CatalogItem(
  name: 'PhaseCard',
  dataSchema: S.object(
    description: 'A phase in the rough plan.',
    properties: <String, S>{
      'label': S.string(),
      'title': S.string(),
      'text': S.string(),
    },
    required: ['label', 'title', 'text'],
  ),
  widgetBuilder: (c) {
    final p = _props(c);
    final label = p['label'] as String? ?? '';
    final title = p['title'] as String? ?? '';
    final text = p['text'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppTheme.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: AppTheme.body(11.5,
                            color: AppTheme.purpleBright, height: 1.0)
                        .copyWith(
                            fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(child: Text(title, style: AppTheme.heading(15.5))),
              ],
            ),
            const SizedBox(height: 8),
            Text(text, style: AppTheme.body(14, height: 1.5)),
          ],
        ),
      ),
    );
  },
);

/// A plain bullet line (evidence, failure modes, acceptance criteria).
final _bullet = CatalogItem(
  name: 'Bullet',
  dataSchema: S.object(
    description: 'A single bullet line.',
    properties: <String, S>{'text': S.string()},
    required: ['text'],
  ),
  widgetBuilder: (c) {
    final text = _props(c)['text'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTheme.body(14, height: 1.55))),
        ],
      ),
    );
  },
);

/// An alternative approach card: name, effort/risk meta line, summary.
final _altCard = CatalogItem(
  name: 'AltCard',
  dataSchema: S.object(
    description: 'An alternative approach considered in the plan.',
    properties: <String, S>{
      'name': S.string(),
      'meta': S.string(),
      'text': S.string(),
    },
    required: ['name', 'text'],
  ),
  widgetBuilder: (c) {
    final p = _props(c);
    final name = p['name'] as String? ?? '';
    final meta = p['meta'] as String? ?? '';
    final text = p['text'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: ShapeDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name, style: AppTheme.heading(14.5)),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    style:
                        AppTheme.body(12, color: AppTheme.textMuted, height: 1.0),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(text, style: AppTheme.body(13.5, height: 1.5)),
          ],
        ),
      ),
    );
  },
);

/// A labeled feasibility/effort signal line.
final _effortSignal = CatalogItem(
  name: 'EffortSignal',
  dataSchema: S.object(
    description: 'A labeled feasibility or effort signal.',
    properties: <String, S>{'label': S.string(), 'value': S.string()},
    required: ['label', 'value'],
  ),
  widgetBuilder: (c) {
    final p = _props(c);
    final label = p['label'] as String? ?? '';
    final value = p['value'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, size: 16, color: AppTheme.gold),
          const SizedBox(width: 8),
          Text('$label: ',
              style: AppTheme.body(13.5, color: AppTheme.textMuted, height: 1.2)),
          Flexible(
            child: Text(
              value,
              style: AppTheme.body(13.5, color: AppTheme.gold, height: 1.2)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  },
);
