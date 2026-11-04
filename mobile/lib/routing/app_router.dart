import 'package:go_router/go_router.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/navigation/presentation/main_nav_screen.dart';
import '../features/catalog/presentation/product_detail_screen.dart';
import '../features/catalog/presentation/custom_burger_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/checkout/presentation/order_confirmation_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/orders/models/order_model.dart';
import '../features/outlet/presentation/outlet_screen.dart';
import '../features/buddy_ai/presentation/buddy_ai_screen.dart';
import '../features/game/presentation/game_screen.dart';
import '../features/converter/presentation/converter_screen.dart';
import '../features/rewards/presentation/rewards_screen.dart';
import '../features/rewards/presentation/my_vouchers_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/support/presentation/support_chat_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/admin/presentation/admin_scaffold.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/feedback/presentation/feedback_screen.dart';
import '../features/feedback/presentation/give_feedback_screen.dart';
import '../features/ai_recommendation/models/ai_recommendation_models.dart';
import '../features/ai_recommendation/presentation/ai_recommendation_entry_screen.dart';
import '../features/ai_recommendation/presentation/ai_preference_selection_screen.dart';
import '../features/ai_recommendation/presentation/ai_processing_screen.dart';
import '../features/ai_recommendation/presentation/ai_recommendation_results_screen.dart';
import '../features/ai_recommendation/presentation/ai_burger_detail_screen.dart';
import '../features/ai_recommendation/presentation/ai_more_recommendations_screen.dart';
import '../features/ai_recommendation/presentation/ai_edit_preferences_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String profile = '/profile';
  static const String menu = '/menu';
  static const String rewards = '/rewards';
  static const String myVouchers = '/my-vouchers';
  static const String customBurger = '/custom-burger';
  static const String productDetail = '/product/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderConfirmed = '/order-confirmed';
  static const String orders = '/orders';
  static const String outlets = '/outlets';
  static const String buddy = '/buddy';
  static const String game = '/game';
  static const String converter = '/converter';
  static const String blockchain = '/blockchain';
  static const String editProfile = '/profile/edit';
  static const String supportChat = '/support-chat';
  static const String feedback = '/feedback';
  static const String giveFeedback = '/feedback/give';
  static const String notifications = '/notifications';
  static const String admin = '/admin';
  static const String aiEntry = '/ai-recommendation';
  static const String aiPreferences = '/ai-recommendation/preferences';
  static const String aiProcessing = '/ai-recommendation/processing';
  static const String aiResults = '/ai-recommendation/results';
  static const String aiBurgerDetail = '/ai-recommendation/detail';
  static const String aiMoreRecommendations = '/ai-recommendation/more';
  static const String aiEditPreferences = '/ai-recommendation/edit-preferences';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    redirect: (context, state) async {
      final location = state.matchedLocation;
      if (location.startsWith('/admin') || location.startsWith('/blockchain')) {
        final storage = SecureStorageService();
        final token = await storage.getAccessToken();
        final userData = await storage.getUserData();
        if (token == null || userData == null) {
          return '/login';
        }
        final role = (userData['role'] as String?)?.toLowerCase();
        if (role != 'admin') {
          return '/main';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: admin,
        builder: (context, state) => const AdminLayoutScreen(),
      ),
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => LoginScreen(
          initialEmail: state.extra as String?,
        ),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: main,
        builder: (context, state) => const MainNavScreen(),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const MainNavScreen(initialIndex: 4),
      ),
      GoRoute(
        path: menu,
        builder: (context, state) => const MainNavScreen(initialIndex: 1),
      ),
      GoRoute(
        path: customBurger,
        builder: (context, state) => const CustomBurgerScreen(),
      ),
      GoRoute(
        path: productDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'b-01';
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: orderConfirmed,
        builder: (context, state) {
          final order = state.extra as OrderItemModel;
          return OrderConfirmationScreen(order: order);
        },
      ),
      GoRoute(
        path: orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: outlets,
        builder: (context, state) => const OutletScreen(),
      ),
      GoRoute(
        path: buddy,
        builder: (context, state) => const BuddyAiScreen(),
      ),
      GoRoute(
        path: game,
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: rewards,
        builder: (context, state) => const RewardsScreen(),
      ),
      GoRoute(
        path: myVouchers,
        builder: (context, state) => const MyVouchersScreen(),
      ),
      GoRoute(
        path: converter,
        builder: (context, state) => const ConverterScreen(),
      ),
      GoRoute(
        path: blockchain,
        builder: (context, state) => const AdminLayoutScreen(initialIndex: 9),
      ),
      GoRoute(
        path: editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: supportChat,
        builder: (context, state) => const SupportChatScreen(),
      ),
      GoRoute(
        path: feedback,
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: giveFeedback,
        builder: (context, state) {
          final order = state.extra as OrderItemModel?;
          return GiveFeedbackScreen(order: order);
        },
      ),
      GoRoute(
        path: notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: aiEntry,
        builder: (context, state) => const AiRecommendationEntryScreen(),
      ),
      GoRoute(
        path: aiPreferences,
        builder: (context, state) => const AiPreferenceSelectionScreen(),
      ),
      GoRoute(
        path: aiProcessing,
        builder: (context, state) => const AiProcessingScreen(),
      ),
      GoRoute(
        path: aiResults,
        builder: (context, state) => const AiRecommendationResultsScreen(),
      ),
      GoRoute(
        path: aiBurgerDetail,
        builder: (context, state) {
          final rec = state.extra as BurgerRecommendation?;
          return AiBurgerDetailScreen(initialRecommendation: rec);
        },
      ),
      GoRoute(
        path: aiMoreRecommendations,
        builder: (context, state) => const AiMoreRecommendationsScreen(),
      ),
      GoRoute(
        path: aiEditPreferences,
        builder: (context, state) => const AiEditPreferencesScreen(),
      ),
    ],
  );
}
