import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/pedido_repository.dart';
import '../domain/pedido.dart';

/// Tela 5 — Cadastro de Pedido (`docs/controle-atendimento-prototype.md` §3.5,
/// `docs/controle-atendimento-functional.md` §6.2 (3.1/3.2), §7).
class CadastroPedidoScreen extends StatefulWidget {
  const CadastroPedidoScreen({
    super.key,
    required this.fluxoAtendimentoId,
    this.pedidoExistente,
  });

  final String fluxoAtendimentoId;

  /// Quando fornecido (abertura a partir dos botões "Atendimento" ou
  /// "Editar" da Tela 4), a tela já abre com os campos habilitados e
  /// pré-preenchidos, pulando a etapa de busca por identificador.
  final Pedido? pedidoExistente;

  @override
  State<CadastroPedidoScreen> createState() => _CadastroPedidoScreenState();
}

class _CadastroPedidoScreenState extends State<CadastroPedidoScreen> {
  final _identificadorFormKey = GlobalKey<FormState>();
  final _dadosFormKey = GlobalKey<FormState>();

  late final TextEditingController _identificadorController;
  final _nomeClienteController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _observacaoController = TextEditingController();

  TipoEntrega? _tipoEntrega;
  TipoPagamento? _tipoPagamento;

  /// Pedido já existente no banco para este identificador (encontrado pela
  /// busca, ou recebido diretamente via [CadastroPedidoScreen.pedidoExistente]).
  /// `null` enquanto ainda não confirmado, ou quando o identificador não
  /// corresponde a nenhum pedido já gravado (fluxo "Novo Pedido").
  Pedido? _pedidoBase;
  bool _identificadorConfirmado = false;
  bool _buscando = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final existente = widget.pedidoExistente;
    _identificadorController = TextEditingController(
      text: existente?.identificador ?? '',
    );

