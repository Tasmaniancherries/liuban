import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/navigation/deep_link_guard.dart';
import 'package:liuban/core/navigation/post_login_redirect.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/models/feed_post_dto.dart';
import 'package:liuban/features/account/change_password_screen.dart';
import 'package:liuban/features/auth/forgot_password_screen.dart';
import 'package:liuban/features/auth/login_screen.dart';
import 'package:liuban/features/auth/registration_screen.dart';
import 'package:liuban/features/auth/reset_password_confirm_screen.dart';
import 'package:liuban/features/feed/feed_post_detail_screen.dart';
import 'package:liuban/features/feed/feed_screen.dart';
import 'package:liuban/features/friends/add_friend_screen.dart';
import 'package:liuban/features/friends/friend_requests_screen.dart';
import 'package:liuban/features/messages/dm_chat_screen.dart';
import 'package:liuban/features/messages/messages_screen.dart';
import 'package:liuban/features/messages/support_chat_screen.dart';
import 'package:liuban/features/profile/profile_screen.dart';
import 'package:liuban/features/promotion/promotion_detail_screen.dart';
import 'package:liuban/features/promotion/promotion_list_screen.dart';
import 'package:liuban/features/settings/blocked_users_screen.dart';
import 'package:liuban/features/settings/settings_screen.dart';
import 'package:liuban/features/shell/main_shell.dart';
import 'package:liuban/widgets/auth_required_gate.dart';
import 'package:liuban/widgets/compose_access_gate.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(
  AppSession session, {
  required AuthSessionTokens sessionTokens,
}) {
  return GoRouter(
    debugLogDiagnostics: kDebugMode,
    navigatorKey: rootNavigatorKey,
    initialLocation: '/feed',
    refreshListenable: Listenable.merge([session, sessionTokens]),
    errorBuilder: (context, state) {
      final err = state.error;
      final primary = switch (err) {
        null => ApiDevSemantics.routeErrorBodyFallbackMessage,
        GoException(:final message) =>
          ApiDevSemantics.userFacingGoRouterMessage(message),
      };
      final uriText = state.uri.toString().trim();
      final safeLoc = uriText.isEmpty ? '' : safeLocationForLog(uriText);
      final showAttemptedLoc = safeLoc.isNotEmpty && safeLoc != '/';
      return Scaffold(
        appBar: AppBar(
          title: Semantics(
            header: true,
            label: ApiDevSemantics.routeErrorScreenAppBarSemanticsLabel,
            hint: ApiDevSemantics.routeErrorScreenAppBarSemanticsHint,
            child: const Text(ApiDevSemantics.routeErrorScreenAppBarTitle),
          ),
          leading: Semantics(
            hint: '離開錯誤頁並前往廣場動態列表',
            child: IconButton(
              tooltip: '回到廣場',
              icon: const Icon(Icons.home_outlined, semanticLabel: '回到廣場'),
              onPressed: () => GoRouter.of(context).go('/feed'),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  container: true,
                  label: ApiDevSemantics.routeErrorSemanticsLabel(
                    primary,
                    attemptedSafeLocation: showAttemptedLoc ? safeLoc : null,
                  ),
                  hint: '可使用下方按鈕回到廣場動態',
                  excludeSemantics: true,
                  child: SelectionArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          primary,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (showAttemptedLoc) ...[
                          const SizedBox(height: 12),
                          Text(
                            '嘗試開啟（已脫敏）：$safeLoc',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          ApiDevSemantics.routeNotFoundFootnote,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Tooltip(
                  message: '回到廣場動態',
                  child: Semantics(
                    button: true,
                    label: '回到廣場動態',
                    hint: '離開錯誤頁並前往動態列表',
                    excludeSemantics: true,
                    child: FilledButton(
                      onPressed: () => GoRouter.of(context).go('/feed'),
                      child: const Text('回廣場'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    routes: [
      GoRoute(
        path: '/register',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => LoginScreen(
          redirectAfterLogin: sanitizePostLoginRedirect(
            state.uri.queryParameters['redirect'],
          ),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordConfirmScreen(initialToken: token);
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/blocked-users',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            const AuthRequiredGate(title: '已屏蔽用戶', child: BlockedUsersScreen()),
      ),
      GoRoute(
        path: '/account/password',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AuthRequiredGate(
          title: '修改密碼',
          child: ChangePasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/friend-requests',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AuthRequiredGate(
          title: '好友申請',
          child: FriendRequestsScreen(),
        ),
      ),
      GoRoute(
        path: '/add-friend',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            const AuthRequiredGate(title: '添加好友', child: AddFriendScreen()),
      ),
      GoRoute(
        path: '/dm/:peerId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final peerId = Uri.decodeComponent(
            state.pathParameters['peerId'] ?? '',
          );
          final custom = state.uri.queryParameters['custom'] ?? peerId;
          return AuthRequiredGate(
            title: '@$custom',
            child: DmChatScreen(peerId: peerId, peerCustomId: custom),
          );
        },
      ),
      GoRoute(
        path: '/compose',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ComposeAccessGate(),
      ),
      GoRoute(
        path: '/compose/edit/:postId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final raw = state.pathParameters['postId'] ?? '';
          final id = Uri.decodeComponent(raw);
          FeedPostDto? initial;
          final extra = state.extra;
          if (extra is FeedPostDto && extra.id == id) {
            initial = extra;
          }
          return ComposeAccessGate(editingPostId: id, initialPost: initial);
        },
      ),
      GoRoute(
        path: '/support',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SupportChatScreen(),
      ),
      GoRoute(
        path: '/post/:postId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final raw = state.pathParameters['postId'] ?? '';
          final id = Uri.decodeComponent(raw);
          final extra = state.extra;
          FeedPostDto? fallback;
          if (extra is FeedPostDto) {
            fallback = extra;
          }
          return FeedPostDetailScreen(postId: id, fallback: fallback);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: FeedScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/promotion',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: PromotionListScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return PromotionDetailScreen(promotionId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MessagesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
