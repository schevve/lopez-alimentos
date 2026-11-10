import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/features/auth/data/auth_service.dart';
import 'package:cesta_flow/features/auth/presentation/login_screen.dart';
import 'package:cesta_flow/features/customer/presentation/tela_clientes.dart';
import 'package:cesta_flow/features/dashboard/presentation/dashboard.dart';
import 'package:cesta_flow/features/export/presentation/data_exportation.dart';
import 'package:cesta_flow/features/sale/presentation/sale_list.dart';
import 'package:cesta_flow/features/shared/app_navigation.dart';
import 'package:cesta_flow/features/shared/bottom_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o banco SQLite para Flutter Web.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Inicializa o Supabase.
  await Supabase.initialize(
    url: 'https://vzpomvpwbqaesfezxehf.supabase.co',
    publishableKey: 'sb_publishable_Y5sHcuLfegaSCvK_c5RUFg_-ecEu179',
  );

  // Se o usuário desmarcou "Lembrar-me" no último login, encerra a sessão.
  await AuthService.instance.aplicarPreferenciaLembrarMe();

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    _enableWakeLock();
  }

  Future<void> _enableWakeLock() async {
    // No navegador, o WakeLock pode falhar quando a página
    // não está visível. Isso não deve impedir a aplicação de abrir.
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('Não foi possível ativar o WakeLock: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

/// Decide qual tela mostrar: a principal, se há usuário logado, ou o login.
/// Reage sozinho a login e logout, sem precisar de Navigator.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        return session != null ? const MainScreen() : const LoginScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _selectedKey = 'home';

  final Map<String, Widget> _pages = const {
    'home': Dashboard(),
    'sales': SalesList(),
    'customers': ClientesScreen(),
    'export': DataExportation(),
  };

  // Encerra a sessão. O AuthGate percebe o logout e volta para o login.
  Future<void> _sair() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService.instance.sair();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível sair. Verifique sua conexão e tente de novo.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = _pages.keys.toList();
    final selectedIndex = keys.indexOf(_selectedKey);

    return Scaffold(
      key: mainScaffoldKey,
      body: IndexedStack(
        index: selectedIndex >= 0 ? selectedIndex : 0,
        children: _pages.values.toList(),
      ),
      bottomNavigationBar: BottomBar(
        selectedKey: _selectedKey,
        onTap: (key) {
          if (_pages.containsKey(key)) {
            setState(() {
              _selectedKey = key;
            });
          }
        },
        buttonsIcons: const <String, (String, IconData)>{
          'home': ('Início', Icons.home_rounded),
          'sales': ('Vendas', Icons.shopping_cart_rounded),
          'customers': ('Clientes', Icons.people_rounded),
        },
      ),
      drawer: NavigationDrawer(
        backgroundColor: AppColors.primary,
        indicatorColor: AppColors.black.withAlpha(50),
        selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
        onDestinationSelected: (index) {
          // O último item do menu ("Sair") vem depois das páginas.
          if (index == keys.length) {
            Navigator.pop(context);
            _sair();
            return;
          }

          if (index >= 0 && index < keys.length) {
            setState(() {
              _selectedKey = keys[index];
            });
          }

          Navigator.pop(context);
        },
        children: [
          const SizedBox(height: 20),
          const NavigationDrawerDestination(
            icon: Icon(Icons.home_rounded, color: AppColors.white),
            label: Text('Início', style: TextStyle(color: AppColors.white)),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.shopping_cart_rounded, color: AppColors.white),
            label: Text('Vendas', style: TextStyle(color: AppColors.white)),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.people_rounded, color: AppColors.white),
            label: Text('Clientes', style: TextStyle(color: AppColors.white)),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.upload_rounded, color: AppColors.white),
            label: Text(
              'Exportar Dados',
              style: TextStyle(color: AppColors.white),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 8, 28, 8),
            child: Divider(color: Colors.white24),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.logout_rounded, color: AppColors.white),
            label: Text('Sair', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}
