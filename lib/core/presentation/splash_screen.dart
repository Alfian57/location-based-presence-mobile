part of '../../main.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_radiusKartu),
                  boxShadow: [
                    BoxShadow(
                      color: _warnaPrimer.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Image(
                    image: AssetImage(_assetLogoAplikasi),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Presensi Guru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _warnaTeksUtama,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Menyiapkan sesi aplikasi',
                style: TextStyle(color: _warnaTeksRedup),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
