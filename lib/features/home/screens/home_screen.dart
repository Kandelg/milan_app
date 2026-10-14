import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milan_app/app/router.dart';
import 'package:milan_app/core/glass.dart';
import 'package:milan_app/core/localization.dart';
import 'package:milan_app/data/models.dart';
import 'package:milan_app/features/home/home_controller.dart';
import 'package:milan_app/features/home/tabs/for_you_tab.dart';
import 'package:milan_app/features/home/tabs/liked_tab.dart';
import 'package:milan_app/features/home/tabs/new_tab.dart';
import 'package:milan_app/features/home/tabs/requested_tab.dart';

/// The Home screen: a notifications bell plus four sub-tabs —
/// For You, New, Requested and Liked.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _unreadCount {
    final List<AppNotification>? items =
        ref.watch(notificationsProvider).value;
    if (items == null) return 0;
    return items.where((AppNotification n) => !n.isRead).length;
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final int unread = _unreadCount;

    return Scaffold(
      appBar: GlassAppBar(
        title: strings.home,
        actions: <Widget>[
          IconButton(
            tooltip: strings.notifications,
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_none),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: Theme.of(context).colorScheme.primary,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            tabs: <Widget>[
              Tab(text: strings.forYou),
              Tab(text: strings.new_),
              Tab(text: strings.requested),
              Tab(text: strings.liked),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const <Widget>[
                ForYouTab(),
                NewTab(),
                RequestedTab(),
                LikedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
