import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google User Messaging Platform (UMP) consent + Mobile Ads initialisation.
///
/// Order, as Google requires: request consent info -> show the consent form
/// if required -> only then initialise the Mobile Ads SDK, and only if
/// `canRequestAds()` is true.
///
/// Privacy rule: this file and `ui/widgets/ad_banner.dart` are the only code
/// that talks to the ads SDK. Neither imports clip models, the clipboard
/// bridge or the clips controller, so clip text can never reach an ad request
/// (enforced by tool/check_structure.py).
class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  /// How long the splash waits for the consent *info* request before moving
  /// on. A consent form that is already showing stays open.
  static const Duration consentTimeout = Duration(seconds: 15);

  /// True once consent allows ads AND the Mobile Ads SDK has initialised.
  final ValueNotifier<bool> adsReady = ValueNotifier<bool>(false);

  /// True when the user must be able to re-open the consent form
  /// (shows "Privacy and ad choices" in Settings).
  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier<bool>(false);

  Future<void>? _initialization;
  bool _sdkStarted = false;

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Safe to call more than once; runs the flow a single time.
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (!_supported) return;
    try {
      await _gatherConsent().timeout(consentTimeout, onTimeout: () {});
    } catch (_) {
      // Fall through: we only show ads if canRequestAds() says so below.
    }
    await _refreshStatus();
  }

  Future<void> _gatherConsent() {
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => unawaited(ConsentForm.loadAndShowConsentFormIfRequired((FormError? _) => finish())),
      (FormError _) => finish(),
    );
    return done.future;
  }

  /// Re-reads consent state; starts the SDK if newly allowed, hides ads if
  /// consent was withdrawn.
  Future<void> _refreshStatus() async {
    var canRequest = false;
    try {
      canRequest = await ConsentInformation.instance.canRequestAds();
      privacyOptionsRequired.value =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
              PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      canRequest = false;
    }
    if (!canRequest) {
      adsReady.value = false;
      return;
    }
    if (!_sdkStarted) {
      try {
        await MobileAds.instance.initialize();
        _sdkStarted = true;
      } catch (_) {
        return;
      }
    }
    adsReady.value = true;
  }

  /// Re-opens the consent form ("Privacy and ad choices" in Settings).
  Future<void> showPrivacyOptions() async {
    if (!_supported) return;
    final done = Completer<void>();
    try {
      await ConsentForm.showPrivacyOptionsForm((FormError? _) {
        if (!done.isCompleted) done.complete();
      });
    } catch (_) {
      if (!done.isCompleted) done.complete();
    }
    await done.future;
    await _refreshStatus();
  }
}
