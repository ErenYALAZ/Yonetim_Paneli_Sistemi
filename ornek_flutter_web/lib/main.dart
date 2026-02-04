import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ornek_flutter_web/utils/constants.dart';
import 'package:ornek_flutter_web/theme/app_theme.dart'; // Yeni tema dosyamız
import 'screens/auth_gate.dart';
import 'screens/intro_screen.dart';
import 'providers/supplier_tedarikci_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/job_provider.dart';
import 'providers/department_provider.dart';
import 'providers/user_provider.dart';
import 'providers/permission_provider.dart';
import 'services/auth_service.dart';
import 'providers/role_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthService()),
        ChangeNotifierProvider(create: (ctx) => SupplierTedarikciProvider()),
        ChangeNotifierProvider(create: (ctx) => AnnouncementProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (ctx) => DepartmentProvider()),
        ChangeNotifierProvider(create: (ctx) => RoleProvider()),
        ChangeNotifierProvider(create: (ctx) => UserProvider()),
        ChangeNotifierProvider(create: (ctx) => PermissionProvider()),
        ChangeNotifierProxyProvider<AuthService, JobProvider>(
          create: (ctx) => JobProvider(),
          update: (ctx, auth, previousJobProvider) {
            print("🔗 ProxyProvider Update: AuthService durumu değişti, JobProvider güncelleniyor.");
            previousJobProvider!..checkForUserChangeAndFetch();
            return previousJobProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Supabase Auth',
        theme: AppTheme.darkTheme(), // Yeni temamızı kullanıyoruz
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
