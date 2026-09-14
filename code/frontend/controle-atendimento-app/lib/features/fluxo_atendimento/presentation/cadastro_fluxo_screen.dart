import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/fluxo_atendimento_repository.dart';
import '../domain/fluxo_atendimento.dart';
import 'quadro_atendimento_screen.dart';

/// Tela 3 — Cadastro do Fluxo de Atendimento
/// (`docs/controle-atendimento-prototype.md` §3.3,
/// `docs/controle-atendimento-functional.md` §5.2).
class CadastroFluxoScreen extends StatefulWidget {
  const CadastroFluxoScreen({super.key});

  @override
  State<CadastroFluxoScreen> createState() => _CadastroFluxoScreenState();
}

class _CadastroFluxoScreenState extends State<CadastroFluxoScreen> {
  static const _tamanhoMaximoIdentificador = 15;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _identificadorController;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _identificadorController = TextEditingController(text: _sugestaoIdentificador());
  }

  @override
  void dispose() {
    _identificadorController.dispose();
    super.dispose();
  }

  String _sugestaoIdentificador() {
    final agora = DateTime.now();
    String pad2(int v) => v.toString().padLeft(2, '0');
    return '${pad2(agora.day)}/${pad2(agora.month)}/${agora.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Fluxo de Atendimento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _identificadorController,
            decoration: const InputDecoration(labelText: 'Identificador'),
            maxLength: _tamanhoMaximoIdentificador,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe o identificador do fluxo';
              }
              return null;
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _salvando ? null : _onConfirmar,
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onConfirmar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    final fluxo = FluxoAtendimento(
      identificador: _identificadorController.text.trim(),
      status: FluxoAtendimentoStatus.aberto,
    );

    try {
      final repository = context.read<FluxoAtendimentoRepository>();
      await repository.insert(fluxo);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => QuadroAtendimentoScreen(fluxo: fluxo)),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on DatabaseException catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      final mensagem = e.isUniqueConstraintError()
          ? 'Já existe um Fluxo de Atendimento com este identificador'
          : 'Não foi possível criar o Fluxo de Atendimento';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }
}
