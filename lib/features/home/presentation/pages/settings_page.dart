import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/app_settings.dart';
import '../../../../app/l10n/app_strings.dart';
import '../../../../app/l10n/lang_builder.dart';
import '../../../../app/privacy_policy_page.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/data/services/profile_photo_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../prayer/data/services/prayer_notification_service.dart';
import '../cubit/home_cubit.dart';
import '../widgets/app_tab_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _refreshingLocation = false;
  String? _localPhotoPath;
  bool _hideRemotePhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocalPhoto());
  }

  Future<void> _loadLocalPhoto() async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;
    final path = await ProfilePhotoService.pathFor(auth.user.uid);
    final hidden = await ProfilePhotoService.isRemoteHidden(auth.user.uid);
    if (mounted) {
      setState(() {
        _localPhotoPath = path;
        _hideRemotePhoto = hidden;
      });
    }
  }

  Future<void> _changeProfilePhoto(User user) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Photo de profil',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textOf(ctx),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primaryOf(ctx),
                  ),
                  title: Text(
                    'Choisir depuis la galerie',
                    style: TextStyle(color: AppColors.textOf(ctx)),
                  ),
                  onTap: () => Navigator.pop(ctx, 'gallery'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.primaryOf(ctx),
                  ),
                  title: Text(
                    'Prendre une photo',
                    style: TextStyle(color: AppColors.textOf(ctx)),
                  ),
                  onTap: () => Navigator.pop(ctx, 'camera'),
                ),
                if (_localPhotoPath != null ||
                    (!_hideRemotePhoto && user.photoURL != null))
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.isDark(ctx)
                          ? AppColors.darkError
                          : const Color(0xFFC0392B),
                    ),
                    title: Text(
                      'Supprimer la photo',
                      style: TextStyle(
                        color: AppColors.isDark(ctx)
                            ? AppColors.darkError
                            : const Color(0xFFC0392B),
                      ),
                    ),
                    onTap: () => Navigator.pop(ctx, 'remove'),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null || !mounted) return;

    try {
      if (choice == 'remove') {
        await ProfilePhotoService.clear(user.uid);
        if (mounted) {
          setState(() {
            _localPhotoPath = null;
            _hideRemotePhoto = true;
          });
        }
        return;
      }

      final source =
          choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final path = await ProfilePhotoService.pickAndSave(
        uid: user.uid,
        source: source,
      );
      if (!mounted) return;
      if (path == null) return;
      setState(() {
        _localPhotoPath = path;
        _hideRemotePhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.photoUpdated)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.photoFailed)),
      );
    }
  }

  Future<void> _refreshLocation() async {
    final homeCubit = context.read<HomeCubit>();
    setState(() => _refreshingLocation = true);
    try {
      final ok = await homeCubit.requestUserLocation();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? S.locationUpdated : S.locationFailed),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.locationFailed)),
      );
    } finally {
      if (mounted) setState(() => _refreshingLocation = false);
    }
  }

  Future<void> _changeDisplayName(User user) async {
    final controller = TextEditingController(text: user.displayName ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nom d’affichage'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Ton prénom',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.save),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (ok != true || !mounted) return;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom ne peut pas être vide')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final error = await context.read<AuthCubit>().updateDisplayName(name);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Nom mis à jour')),
    );
  }

  Future<void> _changePassword(User user) async {
    final cubit = context.read<AuthCubit>();
    if (!cubit.hasPasswordProvider(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compte Google : le mot de passe se change dans ton compte Google.',
          ),
        ),
      );
      return;
    }

    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;
    String? formError;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Modifier le mot de passe'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentCtrl,
                      obscureText: obscureCurrent,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe actuel',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setLocal(
                            () => obscureCurrent = !obscureCurrent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        helperText: 'Minimum 6 caractères',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setLocal(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirmer',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setLocal(
                            () => obscureConfirm = !obscureConfirm,
                          ),
                        ),
                      ),
                    ),
                    if (formError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        formError!,
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(S.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final current = currentCtrl.text;
                    final next = newCtrl.text;
                    final confirm = confirmCtrl.text;
                    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
                      setLocal(
                        () => formError = 'Remplis tous les champs',
                      );
                      return;
                    }
                    if (next.length < 6) {
                      setLocal(
                        () => formError =
                            'Le nouveau mot de passe doit avoir au moins 6 caractères',
                      );
                      return;
                    }
                    if (next != confirm) {
                      setLocal(
                        () => formError =
                            'Les nouveaux mots de passe ne correspondent pas',
                      );
                      return;
                    }
                    if (next == current) {
                      setLocal(
                        () => formError =
                            'Le nouveau mot de passe doit être différent',
                      );
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: Text(S.save),
                ),
              ],
            );
          },
        );
      },
    );

    final current = currentCtrl.text;
    final next = newCtrl.text;
    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();

    if (submitted != true || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final error = await cubit.updatePassword(
      currentPassword: current,
      newPassword: next,
    );
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Mot de passe mis à jour')),
    );
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final homeCubit = context.read<HomeCubit>();
    final notif = PrayerNotificationService.instance;
    if (!enabled) {
      await AppSettings.setNotificationsEnabled(false);
      await notif.cancelAll();
      homeCubit.invalidateNotifSync();
      return;
    }

    final ok = await notif.requestPermissions();
    if (!mounted) return;
    if (!ok) {
      await AppSettings.setNotificationsEnabled(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.notifAllow)),
      );
      setState(() {});
      return;
    }

    await AppSettings.setNotificationsEnabled(true);
    homeCubit.invalidateNotifSync();
    await homeCubit.load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context, _) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final user =
                authState is AuthAuthenticated ? authState.user : null;

            return ColoredBox(
              color: AppColors.scaffoldOf(context),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                      children: [
                        AppTabHeader(title: S.settings),
                    const SizedBox(height: 18),
                    _SectionLabel(S.account),
                    const SizedBox(height: 10),
                    _AccountCard(
                      user: user,
                      localPhotoPath: _localPhotoPath,
                      hideRemotePhoto: _hideRemotePhoto,
                      onEditPhoto: user == null
                          ? null
                          : () => _changeProfilePhoto(user),
                      onEditName: user == null
                          ? null
                          : () => _changeDisplayName(user),
                      onChangePassword: user == null
                          ? null
                          : () => _changePassword(user),
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel(S.preferences),
                    const SizedBox(height: 10),
                    const _PreferencesCard(),
                    const SizedBox(height: 22),
                    _SectionLabel(S.system),
                    const SizedBox(height: 10),
                    _SystemCard(
                      refreshingLocation: _refreshingLocation,
                      onRefreshLocation: _refreshLocation,
                      onToggleNotifs: _toggleNotifications,
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel(S.about),
                    const SizedBox(height: 10),
                    _AboutCard(
                      onPrivacy: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PrivacyPolicyPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    _LogoutButton(
                      onTap: () => context.read<AuthCubit>().signOut(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Noor Al-Iman v1.0.0 • 2026',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.mutedOf(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.mutedOf(context),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.user,
    required this.localPhotoPath,
    required this.hideRemotePhoto,
    required this.onEditPhoto,
    required this.onEditName,
    required this.onChangePassword,
  });

  final User? user;
  final String? localPhotoPath;
  final bool hideRemotePhoto;
  final VoidCallback? onEditPhoto;
  final VoidCallback? onEditName;
  final VoidCallback? onChangePassword;

  ImageProvider? get _avatarImage {
    if (localPhotoPath != null) {
      return FileImage(File(localPhotoPath!));
    }
    if (!hideRemotePhoto && user?.photoURL != null) {
      return NetworkImage(user!.photoURL!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Utilisateur Noor';
    final email = user?.email ?? '—';
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatar = _avatarImage;

    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onEditPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      key: ValueKey(localPhotoPath ?? user?.photoURL ?? 'none'),
                      radius: 32,
                      backgroundColor: AppColors.chipOf(context),
                      backgroundImage: avatar,
                      child: avatar == null
                          ? Text(
                              letter,
                              style: TextStyle(
                                color: AppColors.primaryOf(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOf(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.cardOf(context),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 12,
                          color: AppColors.onPrimaryOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppColors.textOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        color: AppColors.mutedOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.borderOf(context)),
          _SettingsTile(
            icon: Icons.photo_camera_outlined,
            title: 'Changer la photo de profil',
            onTap: onEditPhoto,
          ),
          Divider(height: 1, color: AppColors.borderOf(context)),
          _SettingsTile(
            icon: Icons.edit_outlined,
            title: 'Changer le nom d’affichage',
            onTap: onEditName,
          ),
          Divider(height: 1, color: AppColors.borderOf(context)),
          _SettingsTile(
            icon: Icons.lock_reset_rounded,
            title: 'Modifier le mot de passe',
            onTap: onChangePassword,
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.appLanguage,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textOf(context),
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<String>(
            valueListenable: AppSettings.lang,
            builder: (context, lang, _) {
              return Row(
                children: [
                  for (final entry in const [
                    ('fr', 'Français'),
                    ('ar', 'العربية'),
                    ('en', 'English'),
                  ]) ...[
                    Expanded(
                      child: _LangChip(
                        label: entry.$2,
                        selected: lang == entry.$1,
                        onTap: () => AppSettings.setLang(entry.$1),
                      ),
                    ),
                    if (entry.$1 != 'en') const SizedBox(width: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            S.theme,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textOf(context),
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppSettings.themeMode,
            builder: (context, mode, _) {
              return Row(
                children: [
                  Expanded(
                    child: _ThemeBox(
                      icon: Icons.wb_sunny_outlined,
                      label: S.light,
                      selected: mode == ThemeMode.light,
                      onTap: () => AppSettings.setThemeMode(ThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ThemeBox(
                      icon: Icons.dark_mode_outlined,
                      label: S.dark,
                      selected: mode == ThemeMode.dark,
                      onTap: () => AppSettings.setThemeMode(ThemeMode.dark),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SystemCard extends StatelessWidget {
  const _SystemCard({
    required this.refreshingLocation,
    required this.onRefreshLocation,
    required this.onToggleNotifs,
  });

  final bool refreshingLocation;
  final VoidCallback onRefreshLocation;
  final ValueChanged<bool> onToggleNotifs;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, next) {
        final a = prev is HomeLoaded ? prev.data.location.label : null;
        final b = next is HomeLoaded ? next.data.location.label : null;
        return a != b;
      },
      builder: (context, homeState) {
        final locationLabel =
            homeState is HomeLoaded ? homeState.data.location.label : '—';

        return _Card(
          child: Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: AppSettings.notificationsEnabled,
                builder: (context, enabled, _) {
                  return Row(
                    children: [
                      const _RoundIcon(Icons.notifications_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.notifications,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textOf(context),
                              ),
                            ),
                            Text(
                              'Adhan et rappels quotidiens',
                              style: TextStyle(
                                color: AppColors.mutedOf(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: enabled,
                        onChanged: onToggleNotifs,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: AppColors.borderOf(context)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _RoundIcon(Icons.location_on_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          S.locationHint,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.mutedOf(context),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: S.refreshLocation,
                    onPressed: refreshingLocation ? null : onRefreshLocation,
                    visualDensity: VisualDensity.compact,
                    icon: refreshingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            color: AppColors.primaryOf(context),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.isDark(context)
                      ? AppColors.darkSurfaceHigh
                      : const Color(0xFFE8F4FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 20,
                      color: AppColors.isDark(context)
                          ? AppColors.darkPrimary
                          : const Color(0xFF3B82A0),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        locationLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          height: 1.3,
                          color: AppColors.textOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark(context);
    return Material(
      color: dark ? const Color(0xFF3A1C1C) : const Color(0xFFFDECEC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: dark ? AppColors.darkError : const Color(0xFFC0392B),
              ),
              const SizedBox(width: 8),
              Text(
                S.logout,
                style: TextStyle(
                  color: dark ? AppColors.darkError : const Color(0xFFC0392B),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.onPrivacy});

  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: InkWell(
        onTap: onPrivacy,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: AppColors.primaryOf(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.privacyPolicy,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textOf(context),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardOf(context),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.isDark(context)
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.deco.withValues(alpha: 0.7),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryOf(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textOf(context),
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedBg = AppColors.isDark(context)
        ? AppColors.darkPrimaryContainer
        : AppColors.primary;
    final idleBg = AppColors.isDark(context)
        ? AppColors.darkSurfaceHigh
        : const Color(0xFFF0EFEA);
    return Material(
      color: selected ? selectedBg : idleBg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? (AppColors.isDark(context)
                        ? AppColors.darkPrimary
                        : Colors.white)
                    : AppColors.mutedOf(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeBox extends StatelessWidget {
  const _ThemeBox({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark(context);
    final selectedBg =
        dark ? AppColors.darkPrimaryContainer : const Color(0xFFE8F3EF);
    final idleBg = dark ? AppColors.darkSurfaceHigh : const Color(0xFFF7F6F2);
    final accent = AppColors.accentOf(context);
    return Material(
      color: selected ? selectedBg : idleBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : AppColors.borderOf(context),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? accent : AppColors.mutedOf(context),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? accent : AppColors.mutedOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.chipOf(context),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primaryOf(context), size: 20),
    );
  }
}
