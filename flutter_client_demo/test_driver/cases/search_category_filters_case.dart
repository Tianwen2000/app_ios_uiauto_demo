import '../pages/discover_page.dart';
import '../pages/login_page.dart';
import '../support/case_runner.dart';

Future<void> runSearchCategoryFiltersCase(
  CaseRunner runner, {
  required String password,
}) async {
  await runner.step(
    stepId: 'S001',
    stepName: 'Login into the demo app',
    body: () async {
      await LoginPage.waitForVisible(runner);
      await LoginPage.login(
        runner,
        stepId: 'S001',
        stepName: 'Login into the demo app',
        username: 'qa_filter',
        password: password,
      );
      await DiscoverPage.waitForWelcome(runner, 'qa_filter');
    },
  );

  await runner.step(
    stepId: 'S002',
    stepName: 'Search for a matching product',
    body: () async {
      await DiscoverPage.search(
        runner,
        stepId: 'S002',
        stepName: 'Search for a matching product',
        query: 'Wave',
      );
      await runner.waitForText('Wave Headset');
      await runner.waitForAbsentText('Focus Lamp');
    },
  );

  await runner.step(
    stepId: 'S003',
    stepName: 'Clear search and filter by category',
    body: () async {
      await DiscoverPage.search(
        runner,
        stepId: 'S003',
        stepName: 'Clear search and filter by category',
        query: '',
      );
      await DiscoverPage.filterByAudio(
        runner,
        stepId: 'S003',
        stepName: 'Clear search and filter by category',
      );
      await runner.waitForText('Wave Headset');
    },
  );

  await runner.step(
    stepId: 'S004',
    stepName: 'Drive the empty state',
    body: () async {
      await DiscoverPage.search(
        runner,
        stepId: 'S004',
        stepName: 'Drive the empty state',
        query: 'zzz',
      );
      await runner.waitForText('Try another keyword or switch categories.');
    },
  );
}
