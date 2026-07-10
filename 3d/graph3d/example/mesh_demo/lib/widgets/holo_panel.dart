import 'package:flutter/material.dart';
import 'package:graph3d/graph3d.dart';

import '../data/mesh.dart';
import '../theme.dart';
import '../view_controller.dart';

/// The holographic detail panel: docked in the upper-right corner so it
/// never sits on top of the graph, tethered to the selected orb by a leader
/// line, and closable — the selection survives, only the panel goes away.
class HoloPanel extends StatefulWidget {
  const HoloPanel({super.key, required this.controller});

  final MeshViewController controller;

  @override
  State<HoloPanel> createState() => _HoloPanelState();
}

class _HoloPanelState extends State<HoloPanel> {
  MeshViewController get controller => widget.controller;

  bool _dismissed = false;
  String? _dismissedKey;

  @override
  Widget build(BuildContext context) {
    final scene = controller.scene;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        controller,
        scene,
        scene.camera,
        scene.transition,
      ]),
      builder: (context, _) {
        final id = scene.selectedId;
        if (id == null) return const SizedBox.shrink();
        final key = scene.selectedKey;

        // Closing hides the panel for THIS node; selecting another brings
        // the panel back.
        if (_dismissedKey != key) {
          _dismissed = false;
          _dismissedKey = key;
        }
        if (_dismissed) return const SizedBox.shrink();

        final entity = scene.renderNodes[id - 1].data;

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            scene.advancePoses();
            final projector = Projector(
              view: scene.camera.viewMatrix,
              perspective: perspectiveFor(size.height),
            );
            final projected = projector.project(
              scene.poses[id - 1].position,
            );

            // Docked upper-right, under the breadcrumb/view-toggle row, so
            // the graph itself stays unobstructed.
            final panelWidth = size.width < 420 ? 236.0 : 268.0;
            const top = 78.0; // clear of the breadcrumb/view-toggle row
            final left = size.width - panelWidth - 10;

            return Stack(
              children: <Widget>[
                if (projected != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _LeaderLinePainter(
                          from: projected.screen +
                              Offset(size.width / 2, size.height / 2),
                          to: Offset(left + panelWidth / 2, top + 6),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: left,
                  top: top,
                  width: panelWidth,
                  child: _PanelBody(
                    controller: controller,
                    entity: entity,
                    onClose: () => setState(() => _dismissed = true),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LeaderLinePainter extends CustomPainter {
  const _LeaderLinePainter({required this.from, required this.to});

  final Offset from;
  final Offset to;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kAccent.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    canvas.drawLine(from, to, paint);
    canvas.drawCircle(from, 2.5, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_LeaderLinePainter oldDelegate) =>
      oldDelegate.from != from || oldDelegate.to != to;
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({
    required this.controller,
    required this.entity,
    required this.onClose,
  });

  final MeshViewController controller;
  final MeshEntity entity;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final network = controller.network;
    final chain = controller.pathChain;
    final unknownHops = entity.hops >= 2 ? entity.hops - 2 : 0;

    return Container(
      decoration: BoxDecoration(
        color: kPanelBg,
        border: Border.all(color: kPanelBorder, width: 1.5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: kAccent.withValues(alpha: 0.12),
            blurRadius: 18,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              for (final iface in entity.ifaces) ...<Widget>[
                _IfaceChip(iface: iface),
                const SizedBox(width: 4),
              ],
              const Spacer(),
              Flexible(
                child: Text(
                  roleLabel(entity.role),
                  overflow: TextOverflow.ellipsis,
                  style: kMono.copyWith(fontSize: 10.5, color: kTextDim),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text(
                    '✕',
                    style: kMono.copyWith(fontSize: 14, color: kAccent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entity.name,
            style: kMono.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text('hash  ${entity.shortHash}…', style: kMono),
          if (entity.role != MeshRole.self)
            Text(
              entity.hops == 1
                  ? 'link  direct · ${entity.iface.label}'
                  : 'path  ${entity.hops} hops'
                        '${unknownHops > 0 ? ' · $unknownHops unknown' : ''}',
              style: kMono,
            ),
          if (entity.nextHop != null)
            Text(
              'via   ${network.byHash(entity.nextHop!).name}',
              style: kMono,
            ),
          if (entity.distanceM != null)
            Text(
              'range ~${entity.distanceM!.round()} m'
              '${entity.nextHop != null ? ' from relay' : ''}',
              style: kMono,
            ),
          if (entity.isAggregate)
            Text('nodes ${entity.deviceCount} behind it', style: kMono),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              if (chain.length > 1) ...<Widget>[
                _MiniButton(
                  label: '‹',
                  enabled: controller.pathStep > 0,
                  onPressed: () => controller.stepPath(-1),
                ),
                const SizedBox(width: 4),
                Text(
                  'hop ${controller.pathStep}/${chain.length - 1}',
                  style: kMono.copyWith(fontSize: 11, color: kTextDim),
                ),
                const SizedBox(width: 4),
                _MiniButton(
                  label: '›',
                  enabled: controller.pathStep < chain.length - 1,
                  onPressed: () => controller.stepPath(1),
                ),
              ],
              const Spacer(),
              if (entity.isAggregate)
                _MiniButton(
                  label: controller.expandedHash == entity.hash
                      ? 'collapse'
                      : 'expand',
                  onPressed: () => controller.tapNode(
                    controller.scene.selectedId ?? 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IfaceChip extends StatelessWidget {
  const _IfaceChip({required this.iface});

  final Iface iface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: iface.color.withValues(alpha: 0.18),
        border: Border.all(color: iface.color.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        iface.label,
        style: TextStyle(
          color: iface.color,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: kAccent.withValues(alpha: enabled ? 0.7 : 0.25),
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: kMono.copyWith(
            fontSize: 12,
            color: enabled ? kAccent : kTextDim,
          ),
        ),
      ),
    );
  }
}
