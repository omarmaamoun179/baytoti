import 'package:equatable/equatable.dart';

import '../../domain/entities/explore_feed.dart';

enum ExploreStatus { initial, loading, loaded, error }

class ExploreState extends Equatable {
  final ExploreStatus status;
  final ExploreTab tab;
  final ExploreFeed? feed;
  final ExploreTab? feedTab;
  final bool isLoadingMore;
  final String? errorMessage;

  const ExploreState({
    this.status = ExploreStatus.initial,
    this.tab = ExploreTab.daily,
    this.feed,
    this.feedTab,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get isSwitching => status == ExploreStatus.loading && feed != null;

  ExploreState copyWith({
    ExploreStatus? status,
    ExploreTab? tab,
    ExploreFeed? feed,
    ExploreTab? feedTab,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return ExploreState(
      status: status ?? this.status,
      tab: tab ?? this.tab,
      feed: feed ?? this.feed,
      feedTab: feedTab ?? this.feedTab,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, tab, feed, feedTab, isLoadingMore, errorMessage];
}
