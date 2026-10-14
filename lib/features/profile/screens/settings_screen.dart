import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// General application settings. Profile editing lives on the profile page.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _phoneVisibilityKey = 'settings_phone_visibility';
  static const String _legacyShowPhoneToPublicKey =
      'settings_show_phone_public';

  String _phoneVisibility = 'private';
  bool _loadingPreferences = true;
  bool _busyAction = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String? saved = preferences.getString(_phoneVisibilityKey);
      final String visibility =
          saved == 'public' || saved == 'friends' || saved == 'private'
          ? saved!
          : (preferences.getBool(_legacyShowPhoneToPublicKey) ?? false)
          ? 'public'
          : 'private';
      if (!mounted) return;
      setState(() {
        _phoneVisibility = visibility;
        _loadingPreferences = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingPreferences = false);
      _showSnackBar('Could not load privacy settings: $error', isError: true);
    }
  }

  Future<void> _setPhoneVisibility(String visibility) async {
    final String previous = _phoneVisibility;
    setState(() => _phoneVisibility = visibility);
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setString(_phoneVisibilityKey, visibility);
      await preferences.remove(_legacyShowPhoneToPublicKey);
    } catch (error) {
      if (!mounted) return;
      setState(() => _phoneVisibility = previous);
      _showSnackBar('Could not save privacy setting: $error', isError: true);
    }
  }

  Future<void> _signOut() async {
    if (_busyAction) return;
    final bool confirmed = await _confirmAction(
      title: 'Log out?',
      message: 'You will need to sign in again to use Milan.',
      confirmLabel: 'Log out',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busyAction = true);
    try {
      await _supabase.auth.signOut();
    } catch (error) {
      if (mounted) _showSnackBar('Could not log out: $error', isError: true);
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _deleteAccount() async {
    if (_busyAction) return;
    final bool confirmed = await _confirmAction(
      title: 'Delete account?',
      message: 'This permanently deletes your account and data. This action cannot be undone.',
      confirmLabel: 'Delete account',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busyAction = true);
    try {
      await _supabase.functions.invoke('delete-account');
      await _supabase.auth.signOut();
    } catch (error) {
      if (mounted) {
        _showSnackBar('Could not delete account: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _showNotAvailable(String feature) {
    _showSnackBar('$feature is not available yet.');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: <Widget>[
          ListTile(
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool destructive = false,
    required VoidCallback onTap,
  }) {
    final Color? color = destructive
        ? Theme.of(context).colorScheme.error
        : null;
    return ListTile(
      enabled: !_busyAction,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: _busyAction && destructive
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _busyAction ? null : onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: <Widget>[
            _section('Privacy & Phone Visibility', Icons.lock_outline, <Widget>[
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.visibility_outlined),
                title: const Text('Show number to Public'),
                subtitle: Text(
                  _phoneVisibility == 'public'
                      ? 'Your number is set to public visibility.'
                      : 'Hide my number from public profiles.',
                ),
                value: _phoneVisibility == 'public',
                onChanged: _loadingPreferences
                    ? null
                    : (bool value) =>
                          _setPhoneVisibility(value ? 'public' : 'private'),
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Only Friends'),
                subtitle: const Text('Show your number only to friends.'),
                trailing: Icon(
                  _phoneVisibility == 'friends'
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: _phoneVisibility == 'friends'
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                enabled: !_loadingPreferences,
                onTap: _loadingPreferences
                    ? null
                    : () => _setPhoneVisibility('friends'),
              ),
            ]),
            _section('Premium & Sync', Icons.stars_outlined, <Widget>[
              _tile(
                icon: Icons.workspace_premium_outlined,
                title: 'Subscription',
                onTap: () => _showNotAvailable('Subscription'),
              ),
              _tile(
                icon: Icons.sync_outlined,
                title: 'Sync Chat History',
                onTap: () => _showNotAvailable('Chat history sync'),
              ),
            ]),
            _section('Account Management', Icons.person_outline, <Widget>[
              _tile(
                icon: Icons.manage_accounts_outlined,
                title: 'Manage Account',
                subtitle: 'Account security and profile settings',
                onTap: () => _showNotAvailable('Account management'),
              ),
              _tile(
                icon: Icons.delete_outline,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account and data',
                destructive: true,
                onTap: _deleteAccount,
              ),
            ]),
            _section('Legal & Safety', Icons.gpp_good_outlined, <Widget>[
              _tile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () => _showNotAvailable('Terms of Service'),
              ),
              _tile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => _showNotAvailable('Privacy Policy'),
              ),
              _tile(
                icon: Icons.shield_outlined,
                title: 'Safety Tips',
                onTap: () => _showNotAvailable('Safety Tips'),
              ),
            ]),
            _section('Support & Action', Icons.support_agent_outlined, <Widget>[
              _tile(
                icon: Icons.help_outline,
                title: 'Help Center',
                onTap: () => _showNotAvailable('Help Center'),
              ),
              _tile(
                icon: Icons.mail_outline,
                title: 'Contact Us',
                onTap: () => _showNotAvailable('Contact Us'),
              ),
              _tile(
                icon: Icons.logout_rounded,
                title: 'Log out',
                destructive: true,
                onTap: _signOut,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
