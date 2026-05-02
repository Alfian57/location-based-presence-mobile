part of '../../../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.apiBase,
    required this.onAuthenticated,
  });

  final String apiBase;
  final Future<void> Function(String token, Map<String, dynamic> user)
  onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _activationMode = false;
  bool _showPassword = false;
  bool _loading = false;
  String? _error;

  AuthRepository get _repository => AuthRepository(apiBase: widget.apiBase);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Email dan kata sandi wajib diisi.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _repository.authenticate(
        activationMode: _activationMode,
        email: _email.text.trim(),
        password: _password.text,
      );

      await widget.onAuthenticated(
        response['token'] as String,
        Map<String, dynamic>.from(response['pengguna'] as Map),
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on PlatformException catch (error) {
      setState(() => _error = error.message ?? 'Perangkat tidak bisa dibaca.');
    } catch (error) {
      setState(() => _error = 'Masuk gagal: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Isi email terlebih dahulu.');
      return;
    }

    setState(() => _error = null);
    try {
      final message = await _repository.resetPassword(_email.text.trim());
      if (!mounted) return;
      tampilkanNotifikasi(context, message);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = layarXxs(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: paddingHalaman(context),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (compact ? 32 : 48),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _LoginHeader(),
                        SizedBox(height: compact ? 18 : 24),
                        Panel(
                          padding: EdgeInsets.all(compact ? 14 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SegmentedButton<bool>(
                                showSelectedIcon: false,
                                style: ButtonStyle(
                                  visualDensity: compact
                                      ? VisualDensity.compact
                                      : VisualDensity.standard,
                                  padding: WidgetStatePropertyAll(
                                    EdgeInsets.symmetric(
                                      horizontal: compact ? 8 : 12,
                                    ),
                                  ),
                                ),
                                segments: const [
                                  ButtonSegment<bool>(
                                    value: false,
                                    label: Text('Masuk'),
                                  ),
                                  ButtonSegment<bool>(
                                    value: true,
                                    label: Text('Aktivasi'),
                                  ),
                                ],
                                selected: {_activationMode},
                                onSelectionChanged: _loading
                                    ? null
                                    : (values) => setState(
                                        () => _activationMode = values.first,
                                      ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                _activationMode
                                    ? 'Aktivasi akun'
                                    : 'Masuk akun',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _activationMode
                                    ? 'Gunakan email dan kata sandi dari admin sekolah.'
                                    : 'Gunakan akun guru yang sudah terdaftar.',
                                style: const TextStyle(
                                  color: _warnaTeksRedup,
                                  height: 1.4,
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                ErrorBox(message: _error!),
                              ],
                              const SizedBox(height: 16),
                              TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _password,
                                obscureText: !_showPassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  if (!_loading) _submit();
                                },
                                decoration: InputDecoration(
                                  labelText: 'Kata Sandi',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _showPassword
                                        ? 'Sembunyikan kata sandi'
                                        : 'Tampilkan kata sandi',
                                    onPressed: () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _activationMode
                                            ? 'Aktivasi & Masuk'
                                            : 'Masuk',
                                      ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading ? null : _resetPassword,
                                  child: const Text('Reset Kata Sandi'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    final compact = layarXxs(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: compact ? 68 : 78,
          height: compact ? 68 : 78,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radiusKartu),
            border: Border.all(color: _warnaGaris),
          ),
          clipBehavior: Clip.antiAlias,
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Image(
              image: AssetImage(_assetLogoAplikasi),
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: compact ? 12 : 14),
        Text(
          'Presensi Guru',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: _warnaTeksUtama,
            fontSize: compact ? 22 : null,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: const Text(
            'Masuk dengan akun guru yang sudah terdaftar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _warnaTeksRedup, height: 1.35),
          ),
        ),
      ],
    );
  }
}
