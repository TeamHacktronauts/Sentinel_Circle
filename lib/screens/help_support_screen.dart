import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'How can we help you?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Find answers to common questions and get support',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Quick Help Section
              _buildSection(
                context,
                title: 'Quick Help',
                icon: Icons.quickreply,
                children: [
                  _buildHelpItem(
                    context,
                    title: 'Getting Started',
                    subtitle: 'Learn how to use Sentinel Circle',
                    icon: Icons.play_arrow,
                    onTap: () => _showGettingStartedDialog(context),
                  ),
                  _buildHelpItem(
                    context,
                    title: 'Emergency Features',
                    subtitle: 'How to use safety and reporting features',
                    icon: Icons.emergency,
                    onTap: () => _showEmergencyFeaturesDialog(context),
                  ),
                  _buildHelpItem(
                    context,
                    title: 'Managing Trusted Contacts',
                    subtitle: 'Add and manage your trusted parents',
                    icon: Icons.people_outline,
                    onTap: () => _showTrustedContactsDialog(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Contact Support Section
              _buildSection(
                context,
                title: 'Contact Support',
                icon: Icons.support_agent,
                children: [
                  _buildHelpItem(
                    context,
                    title: 'Email Support',
                    subtitle: 'support@sentinelcircle.com',
                    icon: Icons.email_outlined,
                    onTap: () => _launchURL('mailto:support@sentinelcircle.com'),
                  ),
                  _buildHelpItem(
                    context,
                    title: 'Phone Support',
                    subtitle: '1-800-SENTINEL',
                    icon: Icons.phone_outlined,
                    onTap: () => _launchURL('tel:18007368435'),
                  ),
                  _buildHelpItem(
                    context,
                    title: 'Live Chat',
                    subtitle: 'Chat with our support team',
                    icon: Icons.chat_outlined,
                    onTap: () => _showLiveChatDialog(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Resources Section
              _buildSection(
                context,
                title: 'Resources',
                icon: Icons.library_books,
                children: [
                  _buildHelpItem(
                    context,
                    title: 'User Guide',
                    subtitle: 'Complete user documentation',
                    icon: Icons.description_outlined,
                    onTap: () => _launchURL('https://sentinelcircle.com/guide'),
                  ),
                  _buildHelpItem(
                    context,
                    title: 'Video Tutorials',
                    subtitle: 'Watch step-by-step tutorials',
                    icon: Icons.video_library_outlined,
                    onTap: () => _launchURL('https://sentinelcircle.com/tutorials'),
                  ),
                  _buildHelpItem(
                    context,
                    title: 'FAQ',
                    subtitle: 'Frequently asked questions',
                    icon: Icons.help_outline,
                    onTap: () => _showFAQDialog(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Emergency Resources Section
              _buildSection(
                context,
                title: 'Emergency Resources',
                icon: Icons.emergency,
                children: [
                  _buildHelpItem(
                    context,
                    title: 'Emergency Services',
                    subtitle: 'Call 911 for immediate emergencies',
                    icon: Icons.local_hospital,
                    onTap: () => _launchURL('tel:911'),
                    isEmergency: true,
                  ),
                  _buildHelpItem(
                    context,
                    title: 'Crisis Hotline',
                    subtitle: '24/7 crisis support line',
                    icon: Icons.psychology,
                    onTap: () => _launchURL('tel:988'),
                    isEmergency: true,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // App Info Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Sentinel Circle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version: 1.0.0',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2026 Sentinel Circle. All rights reserved.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _launchURL('https://sentinelcircle.com/privacy'),
                      child: const Text('Privacy Policy'),
                    ),
                    TextButton(
                      onPressed: () => _launchURL('https://sentinelcircle.com/terms'),
                      child: const Text('Terms of Service'),
                    ),
                  ],
                ),
              ),
              
              // Add extra bottom padding to avoid overlap with navigation buttons
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildHelpItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isEmergency = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: isEmergency ? Colors.red.shade50 : null,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEmergency 
                  ? Colors.red.shade100 
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isEmergency 
                  ? Colors.red.shade700 
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isEmergency ? Colors.red.shade700 : null,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isEmergency 
                ? Colors.red.shade700 
                : Theme.of(context).colorScheme.primary,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showGettingStartedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Getting Started'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Welcome to Sentinel Circle!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Set up your trusted parents contacts'),
              Text('2. Learn to use the emergency button'),
              Text('3. Explore the reporting features'),
              Text('4. Chat with Syndy for assistance'),
              SizedBox(height: 12),
              Text(
                'Sentinel Circle helps keep you safe by connecting you with trusted contacts and emergency services when you need help.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyFeaturesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Features'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Safety Button:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Press the "I Feel Unsafe" button for immediate help.'),
              SizedBox(height: 8),
              Text(
                'Report Safety Concern:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Report any safety concerns through the app.'),
              SizedBox(height: 8),
              Text(
                'Trusted Contacts:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Your trusted parents will be notified in emergencies.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showTrustedContactsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Managing Trusted Contacts'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to add trusted parents:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Go to Menu → Trusted Parents'),
              Text('2. Enter parent\'s name and email'),
              Text('3. Tap "Add" to save the contact'),
              SizedBox(height: 12),
              Text(
                'Important Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• You can add up to 5 trusted parents'),
              Text('• Make sure to use correct email addresses'),
              Text('• These contacts will be notified in emergencies'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLiveChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('Our live chat support is available:'),
            SizedBox(height: 8),
            Text('Monday - Friday: 9 AM - 6 PM'),
            Text('Saturday - Sunday: 10 AM - 4 PM'),
            SizedBox(height: 16),
            Text(
              'For urgent matters, please call our emergency hotline.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Q: How do I add trusted parents?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('A: Go to Menu → Trusted Parents and add their email addresses.'),
              SizedBox(height: 12),
              Text(
                'Q: What happens when I press the emergency button?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('A: Your trusted contacts and emergency services will be notified.'),
              SizedBox(height: 12),
              Text(
                'Q: Is my information secure?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('A: Yes, we use encryption to protect your data.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
