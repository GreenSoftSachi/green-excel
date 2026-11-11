import 'package:flutter/material.dart';
import '../models/user_account.dart';

class AuthDialog extends StatefulWidget {
  final UserAccount currentUser;
  final Function(UserAccount account) onAccountChanged;

  const AuthDialog({
    super.key,
    required this.currentUser,
    required this.onAccountChanged,
  });

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isCustomizing = false;

  void _signInGoogle() {
    final email = _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : 'user@gmail.com';
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Google User';
    final acc = UserAccount.mockGoogle(name, email);
    widget.onAccountChanged(acc);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connected with Google Account: $email')),
    );
  }

  void _signInMicrosoft() {
    final email = _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : 'user@outlook.com';
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Microsoft User';
    final acc = UserAccount.mockMicrosoft(name, email);
    widget.onAccountChanged(acc);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connected with Microsoft Outlook 365: $email')),
    );
  }

  void _signOffline() {
    final acc = UserAccount.defaultGuest();
    widget.onAccountChanged(acc);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Switched to Local Offline Workspace')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.cloud_sync, color: Color(0xFF107C41), size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Cloud Sync & Accounts',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Current Status Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: widget.currentUser.provider == AuthProviderType.microsoft
                          ? const Color(0xFF0078D4)
                          : (widget.currentUser.provider == AuthProviderType.google
                              ? const Color(0xFFEA4335)
                              : Colors.grey.shade600),
                      child: Text(
                        widget.currentUser.displayName.isNotEmpty
                            ? widget.currentUser.displayName[0].toUpperCase()
                            : 'G',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.currentUser.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            widget.currentUser.email,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                widget.currentUser.isConnected ? Icons.check_circle : Icons.offline_bolt,
                                size: 13,
                                color: widget.currentUser.isConnected ? Colors.green : Colors.amber.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.currentUser.isConnected
                                    ? 'Auto-Sync Active (OneDrive & Drive)'
                                    : 'Offline Mode (Local Storage Only)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: widget.currentUser.isConnected ? Colors.green : Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Edit name/email toggle
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _isCustomizing = !_isCustomizing),
                  icon: Icon(_isCustomizing ? Icons.keyboard_arrow_up : Icons.tune, size: 16),
                  label: Text(_isCustomizing ? 'Hide Customization' : 'Custom Account Details', style: const TextStyle(fontSize: 12)),
                ),
              ),

              if (_isCustomizing) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'User Full Name',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Email Address',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Google Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3C4043),
                    elevation: 1,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.mail_rounded, color: Color(0xFFEA4335)),
                  label: const Text('Sign in with Google / Gmail', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _signInGoogle,
                ),
              ),
              const SizedBox(height: 10),

              // Microsoft Outlook Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0078D4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.window, color: Colors.white),
                  label: const Text('Sign in with Microsoft 365 / Outlook', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _signInMicrosoft,
                ),
              ),
              const SizedBox(height: 10),

              // Local Offline Mode
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.offline_pin_outlined),
                  label: const Text('Continue as Offline Guest'),
                  onPressed: _signOffline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
