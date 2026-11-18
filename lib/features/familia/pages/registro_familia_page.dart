import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/pages/activar_cuenta_page.dart';
import '../../auth/pages/login_page.dart';
import '../models/solicitud_familia_model.dart';
import '../services/solicitud_familia_service.dart';
import '../widgets/formulario_familia.dart';
import 'codigo_familia_page.dart';

/// "Soy familiar de un jugador": el registro sin sesión en tres pasos (tus datos, tus hijos y las dos casillas). Al
/// enviar manda el código por email y sigue en [CodigoFamiliaPage]. NUNCA enseña nombres de jugadores ni confirma si
/// existen.
class RegistroFamiliaPage extends StatefulWidget {
  /// Solo para tests: sustituye al servicio real.
  final SolicitudFamiliaService servicio;

  const RegistroFamiliaPage({
    super.key,
    this.servicio = const SolicitudFamiliaService(),
  });

  @override
  State<RegistroFamiliaPage> createState() => _RegistroFamiliaPageState();
}

class _RegistroFamiliaPageState extends State<RegistroFamiliaPage> {
  static const int _pasos = 3;

  final _datosKey = GlobalKey<FormState>();
  final _hijosKey = GlobalKey<FormularioHijosState>();

  final _nombre = TextEditingController();
  final _apellidos = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();

  ParentescoFamilia? _parentesco;
  bool _representante = false;
  bool _privacidad = false;
  bool _casillasIntentadas = false;

  int _paso = 0;
  bool _cargando = false;
  String? _error;
  EstadoRegistroFamilia? _bloqueo;

  @override
  void dispose() {
    _nombre.dispose();
    _apellidos.dispose();
    _email.dispose();
    _telefono.dispose();
    super.dispose();
  }

  AppLocalizations get _t => AppLocalizations.of(context);

  String? _validarTelefono(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) return null;

    final soloPermitidos = RegExp(r'^[0-9+()\-. ]{6,20}$');

