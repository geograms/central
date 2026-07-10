import 'data/mesh.dart';

/// What a scene node carries in this app: either a whole hub (collapsed, one
/// aggregate card) or a single leaf device of the expanded hub.
sealed class MeshNode {
  const MeshNode();

  String get sceneKey;
}

class HubNode extends MeshNode {
  const HubNode(this.hub, this.index);

  final MeshHub hub;

  /// Position in the network's hub list, which fixes its ring slot.
  final int index;

  @override
  String get sceneKey => 'hub:${hub.hash}';
}

class DeviceNode extends MeshNode {
  const DeviceNode(this.device, this.hubHash);

  final MeshDevice device;
  final String hubHash;

  @override
  String get sceneKey => 'dev:$hubHash/${device.destHash}';
}
