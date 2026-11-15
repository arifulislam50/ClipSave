import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../ads/ads_service.dart';
import '../../core/ad_config.dart';
import '../../core/theme/app_theme.dart';

/// One large anchored adaptive banner, shown above the bottom navigation bar
/// on the History and Folders tabs only.
///
/// Loads only after consent allows ads. The request is a plain `AdRequest()`:
/// no keywords, content URLs or anything derived from clips.
class AdaptiveBanner extends StatefulWidget {
  const AdaptiveBanner({super.key});

  @override
  State<AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends State<AdaptiveBanner> {
  final AdsService _ads = AdsService.instance;
  BannerAd? _ad;
  int? _width;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ads.adsReady.addListener(_onAdsReadyChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width != _width) {
      _width = width;
      _load();
    }
  }

  void _onAdsReadyChanged() {
    if (_ads.adsReady.value) {
      if (_ad == null) _load();
    } else {
      // Consent withdrawn: remove the ad immediately.
      final old = _ad;
      if (mounted) setState(() => _ad = null);
      old?.dispose();
    }
  }

  Future<void> _load() async {
    final width = _width;
    if (width == null || _loading || !_ads.adsReady.value) return;
    _loading = true;
    try {
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (!mounted || size == null) return;
      await BannerAd(
        adUnitId: AdConfig.bannerAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            final old = _ad;
            setState(() => _ad = ad as BannerAd);
            old?.dispose();
          },
          onAdFailedToLoad: (ad, error) => ad.dispose(),
        ),
      ).load();
    } catch (_) {
      // No ad is fine; the layout simply has no banner.
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _ads.adsReady.removeListener(_onAdsReadyChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    final colors = CopyBoxColors.of(context);
    return Semantics(
      container: true,
      label: 'Advertisement',
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.card,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
