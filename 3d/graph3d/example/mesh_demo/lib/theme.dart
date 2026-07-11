import 'package:flutter/material.dart';
import 'package:graph3d/graph3d.dart';

import 'data/mesh.dart';

const Color kPanelBg = Color(0xE60A1418);
const Color kPanelBorder = Color(0xFF14545E);
const Color kAccent = Color(0xFF6FE3F0);
const Color kTextDim = Color(0x9980DEEA);
const Color kText = Color(0xFFC7EEF5);

const TextStyle kMono = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: <String>['Courier New', 'DejaVu Sans Mono'],
  fontSize: 12.5,
  color: kText,
  height: 1.4,
);

/// How each entity looks as an orb: hierarchy by size and dressing, network
/// membership by colour.
///
/// [hubScale] inflates the anchors (transports, gateways): the backbone view
/// is a handful of far-apart orbs, which read as specks at ego-view sizes.
NodeSprite spriteOfEntity(
  SceneNode<MeshEntity> node, {
  double hubScale = 1,
}) {
  final entity = node.data;
  switch (entity.role) {
    case MeshRole.self:
      return const NodeSprite(
        radius: 46,
        coreColor: Color(0xFFA7FFF6),
        haloScale: 3.0,
        ringColor: Color(0xFFE0FFFF),
        label: 'this node',
        labelMinPx: 2.5,
      );
    case MeshRole.transport:
      return NodeSprite(
        radius: 40 * hubScale,
        coreColor: entity.iface.color,
        haloScale: 2.8,
        ringColor: Colors.white70,
        badge: '${entity.deviceCount}',
        label: entity.name,
        labelMinPx: 2.5,
      );
    case MeshRole.gateway:
      return NodeSprite(
        radius: 34 * hubScale,
        coreColor: entity.ifaces.first.color,
        secondaryColor:
            entity.ifaces.length > 1 ? entity.ifaces[1].color : null,
        badge: '${entity.deviceCount}',
        label: entity.name,
        labelMinPx: 2.5,
      );
    case MeshRole.bridge:
      return NodeSprite(
        radius: 30,
        coreColor: entity.ifaces.first.color,
        secondaryColor:
            entity.ifaces.length > 1 ? entity.ifaces[1].color : null,
        badge: entity.deviceCount > 0 ? '${entity.deviceCount}' : null,
        label: entity.name,
        labelMinPx: 2.5,
      );
    case MeshRole.peer:
      return NodeSprite(
        radius: 22,
        coreColor: entity.iface.color,
        label: entity.name,
        labelMinPx: 2.5,
      );
    case MeshRole.leaf:
      return NodeSprite(
        radius: 17,
        coreColor: entity.iface.color,
        label: entity.name,
      );
  }
}

String roleLabel(MeshRole role) => switch (role) {
  MeshRole.self => 'this device',
  MeshRole.peer => 'peer',
  MeshRole.bridge => 'edge bridge',
  MeshRole.transport => 'transport hub',
  MeshRole.gateway => 'gateway',
  MeshRole.leaf => 'destination',
};
