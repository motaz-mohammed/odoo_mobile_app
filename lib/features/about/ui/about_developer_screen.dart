import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odoo_mobile_app/core/widgets/shimmer_skeleton.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  static const String _developerName = "Motaz Osman";
  static const String _roleTitle = "Flutter Mobile & Odoo ERP Developer";
  static const String _qatarPhoneDisplay = "(+974) 5595 8014";
  static const String _qatarPhoneRaw = "+97455958014";
  static const String _qatarWhatsApp = "97455958014";

  static const String _ksaPhoneDisplay = "(+966) 51 132 8301";
  static const String _ksaPhoneRaw = "+966511328301";
  static const String _ksaWhatsApp = "966511328301";

  static const String _email = "motazme@gmail.com";
  static const String _linkedInUrl = "https://www.linkedin.com/in/motaz-mohammed-ali/";
  static const String _githubUrl = "https://github.com/motaz-mohammed";

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Could not open ${uri.toString()}")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error opening link: $e")));
      }
    }
  }

  void _copyToClipboard(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$label copied to clipboard"), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About & Developer Contact"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Profile Header Card
          SoftShadowCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: const Text(
                    "MO",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  _developerName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  _roleTitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Odoo 17 Mobile ERP Client • Sales, Purchase, Warehouse & Offline SQLite Sync",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Direct Phone & WhatsApp (Qatar & KSA)
          SoftShadowCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    "DIRECT PHONE & WHATSAPP",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _buildPhoneTile(
                  context: context,
                  location: "Doha, Qatar",
                  displayPhone: _qatarPhoneDisplay,
                  rawPhone: _qatarPhoneRaw,
                  whatsAppNumber: _qatarWhatsApp,
                ),
                const Divider(height: 1),
                _buildPhoneTile(
                  context: context,
                  location: "Riyadh, Saudi Arabia",
                  displayPhone: _ksaPhoneDisplay,
                  rawPhone: _ksaPhoneRaw,
                  whatsAppNumber: _ksaWhatsApp,
                ),
              ],
            ),
          ),

          // Email & Online Profiles
          SoftShadowCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    "EMAIL & PROFILES",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEDE7F6),
                    child: Icon(Icons.email_outlined, color: Colors.deepPurple),
                  ),
                  title: const Text("Email", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(_email),
                  trailing: IconButton(
                    tooltip: "Copy Email",
                    icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                    onPressed: () => _copyToClipboard(context, "Email", _email),
                  ),
                  onTap: () => _launchUri(
                    context,
                    Uri(
                      scheme: 'mailto',
                      path: _email,
                      queryParameters: {'subject': 'Odoo Mobile App Inquiry'},
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.work_outline, color: Color(0xFF0A66C2)),
                  ),
                  title: const Text("LinkedIn", style: TextStyle(fontWeight: FontWeight.w600)),
                  // subtitle: const Text("://linkedin.com"),
                  subtitle: const Text(_linkedInUrl),
                  trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
                  onTap: () => _launchUri(context, Uri.parse(_linkedInUrl)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3E5F5),
                    child: Icon(Icons.code, color: Colors.black87),
                  ),
                  title: const Text("GitHub", style: TextStyle(fontWeight: FontWeight.w600)),
                  // subtitle: const Text("://github.com"),
                  subtitle: const Text(_githubUrl),
                  trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
                  onTap: () => _launchUri(context, Uri.parse(_githubUrl)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Center(
            child: Text(
              "Odoo Mobile App • v1.0.0",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneTile({
    required BuildContext context,
    required String location,
    required String displayPhone,
    required String rawPhone,
    required String whatsAppNumber,
  }) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE8F5E9),
        child: Icon(Icons.phone_in_talk, color: Colors.green),
      ),
      title: Text(location, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(displayPhone),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: "Call $location",
            icon: const Icon(Icons.call, color: Colors.deepPurple),
            onPressed: () => _launchUri(context, Uri(scheme: 'tel', path: rawPhone)),
          ),
          IconButton(
            tooltip: "WhatsApp $location",
            icon: const Icon(Icons.chat, color: Colors.green),
            onPressed: () => _launchUri(context, Uri.parse("https://wa.me")),
          ),
        ],
      ),
      onLongPress: () => _copyToClipboard(context, "$location number", displayPhone),
    );
  }
}
