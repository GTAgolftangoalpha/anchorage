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
  <div class="effective">Effective: 19 March 2026</div>
</div>

<div class="content">

<p>ANCHORAGE is published by <strong>Golf Tango Alpha Pty Ltd</strong> (ABN pending). This policy explains what data we collect, how we use it, and your rights.</p>

<h2>1. What We Collect</h2>
<p>We collect the following:</p>
<ul>
  <li><strong>Email address</strong>, provided during onboarding</li>
  <li><strong>Usage data</strong>, including streak counts and anonymous identifiers used to run your account</li>
  <li><strong>Anonymised crash reports</strong>, to help us fix bugs and improve the app</li>
</ul>

<h2>2. What We Do Not Collect</h2>
<p>The following stays on your device and is never sent to our servers:</p>
<ul>
  <li>Browsing history and blocked domains</li>
  <li>Journal and reflection entries</li>
  <li>Urge log content and notes</li>
  <li>Lapse log content</li>
</ul>
<p>We do not use advertising trackers or fingerprinting. We do not sell or share your data with third parties for marketing.</p>

<h2>3. How We Use Your Data</h2>
<p>We use your data to:</p>
<ul>
  <li>Run your account and personalise your experience</li>
  <li>Improve the app and fix issues</li>
  <li>Send accountability reports to a partner you choose (if applicable)</li>
  <li>Process subscription payments through Google Play</li>
</ul>

<h2>4. Content Filtering</h2>
<p>ANCHORAGE uses a local VPN to filter content entirely on your device. No browsing data or DNS queries leave your device. Your internet traffic is not intercepted or proxied by us.</p>

<h2>5. Data Retention</h2>
<p>Local data stays on your device until you clear app data or uninstall ANCHORAGE. Server-side data is deleted within 30 days of a deletion request. You can delete all your data at any time from Settings.</p>

<h2>6. Your Rights</h2>
<p>Under the Australian Privacy Act 1988, you have the right to:</p>
<ul>
  <li><strong>Access</strong> your data by emailing us</li>
  <li><strong>Delete</strong> your data from within the app, or by emailing us</li>
</ul>
<p>We will respond to all requests within 30 days.</p>

<h2>7. Changes</h2>
<p>We may update this policy from time to time. Material changes will be communicated through an in-app notice.</p>

<h2>8. Contact</h2>
<div class="contact-box">
  <p>Email: <a href="mailto:hello@getanchorage.app">hello@getanchorage.app</a></p>
  <p>Published by Golf Tango Alpha Pty Ltd</p>
</div>

</div>

<div class="footer">Golf Tango Alpha Pty Ltd 2026. All rights reserved.</div>

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
  <div class="subtitle">Terms of Service</div>
  <div class="effective">Effective: 19 March 2026</div>
</div>

<div class="content">

<p>By using ANCHORAGE you agree to these terms. If you do not agree, do not use the app.</p>

<h2>1. Age</h2>
<p>By using ANCHORAGE you confirm you are aged 18 or over, or have obtained parental consent to use this app.</p>

<h2>2. What ANCHORAGE Is</h2>
<p>ANCHORAGE is a self-help tool. It is not a mental health service. We do not make any claims that ANCHORAGE will cure, treat, or prevent any condition. If you are in crisis, please visit <strong>findahelpline.com</strong>.</p>

<h2>3. No Guarantee of Outcomes</h2>
<p>ANCHORAGE uses content filtering and app interception to support your goals, but no filtering solution is 100% effective. We are not responsible for outcomes related to your use of the app. The app is provided "as is" without warranties of any kind.</p>

<h2>4. Acceptable Use</h2>
<p>ANCHORAGE is a voluntary self-help tool. You must not use it to monitor, track, or restrict another person's device without their knowledge and consent. Doing so is a violation of these terms and may violate applicable laws.</p>

<h2>5. Subscriptions</h2>
<p>ANCHORAGE offers a free tier and a premium subscription (ANCHORAGE+). Subscriptions are processed through Google Play, auto-renew unless cancelled, and can be managed via the Google Play Store.</p>

<h2>6. Governing Law</h2>
<p>These terms are governed by the laws of Victoria, Australia.</p>

<h2>7. Contact</h2>
<div class="contact-box">
  <p>Email: <a href="mailto:hello@getanchorage.app">hello@getanchorage.app</a></p>
  <p>Published by Golf Tango Alpha Pty Ltd</p>
</div>

</div>

<div class="footer">Golf Tango Alpha Pty Ltd 2026. All rights reserved.</div>

</body>
</html>
''';
}
