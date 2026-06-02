import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
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
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
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
    final results = await Future.wait([
      TokenStorage.getToken(),
      Future.delayed(const Duration(seconds: 2)),
    ]);
    final token = results[0] as String?;
    final isAuth = token != null;

    if (isAuth) {
      getSystemConfig().then(SystemConfigStorage.save).catchError((_) {});
    }

    if (mounted) setState(() => _authenticated = isAuth);
  }

  void _onAuth() {
    getSystemConfig().then(SystemConfigStorage.save).catchError((_) {});
    setState(() => _authenticated = true);
  }

  void _onLogout() => setState(() => _authenticated = false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '100 Acts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF22c55e),
        textTheme: GoogleFonts.dmSansTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFf8fafc),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0f172a),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF0f172a)),
        ),
      ),
      home: _authenticated == null
          ? const SplashScreen()
          : _authenticated!
              ? MainShell(onLogout: _onLogout)
              : LoginScreen(onAuth: _onAuth),
    );
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onLogout;
  const MainShell({super.key, required this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const UploadScreen(),
      const ActsScreen(),
      const MapScreen(),
      SettingsScreen(onLogout: widget.onLogout),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.white,
        indicatorColor: const Color(0xFFdcfce7),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle, color: Color(0xFF16a34a)),
            label: 'Log Act',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: Color(0xFF16a34a)),
            label: 'My Acts',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFF16a34a)),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF16a34a)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
