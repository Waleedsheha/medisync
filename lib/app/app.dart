import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:medisynch/core/router/app_router.dart';
import 'package:medisynch/app/theme.dart';

class MyPatientsApp extends ConsumerWidget {
  const MyPatientsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'MediSync',
      debugShowCheckedModeBanner: false,

      // Router with auth guards
      routerConfig: router,

      // Apply the MediLaunch Theme
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
    );
  }
}
