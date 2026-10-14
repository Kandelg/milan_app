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
    final List<AppNotification>? items = ref.watch(notificationsProvider).value;
    if (items == null) return 0;
    return items.where((AppNotification n) => !n.isRead).length;
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final int unread = _unreadCount;

    return Scaffold(
      appBar: GlassAppBar(
        title: '',
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _NotificationAction(
              tooltip: strings.notifications,
              unreadCount: unread,
              onPressed: () => context.push(AppRoutes.notifications),
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

class _NotificationAction extends StatelessWidget {
  const _NotificationAction({
    required this.tooltip,
    required this.unreadCount,
    required this.onPressed,
  });

  final String tooltip;
  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipPath(
            clipper: const _NotificationCutClipper(),
            child: Container(
              width: 62,
              height: 52,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFFFF765C), Color(0xFFE43D3D)],
                ),
              ),
              child: Center(
                child: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
                  backgroundColor: Colors.white,
                  textColor: const Color(0xFFE43D3D),
                  child: const Icon(
                    Icons.filter_list_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCutClipper extends CustomClipper<Path> {
  const _NotificationCutClipper();

  @override
  Path getClip(Size size) => _path(size);

  Path _path(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width - 12, 0)
    ..quadraticBezierTo(size.width - 2, 0, size.width - 2, 10)
    ..lineTo(size.width, size.height - 14)
    ..quadraticBezierTo(size.width, size.height, size.width - 12, size.height)
    ..lineTo(12, size.height)
    ..quadraticBezierTo(0, size.height, 0, size.height - 12)
    ..lineTo(8, 15)
    ..quadraticBezierTo(10, 5, 0, 0)
    ..close();

  @override
  bool shouldReclip(covariant _NotificationCutClipper oldClipper) => false;
}
