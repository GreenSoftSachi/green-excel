import 'package:flutter/material.dart';

class AboutAppDialog extends StatelessWidget {
  const AboutAppDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF107C41),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF107C41).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'X',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title & Play Store Badge
              const Text(
                'Green Excel',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Color(0xFF107C41),
                ),
              ),
              const Text(
                'Green Exacl Pro (Edition 2026)',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: Color(0xFF2E7D32)),
                    SizedBox(width: 4),
                    Text(
                      'Google Play Store Production Ready • v1.0.0 (Build 1)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Developer Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFF107C41),
                      child: Icon(Icons.engineering, size: 32, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sachinthaka Sandaruwan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF107C41).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF107C41)),
                      ),
                      child: const Text(
                        'Research and Development Engineer (Software and Hardware)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF86EFAC),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Green Soft Technologies',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // July 2026 Features List
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.new_releases, color: Color(0xFF107C41), size: 18),
                        SizedBox(width: 6),
                        Text(
                          '2026 Modern Excel Features Included:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _featureItem('Copilot in Excel (July 2026)', 'GPT-5.6, Claude Opus 5 & Gemini 2.5 natural language engine'),
                    _featureItem('Interactive Checkboxes', 'Insert > Checkbox support with reactive TRUE/FALSE toggling'),
                    _featureItem('2026 Regex Engine', '=REGEXTEST(), =REGEXEXTRACT(), and =REGEXREPLACE()'),
                    _featureItem('Python in Excel (=PY)', 'Execute inline Python data analysis and list comprehensions'),
                    _featureItem('Modern Lookups & Arrays', 'XLOOKUP, Dynamic Arrays (UNIQUE, SORT, SEQUENCE)'),
                    _featureItem('Print & Export Engine', 'Direct AirPrint/WiFi print, A4/Letter PDF generator, CSV share'),
                    _featureItem('Dual Cloud Auth', 'Google / Gmail Sign-in + Microsoft 365 / Outlook Sync'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Privacy Policy and Legal
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                    label: const Text('Privacy Policy', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showPrivacyPolicy(context),
                  ),
                  const Text('•', style: TextStyle(color: Colors.grey)),
                  TextButton.icon(
                    icon: const Icon(Icons.gavel_outlined, size: 16),
                    label: const Text('Google Play Ready', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showPlayStoreInfo(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF107C41),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✔ ', style: TextStyle(color: Color(0xFF107C41), fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11, color: Colors.black87),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy for Green Excel'),
        content: const SingleChildScrollView(
          child: Text(
            'Effective Date: November 2026\n\n'
            'Green Excel ("the Application"), developed by Sachinthaka Sandaruwan (Green Soft Technologies), '
            'respects your privacy and is committed to protecting your personal data.\n\n'
            '1. Data Collection: All spreadsheet calculations, cell data, and formulas are processed locally on your device. '
            'We do not transmit your spreadsheet content to external unauthorized servers.\n\n'
            '2. Cloud Services: When you sign in with Google or Microsoft 365, authentication is handled securely via standard OAuth tokens '
            'strictly for cloud document synchronization.\n\n'
            '3. Storage & Permissions: The app requires storage access only to save, export (PDF/CSV), and read workbooks chosen by the user.\n\n'
            '4. Compliance: This app complies fully with Google Play Developer Program Policies.\n\n'
            'Contact: support@greensoft.dev\n'
            'Developer: Sachinthaka Sandaruwan (Research and Development Engineer)',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showPlayStoreInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Google Play Store Compliance'),
        content: const SingleChildScrollView(
          child: Text(
            'Green Excel is configured to meet all modern Google Play Console requirements:\n\n'
            '• Application ID: com.greensoft.greenexcel\n'
            '• Target SDK: 34 (Android 14) / Min SDK: 21 (Android 5.0+)\n'
            '• Format: Release APK & Android App Bundle (AAB)\n'
            '• Icons: High-resolution 512x512 Store Icon & full mipmap density icons (mdpi to xxxhdpi)\n'
            '• Architectures: Universal ARM64, ARMv7, x86_64\n'
            '• Developer: Sachinthaka Sandaruwan\n'
            '• Category: Productivity / Business Tools',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}
