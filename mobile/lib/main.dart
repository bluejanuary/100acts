import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/token.dart';
import 'services/api.dart';
import 'services/system_config_storage.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/acts_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool? _authenticated;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await TokenStorage.getToken();
    final isAuth = token != null;

    if (isAuth) {
      // Refresh system config in background; ignore failures (cached copy still used)
      getSystemConfig().then(SystemConfigStorage.save).catchError((_) {});
    }

    if (mounted) setState(() => _authenticated = isAuth);
  }

  void _onAuth() {
    // Fetch system config immediately after login
    getSystemConfig().then(SystemConfigStorage.save).catchError((_) {});
    setState(() => _authenticated = true);
  }

  void _onLogout() => setState(() => _authenticated = false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '100acts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF22c55e),
        useMaterial3: true,
      ),
      home: _authenticated == null
          ? const SplashScreen()
          : _authenticated!
              ? MainTabs(onLogout: _onLogout)
              : LoginScreen(onAuth: _onAuth),
    );
  }
}

class MainTabs extends StatelessWidget {
  final VoidCallback onLogout;
  const MainTabs({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: TabBarView(
          children: [
            const UploadScreen(),
            const ActsScreen(),
            const MapScreen(),
            SettingsScreen(onLogout: onLogout),
          ],
        ),
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.camera_alt), text: 'Log Act'),
            Tab(icon: Icon(Icons.list_alt), text: 'My Acts'),
            Tab(icon: Icon(Icons.map), text: 'Map'),
            Tab(icon: Icon(Icons.person), text: 'Settings'),
          ],
          labelColor: Color(0xFF22c55e),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF22c55e),
        ),
      ),
    );
  }
}
