/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2020 - 2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wger/core/app_settings_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/dashboard.dart';
import 'package:wger/core/material.dart';
import 'package:wger/features/account/providers/timezone_sync.dart';
import 'package:wger/features/gallery/screens/gallery_screen.dart';
import 'package:wger/features/health/providers/health_sync.dart';
import 'package:wger/features/measurements/screens/measurement_categories_screen.dart';
import 'package:wger/features/nutrition/screens/nutritional_plans_screen.dart';
import 'package:wger/features/routines/screens/routine_list_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/features/onboarding/meu_fit_onboarding_profile.dart';
import 'package:wger/features/measurements/screens/weight_screen.dart';
import 'package:wger/features/account/widgets/settings.dart';

class HomeTabsScreen extends ConsumerStatefulWidget {
  const HomeTabsScreen({super.key});

  static const routeName = '/dashboard2';

  @override
  ConsumerState<HomeTabsScreen> createState() => _HomeTabsScreenState();
}

class _HomeTabsScreenState extends ConsumerState<HomeTabsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isWideScreen = false;

  @override
  void initState() {
    super.initState();

    // Pull any new readings from Apple Health / Health Connect once the app is
    // open. A no-op unless the user enabled it in the settings, and unless the
    // last sync is long enough ago.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(healthSyncProvider.notifier).syncIfDue();

      // Report the device timezone to the profile, so the server calculates
      // streaks and trophies in the user's own zone. A no-op when unchanged.
      ref.read(timezoneSyncProvider).reportIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final size = MediaQuery.sizeOf(context);
    _isWideScreen = size.width > MATERIAL_XS_BREAKPOINT;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _changeLanguage(Locale locale) async {
    await ref.read(appSettingsProvider.notifier).setUserLocale(locale);
  }

  final _screenList = [
    const DashboardScreen(),
    const RoutineListScreen(),
    const NutritionalPlansScreen(),
    const MeasurementCategoriesScreen(),
    const GalleryScreen(),
    const _MeuFitProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.home),
        label: 'Início',
      ),
      NavigationDestination(
        icon: const Icon(Icons.fitness_center),
        label: 'Treinos',
      ),
      NavigationDestination(
        icon: const Icon(Icons.restaurant),
        label: 'Nutrição',
      ),
      NavigationDestination(
        icon: const Icon(Icons.area_chart),
        label: 'Evolução',
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        label: 'Perfil',
      ),
    ];

    /// Navigation bar for narrow screens
    Widget getNavigationBar() {
      return NavigationBar(
        destinations: destinations,
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: const Color(0xFF181818),
        indicatorColor: const Color(0xFFC9F31D),
      );
    }

    /// Navigation rail for wide screens
    Widget getNavigationRail() {
      return NavigationRail(
        backgroundColor: const Color(0xFF181818),
        indicatorColor: const Color(0xFFC9F31D),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelType: NavigationRailLabelType.all,
        scrollable: true,
        destinations: destinations
            .map(
              (d) => NavigationRailDestination(
                icon: d.icon,
                label: Text(d.label),
              ),
            )
            .toList(),
      );
    }

    final currentLanguage = ref.watch(appSettingsProvider).asData?.value.userLocale?.languageCode ?? 'pt';

    return Scaffold(
      floatingActionButton: _selectedIndex == 0
          ? PopupMenuButton<String>(
              tooltip: 'Idioma / Language',
              icon: const Icon(Icons.language),
              initialValue: currentLanguage,
              onSelected: (language) => _changeLanguage(language == 'pt' ? const Locale('pt', 'BR') : const Locale('en')),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'pt', child: Text('Português (Brasil)')),
                PopupMenuItem(value: 'en', child: Text('English')),
              ],
            )
          : null,
      body: Row(
        children: [
          if (_isWideScreen) getNavigationRail(),
          Expanded(child: _screenList.elementAt(_selectedIndex)),
        ],
      ),
      bottomNavigationBar: _isWideScreen ? null : getNavigationBar(),
    );
  }
}

class _MeuFitProfileScreen extends StatelessWidget {
  const _MeuFitProfileScreen();

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFC9F31D);
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: FutureBuilder<MeuFitOnboardingProfile?>(
        future: MeuFitOnboardingStorage().load(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFF242424),
                child: Icon(Icons.person, size: 48, color: lime),
              ),
              const SizedBox(height: 12),
              const Center(child: Text('MEU FIT · MEU PERFIL',
                style: TextStyle(color: lime, fontWeight: FontWeight.bold))),
              const SizedBox(height: 20),
              Card(
                color: const Color(0xFF242424),
                child: Column(children: [
                  ListTile(title: const Text('Peso inicial'),
                    subtitle: Text(profile == null ? 'Complete seu cadastro'
                      : '${profile.weightKg.toStringAsFixed(1)} kg')),
                  ListTile(title: const Text('Altura'),
                    subtitle: Text(profile == null ? 'Não informada'
                      : '${profile.heightCm.toStringAsFixed(0)} cm')),
                  ListTile(title: const Text('Meta de treinos'),
                    subtitle: Text(profile == null ? 'Não informada'
                      : '${profile.daysPerWeek} dias por semana')),
                ]),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.monitor_weight, color: lime),
                title: const Text('Meu peso e histórico'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, WeightScreen.routeName),
              ),
              ListTile(
                leading: const Icon(Icons.straighten, color: lime),
                title: const Text('Medidas corporais'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                  builder: (_) => const MeasurementCategoriesScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.restaurant, color: lime),
                title: const Text('Alimentação e planos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                  builder: (_) => const NutritionalPlansScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: lime),
                title: const Text('Configurações'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                  builder: (_) => const SettingsPage())),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Foto editável: recurso em desenvolvimento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70)),
              ),
            ],
          );
        },
      ),
    );
  }
}
