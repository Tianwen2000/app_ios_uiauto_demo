import '../pages/discover_page.dart';
import '../pages/login_page.dart';
import '../pages/profile_page.dart';
import '../pages/shell_page.dart';
import '../support/case_runner.dart';

Future<void> runSmokeLoginBrowseLogoutCase(
  CaseRunner runner, {
  required String username,
  required String password,
}) async {
  await runner.step(
    stepId: 'S001',
    stepName: 'Wait for login screen',
    body: () => LoginPage.waitForVisible(runner),
  );

  await runner.step(
    stepId: 'S002',
    stepName: 'Submit valid credentials',
    body: () async {
      await LoginPage.login(
        runner,
        stepId: 'S002',
        stepName: 'Submit valid credentials',
        username: username,
        password: password,
      );
      await DiscoverPage.waitForCatalog(runner);
    },
  );

  await runner.step(
    stepId: 'S003',
    stepName: 'Verify discover screen and search',
    body: () async {
      await DiscoverPage.waitForWelcome(runner, username);
      await DiscoverPage.search(
        runner,
        stepId: 'S003',
        stepName: 'Verify discover screen and search',
        query: 'Wave',
      );
      await runner.waitForText('Wave Headset');
    },
  );

  await runner.step(
    stepId: 'S004',
    stepName: 'Add a product to the cart',
    body: () async {
      await DiscoverPage.addFirstProductToBag(
        runner,
        stepId: 'S004',
        stepName: 'Add a product to the cart',
      );
      await runner.waitForText('0 favorites saved • 1 items queued');
    },
  );

  await runner.step(
    stepId: 'S005',
    stepName: 'Open profile and validate state',
    body: () async {
      await ShellPage.openAccount(
        runner,
        stepId: 'S005',
        stepName: 'Open profile and validate state',
      );
      await ProfilePage.waitForVisible(runner);
      await ProfilePage.waitForUsername(runner, username);
    },
  );

  await runner.step(
    stepId: 'S006',
    stepName: 'Toggle profile switches',
    body: () async {
      await ProfilePage.toggleReleaseNotifications(
        runner,
        stepId: 'S006',
        stepName: 'Toggle profile switches',
      );
      await ProfilePage.toggleExpressCheckout(
        runner,
        stepId: 'S006',
        stepName: 'Toggle profile switches',
      );
    },
  );

  await runner.step(
    stepId: 'S007',
    stepName: 'Logout back to login',
    body: () async {
      await ProfilePage.signOut(
        runner,
        stepId: 'S007',
        stepName: 'Logout back to login',
      );
      await runner.waitForText('Start shopping');
    },
  );
}
