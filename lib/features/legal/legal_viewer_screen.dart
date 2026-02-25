import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/app_colors.dart';

class LegalViewerScreen extends StatefulWidget {
  final String title;
  final String htmlContent;

  const LegalViewerScreen({
    super.key,
    required this.title,
    required this.htmlContent,
  });

  @override
  State<LegalViewerScreen> createState() => _LegalViewerScreenState();
}

class _LegalViewerScreenState extends State<LegalViewerScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
      ))
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            ),
        ],
      ),
    );
  }
}

// ── HTML Content Constants ──────────────────────────────────────────────────

class LegalHtml {
  LegalHtml._();

  static const String privacy = '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Privacy Policy</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: #FFFFFF;
    color: #1a1a2e;
    line-height: 1.7;
  }
  .header {
    background: #0A1628;
    color: #FFFFFF;
    padding: 40px 20px 32px;
    text-align: center;
  }
  .header .anchor { font-size: 36px; margin-bottom: 8px; }
  .header h1 { font-size: 24px; font-weight: 700; letter-spacing: 3px; margin-bottom: 4px; }
  .header .subtitle { font-size: 13px; color: #7EC8C8; letter-spacing: 1px; }
  .header .effective { margin-top: 12px; font-size: 12px; color: rgba(255,255,255,0.6); }
  .content { padding: 32px 20px 48px; }
  h2 { font-size: 18px; font-weight: 600; color: #0A1628; margin: 28px 0 10px; padding-bottom: 6px; border-bottom: 2px solid #7EC8C8; }
  h3 { font-size: 15px; font-weight: 600; color: #0A1628; margin: 20px 0 6px; }
  p { margin: 6px 0; font-size: 14px; color: #333; }
  ul { margin: 6px 0 6px 20px; }
  li { margin: 3px 0; font-size: 14px; color: #333; }
  a { color: #7EC8C8; }
  .contact-box { background: #f0f7f7; border-left: 4px solid #7EC8C8; padding: 14px 16px; margin: 20px 0; border-radius: 0 8px 8px 0; }
  .contact-box p { margin: 3px 0; }
  .footer { text-align: center; padding: 24px 20px; color: #999; font-size: 12px; border-top: 1px solid #eee; }
</style>
</head>
<body>

<div class="header">
  <div class="anchor">&#9875;</div>
  <h1>ANCHORAGE</h1>
  <div class="subtitle">Privacy Policy</div>
  <div class="effective">Effective: 25 February 2026</div>
</div>

<div class="content">

<p>ANCHORAGE is published by <strong>Temporal Psychology</strong>. We ("we", "us", "our") are committed to protecting your privacy. This Privacy Policy explains what data we collect, how we use it, and your rights regarding that data.</p>

<h2>1. Data We Collect</h2>

<h3>1.1 Data Stored Locally on Your Device</h3>
<p>The following data is stored exclusively on your device using local storage and is <strong>never</strong> transmitted to our servers:</p>
<ul>
  <li><strong>Urge logs</strong> &mdash; trigger categories, timestamps, and optional notes</li>
  <li><strong>Relapse logs</strong> &mdash; guided reflection responses (what happened, what triggered it, what you learned, what to do next time)</li>
  <li><strong>Reflection entries</strong> &mdash; mood ratings and free-text journal entries</li>
  <li><strong>Personal values</strong> &mdash; your selected core values (up to 3)</li>
  <li><strong>First name</strong> &mdash; used only for personalising the app locally</li>
  <li><strong>App preferences</strong> &mdash; guarded app selections and settings</li>
</ul>
<p>This data remains on your device and is deleted when you clear app data or uninstall ANCHORAGE.</p>

<h3>1.2 Data Synced via Firebase</h3>
<p>We use Firebase Authentication (anonymous sign-in) and Cloud Firestore to sync minimal data:</p>
<ul>
  <li><strong>Anonymous user ID (UUID)</strong> &mdash; a randomly generated identifier with no connection to your real identity</li>
  <li><strong>Streak data</strong> &mdash; your current streak count and start date</li>
  <li><strong>Accountability partner details</strong> &mdash; if you add a partner, their name and email are stored in Firestore to enable weekly progress reports</li>
</ul>
<p>We do not collect your real name, phone number, physical address, or any other personally identifiable information through Firebase.</p>

<h3>1.3 Heartbeat Data</h3>
<p>ANCHORAGE sends a periodic heartbeat signal to Firebase approximately every 4 hours. This heartbeat contains:</p>
<ul>
  <li><strong>Anonymous user ID (UUID)</strong></li>
  <li><strong>Timestamp</strong></li>
  <li><strong>VPN active status</strong> (boolean &mdash; whether the content filter is running)</li>
  <li><strong>Guard service active status</strong> (boolean &mdash; whether the app guard is running)</li>
</ul>
<p>The heartbeat does <strong>not</strong> contain browsing data, blocked domains, app usage details, or any personal content. It is used solely to detect if ANCHORAGE has been uninstalled or become inactive, so your accountability partner can be notified to check in with you.</p>

<h3>1.4 Third-Party Services</h3>
<ul>
  <li><strong>SendGrid</strong> &mdash; sends accountability emails (weekly reports, partner invitations, and protection alerts). Processes the recipient email and report content (streak data only, never urge/relapse details).</li>
  <li><strong>RevenueCat</strong> &mdash; processes subscriptions through Google Play. We receive subscription status but never payment card details.</li>
</ul>

<h2>2. How We Use Your Data</h2>
<ul>
  <li>Provide and personalise the ANCHORAGE app experience</li>
  <li>Track and display your streak progress</li>
  <li>Send accountability reports to your chosen partner</li>
  <li>Send accountability alerts when protection is interrupted (warm, non-shaming check-in prompts &mdash; never details about what was accessed)</li>
  <li>Process subscription payments</li>
  <li>Improve app stability (anonymous crash data only)</li>
</ul>

<h2>3. Data We Do NOT Collect</h2>
<ul>
  <li>We do <strong>not</strong> collect browsing history or domains you visit</li>
  <li>We do <strong>not</strong> collect content of blocked pages</li>
  <li>We do <strong>not</strong> log which domains are blocked by the VPN filter</li>
  <li>We do <strong>not</strong> use advertising SDKs or fingerprinting</li>
  <li>We do <strong>not</strong> sell, rent, or share your data with third parties for marketing</li>
</ul>

<h2>4. VPN and Content Filtering</h2>
<p>ANCHORAGE uses a local VPN service to filter DNS requests entirely on your device. No browsing data, DNS queries, or network traffic is transmitted to our servers. Your actual internet traffic is not intercepted or proxied. The VPN only routes DNS queries through a local resolver &mdash; all other traffic bypasses the VPN entirely.</p>

<h2>5. Data Retention</h2>
<ul>
  <li><strong>Local data</strong> &mdash; retained until you clear app data, uninstall, or sign out</li>
  <li><strong>Firebase data</strong> &mdash; retained while your anonymous account exists; deleted within 30 days upon request</li>
  <li><strong>Heartbeat data</strong> &mdash; only the most recent heartbeat is stored; older heartbeats are overwritten</li>
  <li><strong>SendGrid</strong> &mdash; email delivery logs retained per SendGrid policy (typically 30 days)</li>
  <li><strong>RevenueCat</strong> &mdash; subscription records retained per RevenueCat policy and Google Play requirements</li>
</ul>

<h2>6. Your Rights (GDPR &amp; Australian Privacy Act)</h2>
<p>Under both the EU General Data Protection Regulation (GDPR) and the Australian Privacy Act 1988, you have the right to:</p>
<ul>
  <li><strong>Access</strong> &mdash; request a copy of all data we hold about you</li>
  <li><strong>Deletion</strong> &mdash; request deletion of all your data</li>
  <li><strong>Portability</strong> &mdash; receive your data in a structured, machine-readable format</li>
  <li><strong>Rectification</strong> &mdash; correct any inaccurate data</li>
  <li><strong>Withdraw consent</strong> &mdash; stop data processing at any time</li>
</ul>
<p>To exercise any of these rights, email us at the address below. We will respond within 30 days.</p>

<h2>7. Data Security</h2>
<ul>
  <li>Firebase Security Rules restrict data access to authenticated users</li>
  <li>HTTPS encryption for all network communication</li>
  <li>Minimal data collection &mdash; only what is strictly necessary</li>
  <li>No server-side storage of sensitive personal data (urge logs, relapse logs, reflections)</li>
</ul>

<h2>8. Children's Privacy</h2>
<p>ANCHORAGE is intended for users aged 18 and over. We do not knowingly collect data from anyone under 18.</p>

<h2>9. Changes to This Policy</h2>
<p>We may update this Privacy Policy from time to time. Material changes will be communicated through an in-app notice.</p>

<h2>10. Contact Us</h2>
<div class="contact-box">
  <p><strong>Privacy requests and questions:</strong></p>
  <p>Email: <a href="mailto:hello@anchorage.com.au">hello@anchorage.com.au</a></p>
  <p>Published by Temporal Psychology</p>
</div>

</div>

<div class="footer">&copy; 2026 Temporal Psychology. All rights reserved.</div>

</body>
</html>
''';

  static const String terms = '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Terms of Service</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: #FFFFFF;
    color: #1a1a2e;
    line-height: 1.7;
  }
  .header {
    background: #0A1628;
    color: #FFFFFF;
    padding: 40px 20px 32px;
    text-align: center;
  }
  .header .anchor { font-size: 36px; margin-bottom: 8px; }
  .header h1 { font-size: 24px; font-weight: 700; letter-spacing: 3px; margin-bottom: 4px; }
  .header .subtitle { font-size: 13px; color: #7EC8C8; letter-spacing: 1px; }
  .header .effective { margin-top: 12px; font-size: 12px; color: rgba(255,255,255,0.6); }
  .content { padding: 32px 20px 48px; }
  h2 { font-size: 18px; font-weight: 600; color: #0A1628; margin: 28px 0 10px; padding-bottom: 6px; border-bottom: 2px solid #7EC8C8; }
  h3 { font-size: 15px; font-weight: 600; color: #0A1628; margin: 20px 0 6px; }
  p { margin: 6px 0; font-size: 14px; color: #333; }
  ul { margin: 6px 0 6px 20px; }
  li { margin: 3px 0; font-size: 14px; color: #333; }
  a { color: #7EC8C8; }
  .warning-box { background: #fff8f0; border-left: 4px solid #D4AF37; padding: 14px 16px; margin: 20px 0; border-radius: 0 8px 8px 0; }
  .warning-box p { margin: 3px 0; }
  .contact-box { background: #f0f7f7; border-left: 4px solid #7EC8C8; padding: 14px 16px; margin: 20px 0; border-radius: 0 8px 8px 0; }
  .contact-box p { margin: 3px 0; }
  .footer { text-align: center; padding: 24px 20px; color: #999; font-size: 12px; border-top: 1px solid #eee; }
</style>
</head>
<body>

<div class="header">
  <div class="anchor">&#9875;</div>
  <h1>ANCHORAGE</h1>
  <div class="subtitle">Terms of Service</div>
  <div class="effective">Effective: 25 February 2026</div>
</div>

<div class="content">

<p>ANCHORAGE is published by <strong>Temporal Psychology</strong>. By downloading, installing, or using ANCHORAGE ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree, do not use the App.</p>

<h2>1. Age Requirement</h2>
<p>You must be at least <strong>18 years of age</strong> to use ANCHORAGE. By using the App, you confirm that you are 18 or older.</p>

<h2>2. Not a Substitute for Professional Treatment</h2>
<div class="warning-box">
  <p><strong>Important:</strong> ANCHORAGE is a self-help tool designed to support your personal goals. It is <strong>not</strong> a substitute for professional mental health treatment, therapy, counselling, or medical advice.</p>
</div>
<p>If you are experiencing a mental health crisis, please contact a qualified professional or call a crisis helpline immediately. We do not make any claims that ANCHORAGE will cure, treat, or prevent any condition.</p>

<h2>3. Content Filtering Disclaimer</h2>
<p>ANCHORAGE uses DNS-based filtering and app interception to help block access to explicit content. However:</p>
<ul>
  <li>We <strong>do not guarantee</strong> that all explicit content will be blocked</li>
  <li>New domains may not be covered immediately</li>
  <li>The blocklist is sourced from third-party community-maintained lists</li>
  <li>VPN filtering can be disabled by the user at any time</li>
  <li>App interception may behave differently across devices and Android versions</li>
</ul>
<p>ANCHORAGE is an aid, not a guarantee. No content filtering solution is 100% effective.</p>

<h2>4. User Responsibility</h2>
<p>You are solely responsible for:</p>
<ul>
  <li>Your own recovery journey and personal choices</li>
  <li>Maintaining the permissions ANCHORAGE needs to function</li>
  <li>The accuracy of information you provide (e.g. accountability partner details)</li>
  <li>Ensuring your accountability partner consents to receive reports</li>
  <li>Keeping your device secure and the app updated</li>
</ul>

<h2>5. Accountability Partner Feature</h2>
<ul>
  <li>You must obtain your partner's consent before adding their email</li>
  <li>Reports contain only general progress data (streak count, milestones) &mdash; never urge logs, reflections, or browsing data</li>
  <li>You can remove your accountability partner at any time</li>
  <li>We are not responsible for consequences arising from the accountability relationship</li>
</ul>

<h2>6. Prohibited Use: Monitoring Others Without Consent</h2>
<div class="warning-box">
  <p>You must <strong>not</strong> use ANCHORAGE to monitor, track, or restrict another person's device usage without their full knowledge and informed consent. ANCHORAGE is designed as a <strong>voluntary self-help tool</strong>. Using it to covertly monitor a partner, family member, or any other person is a violation of these Terms and may violate applicable laws.</p>
</div>

<h2>7. Subscriptions and Payments</h2>

<h3>7.1 Free Tier</h3>
<p>ANCHORAGE offers a free tier with up to 3 guarded apps, usable indefinitely.</p>

<h3>7.2 ANCHORAGE+ (Premium)</h3>
<p>Available as monthly and annual subscriptions, processed through Google Play and managed by RevenueCat.</p>

<h3>7.3 Billing</h3>
<ul>
  <li>Payment is charged to your Google Play account at purchase</li>
  <li>Subscriptions auto-renew unless cancelled at least 24 hours before the billing period ends</li>
  <li>Manage or cancel via the Google Play Store</li>
</ul>

<h3>7.4 Refunds</h3>
<p>Refund requests are handled by Google Play per their refund policy.</p>

<h2>8. Intellectual Property</h2>
<p>All content, design, code, and branding of ANCHORAGE are the property of Temporal Psychology and protected by applicable intellectual property laws.</p>

<h2>9. Limitation of Liability</h2>
<p>To the maximum extent permitted by law:</p>
<ul>
  <li>ANCHORAGE is provided <strong>"as is"</strong> and <strong>"as available"</strong> without warranties of any kind</li>
  <li>We do not warrant that the App will be uninterrupted or error-free</li>
  <li>We shall not be liable for any indirect, incidental, special, consequential, or punitive damages</li>
  <li>Our total liability shall not exceed the amount paid in the 12 months preceding the claim, or AUD \$50, whichever is greater</li>
</ul>

<h2>10. Indemnification</h2>
<p>You agree to indemnify and hold harmless Temporal Psychology and ANCHORAGE from any claims, damages, losses, or expenses arising from your use of the App or violation of these Terms.</p>

<h2>11. Termination</h2>
<p>We may suspend or terminate your access at any time. You may stop using the App by uninstalling it.</p>

<h2>12. Governing Law</h2>
<p>These Terms are governed by the laws of Victoria, Australia. Disputes are subject to the exclusive jurisdiction of Victorian courts.</p>

<h2>13. Changes to These Terms</h2>
<p>We may update these Terms from time to time. Continued use constitutes acceptance. Material changes will be communicated via in-app notice.</p>

<h2>14. Contact Us</h2>
<div class="contact-box">
  <p><strong>Questions about these Terms:</strong></p>
  <p>Email: <a href="mailto:hello@anchorage.com.au">hello@anchorage.com.au</a></p>
  <p>Published by Temporal Psychology</p>
</div>

</div>

<div class="footer">&copy; 2026 Temporal Psychology. All rights reserved.</div>

</body>
</html>
''';
}
