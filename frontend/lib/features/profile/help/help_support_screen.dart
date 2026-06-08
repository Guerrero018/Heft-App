import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_message.dart';
import '../widgets/settings_ui.dart';

const _supportEmail = 'teamheftapp@gmail.com';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      question: '¿Cómo registro un entrenamiento?',
      answer:
          'Desde Inicio, pulsa una rutina o "Entrenamiento libre". '
          'Marca cada serie como completada y pulsa Finalizar al terminar.',
    ),
    (
      question: '¿Cómo cambio mi contraseña?',
      answer:
          'Ve a Perfil → Ajustes → Privacidad y seguridad → Cambiar contraseña. '
          'Recibirás un código de verificación en tu email.',
    ),
    (
      question: '¿Por qué no recibo notificaciones?',
      answer:
          'Comprueba que los permisos del sistema estén activos y que las '
          'notificaciones estén habilitadas en Ajustes → Notificaciones.',
    ),
    (
      question: '¿Cómo registro mis medidas corporales?',
      answer:
          'En tu perfil, entra en Progreso corporal y pulsa el botón + para '
          'añadir peso, medidas y fotos de progreso.',
    ),
    (
      question: '¿Puedo usar Heft sin conexión?',
      answer:
          'Por ahora necesitas conexión para sincronizar rutinas, entrenamientos '
          'y estadísticas. El modo offline está planificado.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ayuda y soporte',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SettingsInfoBanner(
            icon: Icons.support_agent,
            message:
                '¿Tienes dudas o encontraste un problema? Revisa las preguntas '
                'frecuentes o contacta con nuestro equipo.',
          ),

          const SettingsSectionTitle(
            icon: Icons.quiz_outlined,
            title: 'Preguntas frecuentes',
          ),
          ..._faqs.map((faq) => _FaqTile(
                question: faq.question,
                answer: faq.answer,
              )),

          const SizedBox(height: 20),

          const SettingsSectionTitle(
            icon: Icons.contact_support_outlined,
            title: 'Contacto',
          ),
          SettingsSectionCard(
            children: [
              SettingsNavRow(
                icon: Icons.email_outlined,
                label: 'Escribir a soporte',
                subtitle: _supportEmail,
                onTap: () => _copyEmail(context),
              ),
              const Divider(color: Colors.white10),
              SettingsNavRow(
                icon: Icons.bug_report_outlined,
                label: 'Reportar un problema',
                subtitle: 'Copia el email y describe el error',
                onTap: () => _showReportDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const SettingsSectionTitle(icon: Icons.info_outline, title: 'Acerca de'),
          SettingsSectionCard(
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.fitness_center, color: AppTheme.primaryColor, size: 22),
                title: Text(
                  'Heft',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Versión 1.0.0',
                  style: TextStyle(color: AppTheme.hintColor, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _supportEmail));
    AppMessage.showSuccess(context, 'Email copiado: $_supportEmail');
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reportar un problema',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Envía un email a $_supportEmail describiendo:\n\n'
          '• Qué estabas haciendo\n'
          '• Qué esperabas que ocurriera\n'
          '• Qué ocurrió en su lugar\n\n'
          'Si puedes, adjunta una captura de pantalla.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _copyEmail(context);
            },
            child: const Text('Copiar email'),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      widget.answer,
                      style: const TextStyle(
                        color: AppTheme.hintColor,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
