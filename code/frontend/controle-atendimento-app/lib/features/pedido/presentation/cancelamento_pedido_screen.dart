import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/pedido_repository.dart';
import '../domain/pedido.dart';

/// Tela 7 — Cancelamento de Pedido (`docs/controle-atendimento-prototype.md`
/// §3.7, `docs/controle-atendimento-functional.md` §6.2 (3.5)).
///
/// Cancelamento marca o atributo independente `cancelado = true`, sem
/// transicionar o `status` corrente do pedido (§6.1, nota do diagrama).
class CancelamentoPedidoScreen extends StatefulWidget {
  const CancelamentoPedidoScreen({super.key, required this.pedido});

  final Pedido pedido;

  @override
  State<CancelamentoPedidoScreen> createState() => _CancelamentoPedidoScreenState();
}

class _CancelamentoPedidoScreenState extends State<CancelamentoPedidoScreen> {
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
      appBar: AppBar(title: Text('Cancelar Pedido — ${widget.pedido.identificador}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _motivoController,
          decoration: const InputDecoration(labelText: 'Motivo'),
          maxLines: 3,
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
    setState(() => _salvando = true);

    final motivo = _motivoController.text.trim();
    final pedidoOriginal = widget.pedido;
    final pedido = Pedido(
      identificador: pedidoOriginal.identificador,
      fluxoAtendimentoId: pedidoOriginal.fluxoAtendimentoId,
      status: pedidoOriginal.status,
      cancelado: true,
      nomeCliente: pedidoOriginal.nomeCliente,
      tipoEntrega: pedidoOriginal.tipoEntrega,
      tipoPagamento: pedidoOriginal.tipoPagamento,
      endereco: pedidoOriginal.endereco,
      observacao: pedidoOriginal.observacao,
      restricoes: pedidoOriginal.restricoes,
      valorPagamento: pedidoOriginal.valorPagamento,
      mesa: pedidoOriginal.mesa,
      imagemPedidoRef: pedidoOriginal.imagemPedidoRef,
      motivoCancelamento: motivo.isEmpty ? null : motivo,
      motivoDevolucao: pedidoOriginal.motivoDevolucao,
      dataHoraAguardandoAtendimento: pedidoOriginal.dataHoraAguardandoAtendimento,
      dataHoraEmAtendimento: pedidoOriginal.dataHoraEmAtendimento,
      dataHoraEmExecucao: pedidoOriginal.dataHoraEmExecucao,
      dataHoraRetiradoNoBalcao: pedidoOriginal.dataHoraRetiradoNoBalcao,
      dataHoraEnviado: pedidoOriginal.dataHoraEnviado,
      dataHoraEntregue: pedidoOriginal.dataHoraEntregue,
      dataHoraDevolvido: pedidoOriginal.dataHoraDevolvido,
      dataHoraCancelamento: pedidoOriginal.dataHoraCancelamento ?? DateTime.now(),
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
