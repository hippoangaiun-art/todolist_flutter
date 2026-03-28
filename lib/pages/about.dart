import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:todolist/core/const.dart';
import 'package:todolist/widgets/gradient_background.dart';
import 'package:todolist/widgets/surface_style.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _softSurface(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) {
      return scheme.surfaceContainerHigh;
    }
    return Colors.white.withValues(alpha: 0.88);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        backgroundColor: Colors.transparent,
      ),
      body: GradientBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _softSurface(context),
                    borderRadius: BorderRadius.circular(24),
                    border: SurfaceStyle.cardBorder(context),
                    boxShadow: SurfaceStyle.cardShadow(context),
                  ),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/icon/splash.svg',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'BUPT ToDo List',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '课表与待办一体化管理',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: SurfaceStyle.cardBorder(context),
                    boxShadow: SurfaceStyle.cardShadow(context),
                  ),
                  child: Material(
                    color: _softSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('GitHub 项目主页'),
                      subtitle: Text(Const.githubUrl),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _launchURL(Const.githubUrl),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