    return soloPermitidos.hasMatch(texto) ? null : _t.familyPhoneInvalid;
  }

  void _siguiente() {
    FocusScope.of(context).unfocus();

    setState(() => _error = null);

    if (_paso == 0) {
      if (!(_datosKey.currentState?.validate() ?? false)) return;
    } else if (_paso == 1) {
      if (!(_hijosKey.currentState?.validar() ?? false)) return;
    }

    setState(() => _paso++);
  }

  void _atras() {
    FocusScope.of(context).unfocus();

    setState(() {
      _error = null;
      _bloqueo = null;
      _paso--;
    });
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();

    setState(() => _casillasIntentadas = true);

    if (!_representante || !_privacidad) return;

    setState(() {
      _cargando = true;
      _error = null;
      _bloqueo = null;
    });

    try {
      final estado = await widget.servicio.registrar(
        SolicitudFamiliaNueva(
          nombre: _nombre.text,
          apellidos: _apellidos.text,
          email: _email.text,
          telefono: _telefono.text,
          parentesco: _parentesco!,
          hijos: _hijosKey.currentState!.hijos,
        ),
      );

      if (!mounted) return;

      if (estado == EstadoRegistroFamilia.cuentaExistente ||
          estado == EstadoRegistroFamilia.invitacionPendiente) {
        setState(() => _bloqueo = estado);
        return;
      }

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CodigoFamiliaPage(
            email: _email.text.trim().toLowerCase(),
            envioFallido: estado == EstadoRegistroFamilia.envioFallido,
            servicio: widget.servicio,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = mensajeErrorFamilia(_t, e));
    } catch (e) {
      if (mounted) setState(() => _error = mensajeErrorFamilia(_t, e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ultimo = _paso == _pasos - 1;

    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: t.familyRegisterTitle)),
      // El botón principal va fuera de la lista: con el teclado abierto el cuerpo se encoge y el botón sigue visible.
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _construirCabecera(t),
                        const SizedBox(height: 20),
                        // Los tres pasos viven siempre en el árbol (Offstage) para no perder lo escrito al ir y volver.
                        Offstage(offstage: _paso != 0, child: _paso0(t)),
                        Offstage(
                          offstage: _paso != 1,
                          child: FormularioHijos(key: _hijosKey),
                        ),
                        if (_paso == 2) _paso2(t),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          _caja(_error!, Theme.of(context).colorScheme.error),
                        ],
                        if (_bloqueo != null) ...[
                          const SizedBox(height: 16),
                          _construirBloqueo(t, _bloqueo!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Row(
                    children: [
                      if (_paso > 0) ...[
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            key: const ValueKey('familia-atras'),
                            onPressed: _cargando ? null : _atras,
                            child: Text(t.familyBack),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            key: const ValueKey('familia-principal'),
                            onPressed: _cargando
                                ? null
                                : (ultimo ? _enviar : _siguiente),
                            child: _cargando
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(ultimo ? t.familySend : t.familyNext),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCabecera(AppLocalizations t) {
    final titulos = [
      t.familyStepYou,
      t.familyStepChildren,
      t.familyStepConfirm,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_paso == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              t.familyRegisterIntro,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Text(
          t.familyStepOf(_paso + 1, _pasos),
          key: const ValueKey('familia-paso'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          titulos[_paso],
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: (_paso + 1) / _pasos),
      ],
    );
  }

  Widget _paso0(AppLocalizations t) {
    return Form(
      key: _datosKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const ValueKey('familia-nombre'),
            controller: _nombre,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: t.familyFirstName,
              prefixIcon: const Icon(Icons.person_outline),
              counterText: '',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? t.familyNameRequired : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('familia-apellidos'),
            controller: _apellidos,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: 150,
            decoration: InputDecoration(
              labelText: t.familyLastName,
              prefixIcon: const Icon(Icons.person_outline),
              counterText: '',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? t.familyLastNameRequired
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('familia-email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: t.storeEmailLabel,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return t.loginEmailRequired;

              final valor = v.trim();

              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(valor)
                  ? null
                  : t.loginEmailInvalid;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('familia-telefono'),
            controller: _telefono,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: t.familyPhoneOptional,
              prefixIcon: const Icon(Icons.phone_outlined),
              counterText: '',
            ),
            validator: _validarTelefono,
          ),
          const SizedBox(height: 14),
          SelectorParentesco(
            valor: _parentesco,
            onChanged: (p) => setState(() => _parentesco = p),
          ),
        ],
      ),
    );
  }

  Widget _paso2(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.familyConfirmIntro,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        CasillasFamilia(
          representante: _representante,
          privacidad: _privacidad,
          mostrarErrores: _casillasIntentadas,
          onRepresentante: (v) => setState(() => _representante = v),
          onPrivacidad: (v) => setState(() => _privacidad = v),
        ),
      ],
    );
  }

  Widget _caja(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        key: const ValueKey('familia-error'),
        textAlign: TextAlign.center,
        style: TextStyle(color: color),
      ),
    );
  }

  /// "Ya tienes cuenta" o "ya te invitó el club": el mensaje y un botón a la pantalla que corresponde.
  Widget _construirBloqueo(AppLocalizations t, EstadoRegistroFamilia estado) {
    final existe = estado == EstadoRegistroFamilia.cuentaExistente;
    final email = _email.text.trim().toLowerCase();

    return Column(
      key: ValueKey(
        existe ? 'familia-bloqueo-cuenta' : 'familia-bloqueo-invitacion',
      ),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _caja(
          existe ? t.familyAccountExists : t.familyInvitationPending,
          Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const ValueKey('familia-bloqueo-boton'),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => existe
                  ? LoginPage(emailInicial: email)
                  : ActivarCuentaPage(emailInicial: email),
            ),
          ),
          child: Text(existe ? t.loginButton : t.activateAccountButton),
        ),
      ],
    );
  }
}
