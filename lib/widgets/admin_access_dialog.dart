import 'package:flutter/material.dart';

class AdminAccessDialogResult {
  final String email;
  final String password;
  final bool rememberPassword;

  const AdminAccessDialogResult({
    required this.email,
    required this.password,
    required this.rememberPassword,
  });
}

class AdminAccessDialog extends StatefulWidget {
  const AdminAccessDialog({
    super.key,
    required this.initialEmail,
    required this.initialPassword,
    required this.initialRememberPassword,
  });

  final String initialEmail;
  final String initialPassword;
  final bool initialRememberPassword;

  @override
  State<AdminAccessDialog> createState() => _AdminAccessDialogState();
}

class _AdminAccessDialogState extends State<AdminAccessDialog> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  bool _showPassword = false;
  late bool _rememberPassword;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _passwordCtrl = TextEditingController(text: widget.initialPassword);
    _rememberPassword = widget.initialRememberPassword;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Acceso Admin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Ocultar' : 'Mostrar',
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _rememberPassword,
            title: const Text('Recordar contraseña'),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) {
              setState(() {
                _rememberPassword = value ?? false;
              });
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              AdminAccessDialogResult(
                email: _emailCtrl.text.trim(),
                password: _passwordCtrl.text,
                rememberPassword: _rememberPassword,
              ),
            );
          },
          child: const Text('Entrar'),
        ),
      ],
    );
  }
}