    if (existente != null) {
      _pedidoBase = existente;
      _identificadorConfirmado = true;
      _nomeClienteController.text = existente.nomeCliente ?? '';
      _tipoEntrega = existente.tipoEntrega;
      _tipoPagamento = existente.tipoPagamento;
      _enderecoController.text = existente.endereco ?? '';
      _observacaoController.text = existente.observacao ?? '';
    }
  }

  @override
  void dispose() {
    _identificadorController.dispose();
    _nomeClienteController.dispose();
    _enderecoController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Pedido')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildCampoIdentificador(),
            if (_identificadorConfirmado) ...[
              const SizedBox(height: 16),
              _buildCamposCadastro(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _salvando
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: (_identificadorConfirmado && !_salvando)
                      ? _onGravar
                      : null,
                  child: const Text('Gravar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampoIdentificador() {
    return Form(
      key: _identificadorFormKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _identificadorController,
              readOnly: _identificadorConfirmado,
              decoration: const InputDecoration(
                labelText: 'Identificador do Pedido',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o identificador do pedido';
                }
                return null;
              },
            ),
          ),
          if (!_identificadorConfirmado) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton(
                onPressed: _buscando ? null : _onConfirmarIdentificador,
                child: const Text('Confirmar'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCamposCadastro() {
    return Form(
      key: _dadosFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nomeClienteController,
            decoration: const InputDecoration(labelText: 'Nome do Cliente'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TipoEntrega>(
            initialValue: _tipoEntrega,
            decoration: const InputDecoration(labelText: 'Tipo de Entrega'),
            items: TipoEntrega.values
                .map(
                  (tipo) =>
                      DropdownMenuItem(value: tipo, child: Text(tipo.titulo)),
                )
                .toList(),
            onChanged: (valor) => setState(() {
              _tipoEntrega = valor;
              if (valor != TipoEntrega.delivery) {
                _enderecoController.clear();
              }
            }),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TipoPagamento>(
            initialValue: _tipoPagamento,
            decoration: const InputDecoration(labelText: 'Tipo de Pagamento'),
            items: TipoPagamento.values
                .map(
                  (tipo) =>
                      DropdownMenuItem(value: tipo, child: Text(tipo.titulo)),
                )
                .toList(),
            onChanged: (valor) => setState(() => _tipoPagamento = valor),
          ),
          if (_tipoEntrega == TipoEntrega.delivery) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _enderecoController,
              decoration: const InputDecoration(labelText: 'Endereço'),
              validator: (value) {
                // Endereço só é obrigatório ao editar um Pedido que já
                // passou de aguardando_atendimento (Passo 23) — na criação
                // (aguardando_atendimento), fica opcional: se faltar, o
                // Pedido simplesmente não avança para em_atendimento.
                final editandoPedidoAvancado =
                    _pedidoBase != null &&
                    _pedidoBase!.status != PedidoStatus.aguardandoAtendimento;
                if (editandoPedidoAvancado &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Informe o endereço';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _observacaoController,
            decoration: const InputDecoration(labelText: 'Observação'),
          ),
        ],
      ),
    );
  }

  /// Busca o Pedido mais recente (qualquer fluxo) com este identificador e
  /// usa seus dados de Cadastro como molde — Observação não é copiada.
  /// Sempre resulta na criação de um Pedido novo (Passo 18): `_pedidoBase`
  /// permanece nulo mesmo quando um molde é encontrado.
  Future<void> _onConfirmarIdentificador() async {
    if (!_identificadorFormKey.currentState!.validate()) return;

    setState(() => _buscando = true);

    final repository = context.read<PedidoRepository>();
    final identificador = _identificadorController.text.trim();
    final maisRecente = await repository.buscarMaisRecentePorIdentificador(
      identificador,
    );

    if (!mounted) return;
    setState(() {
      _buscando = false;
      _pedidoBase = null;
      _identificadorConfirmado = true;
      if (maisRecente != null) {
        _nomeClienteController.text = maisRecente.nomeCliente ?? '';
        _tipoEntrega = maisRecente.tipoEntrega;
        _tipoPagamento = maisRecente.tipoPagamento;
        _enderecoController.text = maisRecente.endereco ?? '';
      }
    });
  }

  Future<void> _onGravar() async {
    if (!_dadosFormKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    final nomeCliente = _nomeClienteController.text.trim();
    final endereco = _enderecoController.text.trim();
    final observacao = _observacaoController.text.trim();

    // Tipo de Pagamento só é obrigatório para delivery — retirada no balcão
    // pode ficar sem essa informação nesta fase (Passo 22).
    final pagamentoObrigatorio = _tipoEntrega == TipoEntrega.delivery;
    final cadastroCompleto =
        nomeCliente.isNotEmpty &&
        _tipoEntrega != null &&
        (!pagamentoObrigatorio || _tipoPagamento != null) &&
        (_tipoEntrega != TipoEntrega.delivery || endereco.isNotEmpty);

    final base = _pedidoBase;
    // Uma vez além de `aguardando_atendimento`, o status nunca regride (FN-8):
    // editar os dados de Cadastro de um pedido mais avançado (ex.: a partir do
    // botão "Editar" do card `em_atendimento`) preserva o status atual.
    final novoStatus =
        (base == null || base.status == PedidoStatus.aguardandoAtendimento)
        ? (cadastroCompleto
              ? PedidoStatus.emAtendimento
              : PedidoStatus.aguardandoAtendimento)
        : base.status;

    final pedido = Pedido(
      id: base?.id,
      identificador: _identificadorController.text.trim(),
      fluxoAtendimentoId: widget.fluxoAtendimentoId,
      status: novoStatus,
      cancelado: base?.cancelado ?? false,
      nomeCliente: nomeCliente.isEmpty ? null : nomeCliente,
      tipoEntrega: _tipoEntrega,
      tipoPagamento: _tipoPagamento,
      endereco: endereco.isEmpty ? null : endereco,
      observacao: observacao.isEmpty ? null : observacao,
      restricoes: base?.restricoes,
      valorPagamento: base?.valorPagamento,
      mesa: base?.mesa,
      imagemPedidoRef: base?.imagemPedidoRef,
      motivoCancelamento: base?.motivoCancelamento,
      motivoDevolucao: base?.motivoDevolucao,
      dataHoraAguardandoAtendimento:
          base?.dataHoraAguardandoAtendimento ?? DateTime.now(),
      dataHoraEmAtendimento:
          base?.dataHoraEmAtendimento ??
          (novoStatus == PedidoStatus.emAtendimento ? DateTime.now() : null),
      dataHoraEmExecucao: base?.dataHoraEmExecucao,
      dataHoraRetiradoNoBalcao: base?.dataHoraRetiradoNoBalcao,
      dataHoraEnviado: base?.dataHoraEnviado,
      dataHoraEntregue: base?.dataHoraEntregue,
      dataHoraDevolvido: base?.dataHoraDevolvido,
      dataHoraCancelamento: base?.dataHoraCancelamento,
    );

    final repository = context.read<PedidoRepository>();
    try {
      await repository.salvar(pedido);
      if (!mounted) return;
      Navigator.of(context).pop(novoStatus);
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
