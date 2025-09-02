import 'package:flutter/material.dart';
import '../services/image_service.dart';

class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showShimmer;

  const OptimizedImage({
    super.key,
    this.imageUrl,
    this.fallbackAsset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.showShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final imageService = ImageService();

    // If no image URL provided, show fallback or error
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallbackWidget();
    }

    return imageService.buildCachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: placeholder ?? (showShimmer ? _buildShimmerPlaceholder() : _buildDefaultPlaceholder()),
      errorWidget: errorWidget ?? _buildFallbackWidget(),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return ShimmerPlaceholder(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F5ADC)),
        ),
      ),
    );
  }

  Widget _buildFallbackWidget() {
    Widget fallbackChild;
    
    if (fallbackAsset != null) {
      fallbackChild = Image.asset(
        fallbackAsset!,
        width: width,
        height: height,
        fit: fit,
      );
    } else {
      fallbackChild = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius,
        ),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
            size: 32,
          ),
        ),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: fallbackChild,
      );
    }

    return fallbackChild;
  }
}

class OptimizedCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? child;
  final Color? backgroundColor;
  final bool showShimmer;

  const OptimizedCircleAvatar({
    super.key,
    this.imageUrl,
    required this.radius,
    this.child,
    this.backgroundColor,
    this.showShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final imageService = ImageService();

    return imageService.buildCachedCircleAvatar(
      imageUrl: imageUrl,
      radius: radius,
      child: child,
      backgroundColor: backgroundColor,
    );
  }
}

class ShimmerPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
              colors: [
                Colors.grey[200]!,
                Colors.grey[100]!,
                Colors.grey[200]!,
              ],
            ),
          ),
        );
      },
    );
  }
}

class LaundryShopImageCard extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final BorderRadius? borderRadius;
  final Widget? overlay;

  const LaundryShopImageCard({
    super.key,
    this.imageUrl,
    this.height = 100,
    this.borderRadius,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        OptimizedImage(
          imageUrl: imageUrl,
          fallbackAsset: 'lib/assets/laundry_placeholder.png',
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          borderRadius: borderRadius,
          showShimmer: true,
        ),
        if (overlay != null) overlay!,
      ],
    );
  }
}

class ProfileImageWidget extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const ProfileImageWidget({
    Key? key,
    required this.imageUrl,
    required this.radius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: OptimizedImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: Icon(
            Icons.person,
            size: radius,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}