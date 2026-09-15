import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/pedido_repository.dart';
import '../domain/pedido.dart';

/// Tela 8 — Devolução de Entrega (`docs/controle-atendimento-prototype.md`
/// §3.8, `docs/controle-atendimento-functional.md` §6.2 (3.9)).
class DevolucaoEntregaScreen extends StatefulWidget {
  const DevolucaoEntregaScreen({super.key, required this.pedido});

  final Pedido pedido;

  @override
  State<DevolucaoEntregaScreen> createState() => _DevolucaoEntregaScreenState();
}

class _DevolucaoEntregaScreenState extends State<DevolucaoEntregaScreen> {
  static const _sugestoes = ['Não encontrado', 'Devolvido pelo cliente'];

  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Devolução — ${widget.pedido.identificador}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: _sugestoes
                    .map(
                      (sugestao) => ActionChip(
                        label: Text(sugestao),
                        onPressed: () => setState(() => _motivoController.text = sugestao),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivoController,
                decoration: const InputDecoration(labelText: 'Motivo da Devolução'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o motivo da devolução';
                  }
                  return null;
                },
              ),
            ],
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

    final pedidoOriginal = widget.pedido;
    final pedido = Pedido(
      identificador: pedidoOriginal.identificador,
      fluxoAtendimentoId: pedidoOriginal.fluxoAtendimentoId,
      status: PedidoStatus.devolvido,
      cancelado: pedidoOriginal.cancelado,
      nomeCliente: pedidoOriginal.nomeCliente,
      tipoEntrega: pedidoOriginal.tipoEntrega,
      tipoPagamento: pedidoOriginal.tipoPagamento,
      endereco: pedidoOriginal.endereco,
      observacao: pedidoOriginal.observacao,
      restricoes: pedidoOriginal.restricoes,
      valorPagamento: pedidoOriginal.valorPagamento,
      mesa: pedidoOriginal.mesa,
      imagemPedidoRef: pedidoOriginal.imagemPedidoRef,
      motivoCancelamento: pedidoOriginal.motivoCancelamento,
      motivoDevolucao: _motivoController.text.trim(),
      dataHoraAguardandoAtendimento: pedidoOriginal.dataHoraAguardandoAtendimento,
      dataHoraEmAtendimento: pedidoOriginal.dataHoraEmAtendimento,
      dataHoraEmExecucao: pedidoOriginal.dataHoraEmExecucao,
      dataHoraRetiradoNoBalcao: pedidoOriginal.dataHoraRetiradoNoBalcao,
      dataHoraEnviado: pedidoOriginal.dataHoraEnviado,
      dataHoraEntregue: pedidoOriginal.dataHoraEntregue,
      dataHoraDevolvido: pedidoOriginal.dataHoraDevolvido ?? DateTime.now(),
      dataHoraCancelamento: pedidoOriginal.dataHoraCancelamento,
    );

    final repository = context.read<PedidoRepository>();
    try {
      await repository.salvar(pedido);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
