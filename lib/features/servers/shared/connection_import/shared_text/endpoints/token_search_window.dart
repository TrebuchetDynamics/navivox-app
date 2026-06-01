part of '../../parser.dart';

class _SharedTextEndpointTokenSearchWindow {
  const _SharedTextEndpointTokenSearchWindow({
    required this.followingStart,
    required this.followingEnd,
    required this.leadingEnd,
    required this.canUseLeading,
  }) : assert(followingStart >= 0),
       assert(followingEnd >= followingStart),
       assert(leadingEnd >= 0),
       assert(leadingEnd <= followingStart);

  factory _SharedTextEndpointTokenSearchWindow.fromEndpoint(
    _SharedTextEndpoint endpoint,
  ) {
    return _SharedTextEndpointTokenSearchWindow(
      followingStart: endpoint.tokenWindow.start,
      followingEnd: endpoint.tokenWindow.end,
      leadingEnd: endpoint.sourceWindow.start,
      canUseLeading: !endpoint.hasPriorEndpoint,
    );
  }

  final int followingStart;
  final int followingEnd;
  final int leadingEnd;
  final bool canUseLeading;

  _SharedTextTokenProvenance get provenance {
    return _SharedTextTokenProvenance(
      hasSelectedEndpoint: true,
      followingSearchStart: followingStart,
      followingSearchEnd: followingEnd,
      leadingSearchEnd: canUseLeading ? leadingEnd : 0,
    );
  }
}
