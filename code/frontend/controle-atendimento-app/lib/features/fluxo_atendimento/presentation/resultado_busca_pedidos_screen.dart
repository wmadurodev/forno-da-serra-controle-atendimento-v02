import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/loading_view.dart';
import '../../pedido/data/pedido_repository.dart';
import '../../pedido/domain/pedido.dart';
import '../../pedido/presentation/cadastro_pedido_screen.dart';
import '../../pedido/presentation/cancelamento_pedido_screen.dart';
import '../../pedido/presentation/devolucao_entrega_screen.dart';
import '../../pedido/presentation/edicao_pedido_execucao_screen.dart';
import '../../pedido/presentation/execucao_pedido_screen.dart';
import 'fase_pedido_visual.dart';
import 'pedido_card.dart';

/// Resultados da Busca de Pedidos (Passo 27/28), em tela separada do
/// formulário (`BuscaPedidosScreen`). Cards com os mesmos botões de ação do
/// Kanban, de acordo com o status de cada Pedido.
class ResultadoBuscaPedidosScreen extends StatefulWidget {
  const ResultadoBuscaPedidosScreen({
    super.key,
    required this.fluxoAtendimentoId,
    required this.somenteLeitura,
    required this.campo,
    required this.valor,
  });

  final String fluxoAtendimentoId;
  final bool somenteLeitura;
  final CampoBuscaPedido campo;
  final String valor;

  @override
  State<ResultadoBuscaPedidosScreen> createState() => _ResultadoBuscaPedidosScreenState();
}

class _ResultadoBuscaPedidosScreenState extends State<ResultadoBuscaPedidosScreen> {
  bool _carregando = true;
  List<Pedido> _resultados = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final repository = context.read<PedidoRepository>();
    final resultados = await repository.buscar(widget.fluxoAtendimentoId, widget.campo, widget.valor);
    if (!mounted) return;
    setState(() {
      _resultados = resultados;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultados da Busca')),
      body: _carregando ? const LoadingView() : _buildResultados(),
    );
  }

  Widget _buildResultados() {
    if (_resultados.isEmpty) {
      return const Center(child: Text('Nenhum pedido encontrado'));
    }

    final porStatus = <PedidoStatus, List<Pedido>>{};
    for (final pedido in _resultados) {
      porStatus.putIfAbsent(pedido.status, () => []).add(pedido);
    }
    for (final lista in porStatus.values) {
      lista.sort(_compararPorDataHoraDesc);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final status in PedidoStatus.values)
          if (porStatus[status] != null) _buildBloco(status, porStatus[status]!),
      ],
    );
  }

  Widget _buildBloco(PedidoStatus status, List<Pedido> pedidos) {
    final indice = PedidoStatus.values.indexOf(status);
    final cor = corCinza(status) ?? corColuna(indice, PedidoStatus.values.length);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconePorFase[status], size: 18),
              const SizedBox(width: 6),
              Text('${status.titulo} (${pedidos.length})', style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          for (final pedido in pedidos)
            PedidoCard(
              pedido: pedido,
              somenteLeitura: widget.somenteLeitura,
              onExcluir: () => _executar(() => context.read<PedidoRepository>().excluir(pedido)),
              onRetirado: () => _executar(
                () => context.read<PedidoRepository>().atualizarStatus(pedido, PedidoStatus.retiradoNoBalcao),
              ),
              onEnviado: () => _executar(
                () => context.read<PedidoRepository>().atualizarStatus(pedido, PedidoStatus.enviado),
              ),
              onEntregue: () => _executar(
                () => context.read<PedidoRepository>().atualizarStatus(pedido, PedidoStatus.entregue),
              ),
              onAtendimento: () => _abrirCadastroPedido(pedido),
              onEditarCadastro: () => _abrirCadastroPedido(pedido),
              onExecutar: () => _abrirExecucaoPedido(pedido),
              onEditarExecucao: () => _abrirEdicaoExecucao(pedido),
              onCancelar: () => _abrirCancelamento(pedido),
              onDevolvido: () => _abrirDevolucao(pedido),
            ),
        ],
      ),
    );
  }

  Future<void> _executar(Future<void> Function() acao) async {
    try {
      await acao();
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
    await _carregar();
  }

  Future<void> _abrirCadastroPedido(Pedido pedido) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CadastroPedidoScreen(
          fluxoAtendimentoId: widget.fluxoAtendimentoId,
          pedidoExistente: pedido,
        ),
      ),
    );
    await _carregar();
  }

  Future<void> _abrirExecucaoPedido(Pedido pedido) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExecucaoPedidoScreen(pedido: pedido)),
    );
    await _carregar();
  }

  Future<void> _abrirEdicaoExecucao(Pedido pedido) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EdicaoPedidoExecucaoScreen(pedido: pedido)),
    );
    await _carregar();
  }

  Future<void> _abrirCancelamento(Pedido pedido) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CancelamentoPedidoScreen(pedido: pedido)),
    );
    await _carregar();
  }

  Future<void> _abrirDevolucao(Pedido pedido) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DevolucaoEntregaScreen(pedido: pedido)),
    );
    await _carregar();
  }

  /// Mais recente primeiro, mesmo critério do Kanban (Passo 13).
  static int _compararPorDataHoraDesc(Pedido a, Pedido b) {
    final dataA = a.dataHoraStatusAtual;
    final dataB = b.dataHoraStatusAtual;
    if (dataA == null && dataB == null) return a.identificador.compareTo(b.identificador);
    if (dataA == null) return 1;
    if (dataB == null) return -1;
    return dataB.compareTo(dataA);
  }
}
