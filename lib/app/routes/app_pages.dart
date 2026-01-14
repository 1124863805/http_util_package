import 'package:get/get.dart';

import '../modules/about/bindings/about_binding.dart';
import '../modules/about/views/about_view.dart';
import '../modules/birth_info_form/bindings/birth_info_form_binding.dart';
import '../modules/birth_info_form/views/birth_info_form_view.dart';
import '../modules/chat/bindings/chat_binding.dart';
import '../modules/chat/views/chat_view.dart';
import '../modules/daily_yunshi/bindings/daily_yunshi_binding.dart';
import '../modules/daily_yunshi/views/daily_yunshi_view.dart';
import '../modules/demo/bindings/demo_binding.dart';
import '../modules/demo/views/demo_view.dart';
import '../modules/feedback/bindings/feedback_binding.dart';
import '../modules/feedback/views/feedback_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/main/bindings/main_binding.dart';
import '../modules/main/views/main_view.dart';
import '../modules/membership/bindings/membership_binding.dart';
import '../modules/membership/views/membership_view.dart';
import '../modules/mine/bindings/mine_binding.dart';
import '../modules/mine/views/mine_view.dart';
import '../modules/monthly_yunshi/bindings/monthly_yunshi_binding.dart';
import '../modules/monthly_yunshi/views/monthly_yunshi_view.dart';
import '../modules/my_orders/bindings/my_orders_binding.dart';
import '../modules/my_orders/views/my_orders_view.dart';
import '../modules/my_profile/bindings/my_profile_binding.dart';
import '../modules/my_profile/views/my_profile_view.dart';
import '../modules/my_reports/bindings/my_reports_binding.dart';
import '../modules/my_reports/views/my_reports_view.dart';
import '../modules/pet/bindings/pet_binding.dart';
import '../modules/pet/views/pet_view.dart';
import '../modules/privacy/bindings/privacy_binding.dart';
import '../modules/privacy/views/privacy_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/yunshi/bindings/yunshi_binding.dart';
import '../modules/yunshi/views/yunshi_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.PRIVACY;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.PET,
      page: () => const PetView(),
      binding: PetBinding(),
    ),
    GetPage(name: _Paths.CHAT, page: () => ChatView(), binding: ChatBinding()),
    GetPage(
      name: _Paths.MINE,
      page: () => const MineView(),
      binding: MineBinding(),
    ),
    GetPage(
      name: _Paths.MAIN,
      page: () => const MainView(),
      binding: MainBinding(),
    ),
    GetPage(
      name: _Paths.PRIVACY,
      page: () => const PrivacyView(),
      binding: PrivacyBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.YUNSHI,
      page: () => const YunshiView(),
      binding: YunshiBinding(),
    ),
    GetPage(
      name: _Paths.DAILY_YUNSHI,
      page: () => const DailyYunshiView(),
      binding: DailyYunshiBinding(),
    ),
    GetPage(
      name: _Paths.MONTHLY_YUNSHI,
      page: () => const MonthlyYunshiView(),
      binding: MonthlyYunshiBinding(),
    ),
    GetPage(
      name: _Paths.MY_ORDERS,
      page: () => const MyOrdersView(),
      binding: MyOrdersBinding(),
    ),
    GetPage(
      name: _Paths.MY_REPORTS,
      page: () => const MyReportsView(),
      binding: MyReportsBinding(),
    ),
    GetPage(
      name: _Paths.MY_PROFILE,
      page: () => const MyProfileView(),
      binding: MyProfileBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: _Paths.MEMBERSHIP,
      page: () => const MembershipView(),
      binding: MembershipBinding(),
    ),
    GetPage(
      name: _Paths.ABOUT,
      page: () => const AboutView(),
      binding: AboutBinding(),
    ),
    GetPage(
      name: _Paths.FEEDBACK,
      page: () => const FeedbackView(),
      binding: FeedbackBinding(),
    ),
    GetPage(
      name: _Paths.BIRTH_INFO_FORM,
      page: () => const BirthInfoFormView(),
      binding: BirthInfoFormBinding(),
    ),
    GetPage(
      name: _Paths.DEMO,
      page: () => const DemoView(),
      binding: DemoBinding(),
    ),
  ];
}
