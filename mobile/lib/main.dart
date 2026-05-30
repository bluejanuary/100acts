import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/token.dart';
import 'screens/login_screen.dart';
import 'screens/upload_screen.dart';
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
    TokenStorage.getToken().then((t) => setState(() => _authenticated = t != null));
  }

  void _onAuth() => setState(() => _authenticated = true);
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
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
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
      length: 3,
      child: Scaffold(
        body: TabBarView(
          children: [
            const UploadScreen(),
            const MapScreen(),
            SettingsScreen(onLogout: onLogout),
          ],
        ),
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.camera_alt), text: 'Log Act'),
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
