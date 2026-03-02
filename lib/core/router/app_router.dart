import 'package:auto_route/auto_route.dart';
import 'package:zero_type/features/model_config/presentation/pages/model_config_page.dart';
import 'package:zero_type/features/dictionary/presentation/pages/dictionary_page.dart';
import 'package:zero_type/features/prompt/presentation/pages/prompt_page.dart';
import 'package:zero_type/features/settings/presentation/pages/settings_page.dart';
import 'package:zero_type/features/testing/presentation/pages/testing_page.dart';
import 'package:zero_type/shared/widgets/main_shell.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: MainShellRoute.page,
          initial: true,
          children: [
            AutoRoute(page: ModelConfigRoute.page),
            AutoRoute(page: DictionaryRoute.page),
            AutoRoute(page: PromptRoute.page),
            AutoRoute(page: SettingsRoute.page),
            AutoRoute(page: TestingRoute.page),
          ],
        ),
      ];
}
