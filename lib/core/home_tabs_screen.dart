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

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wger/core/app_settings_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/dashboard.dart';
import 'package:wger/core/material.dart';
import 'package:wger/features/account/providers/timezone_sync.dart';
import 'package:wger/features/health/providers/health_sync.dart';
import 'package:wger/features/measurements/screens/measurement_categories_screen.dart';
import 'package:wger/features/nutrition/screens/meu_fit_taco_food_search_screen.dart';
import 'package:wger/features/smart_training/meu_fit_workouts_screen.dart';
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
    const MeuFitWorkoutsScreen(),
    const MeuFitTacoFoodSearchScreen(),
    const MeasurementCategoriesScreen(),
    const _MeuFitProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Keep icons visible on both states: white on the dark bar and black
    // when the lime selected indicator is shown.
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.home, color: Colors.white),
        selectedIcon: const Icon(Icons.home, color: Colors.black),
        label: 'Início',
      ),
      NavigationDestination(
        icon: const Icon(Icons.fitness_center, color: Colors.white),
        selectedIcon: const Icon(Icons.fitness_center, color: Colors.black),
        label: 'Treinos',
      ),
      NavigationDestination(
        icon: const Icon(Icons.restaurant, color: Colors.white),
        selectedIcon: const Icon(Icons.restaurant, color: Colors.black),
        label: 'Dieta',
      ),
      NavigationDestination(
        icon: const Icon(Icons.area_chart, color: Colors.white),
        selectedIcon: const Icon(Icons.area_chart, color: Colors.black),
        label: 'Evolução',
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline, color: Colors.white),
        selectedIcon: const Icon(Icons.person_outline, color: Colors.black),
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
                selectedIcon: d.selectedIcon,
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

class _MeuFitProfileScreen extends StatefulWidget {
  const _MeuFitProfileScreen();

  @override
  State<_MeuFitProfileScreen> createState() => _MeuFitProfileScreenState();
}

class _MeuFitProfileScreenState extends State<_MeuFitProfileScreen> {
  static const _lime = Color(0xFFC9F31D);
  static const _coverKey = 'meu_fit_profile_cover_path_v1';
  static const _nameKey = 'meu_fit_display_name_v1';
  final _picker = ImagePicker();
  String? _coverPath;
  String? _displayName;
  bool _loadingCover = true;
  bool _pickingCover = false;

  @override
  void initState() {
    super.initState();
    _loadProfilePresentation();
  }

  Future<void> _loadProfilePresentation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_coverKey);
    if (!mounted) return;
    setState(() {
      _displayName = prefs.getString(_nameKey);
      _coverPath = savedPath != null && File(savedPath).existsSync() ? savedPath : null;
      _loadingCover = false;
    });
  }

  Future<void> _chooseCover() async {
    if (_pickingCover) return;
    setState(() => _pickingCover = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1800,
      );
      if (picked == null || !mounted) return;

      // Keep a private copy in app storage; picker cache paths can be temporary.
      final directory = await getApplicationDocumentsDirectory();
      final destination = '${directory.path}/meu_fit_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(picked.path).copy(destination);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_coverKey, savedFile.path);
      if (!mounted) return;
      setState(() => _coverPath = savedFile.path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de capa atualizada!')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a foto. Tente escolher outra imagem.')),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingCover = false);
    }
  }

  Future<void> _removeCover() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coverKey);
    final oldPath = _coverPath;
    if (mounted) setState(() => _coverPath = null);
    if (oldPath != null) {
      try { await File(oldPath).delete(); } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: FutureBuilder<MeuFitOnboardingProfile?>(
        future: MeuFitOnboardingStorage().load(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final hasCover = _coverPath != null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasCover)
                        Image.file(File(_coverPath!), fit: BoxFit.cover)
                      else
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF344018), Color(0xFF202020), Color(0xFF121212)],
                            ),
                          ),
                          child: Center(child: Icon(Icons.person, size: 74, color: _lime)),
                        ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withValues(alpha: 0.08), Colors.black.withValues(alpha: 0.72)],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: PopupMenuButton<String>(
                          tooltip: 'Editar foto de capa',
                          icon: const Icon(Icons.more_horiz, color: Colors.white),
                          color: const Color(0xFF242424),
                          onSelected: (value) {
                            if (value == 'edit') _chooseCover();
                            if (value == 'remove') _removeCover();
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Escolher foto')),
                            if (hasCover) const PopupMenuItem(value: 'remove', child: Text('Remover foto')),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    (_displayName?.trim().isNotEmpty ?? false) ? _displayName!.trim() : 'Meu perfil',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Seu espaço, sua evolução', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonalIcon(
                              onPressed: _pickingCover ? null : _chooseCover,
                              icon: _pickingCover
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.add_a_photo_outlined, size: 18),
                              label: Text(_pickingCover ? 'Salvando' : 'Editar capa'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _lime,
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loadingCover) const LinearProgressIndicator(minHeight: 2, color: _lime),
              const SizedBox(height: 22),
              const Text('DADOS DO PERFIL', style: TextStyle(color: _lime, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Card(
                color: const Color(0xFF242424),
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.monitor_weight_outlined, color: _lime),
                    title: const Text('Peso inicial'),
                    subtitle: Text(profile == null ? 'Complete seu cadastro' : '${profile.weightKg.toStringAsFixed(1)} kg'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.height, color: _lime),
                    title: const Text('Altura'),
                    subtitle: Text(profile == null ? 'Não informada' : '${profile.heightCm.toStringAsFixed(0)} cm'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined, color: _lime),
                    title: const Text('Meta de treinos'),
                    subtitle: Text(profile == null ? 'Não informada' : '${profile.daysPerWeek} dias por semana'),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.monitor_weight, color: _lime),
                title: const Text('Meu peso e histórico'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, WeightScreen.routeName),
              ),
              ListTile(
                leading: const Icon(Icons.straighten, color: _lime),
                title: const Text('Medidas corporais'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                  builder: (_) => const MeasurementCategoriesScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.restaurant, color: _lime),
                title: const Text('Dieta e planos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                  builder: (_) => const MeuFitTacoFoodSearchScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: _lime),
                title: const Text('Configurações'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                  builder: (_) => const SettingsPage())),
              ),
            ],
          );
        },
      ),
    );
  }
}
