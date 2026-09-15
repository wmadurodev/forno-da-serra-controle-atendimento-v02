import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/storage/imagem_pedido_storage.dart';
import '../data/pedido_repository.dart';
import '../domain/pedido.dart';

/// Tela 9 — Edição de Pedido em Execução (`docs/controle-atendimento-prototype.md`
/// §3.9, **P-6**; `docs/controle-atendimento-functional.md` **FN-4**).
class EdicaoPedidoExecucaoScreen extends StatefulWidget {
  const EdicaoPedidoExecucaoScreen({super.key, required this.pedido});

  final Pedido pedido;

  @override
  State<EdicaoPedidoExecucaoScreen> createState() => _EdicaoPedidoExecucaoScreenState();
}

class _EdicaoPedidoExecucaoScreenState extends State<EdicaoPedidoExecucaoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeClienteController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _observacaoController;
  late final TextEditingController _mesaController;
  late final TextEditingController _restricoesController;
  late final TextEditingController _valorPagamentoController;

  TipoEntrega? _tipoEntrega;
  TipoPagamento? _tipoPagamento;
  File? _novaFoto;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final pedido = widget.pedido;
    _nomeClienteController = TextEditingController(text: pedido.nomeCliente ?? '');
    _enderecoController = TextEditingController(text: pedido.endereco ?? '');
    _observacaoController = TextEditingController(text: pedido.observacao ?? '');
    _mesaController = TextEditingController(text: pedido.mesa ?? '');
    _restricoesController = TextEditingController(text: pedido.restricoes ?? '');
    _valorPagamentoController = TextEditingController(
      text: pedido.valorPagamento != null ? pedido.valorPagamento.toString() : '',
    );
    _tipoEntrega = pedido.tipoEntrega;
    _tipoPagamento = pedido.tipoPagamento;
  }

  @override
  void dispose() {
    _nomeClienteController.dispose();
    _enderecoController.dispose();
    _observacaoController.dispose();
    _mesaController.dispose();
    _restricoesController.dispose();
    _valorPagamentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar Pedido — ${widget.pedido.identificador}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: widget.pedido.identificador,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Identificador do Pedido'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeClienteController,
                decoration: const InputDecoration(labelText: 'Nome do Cliente'),
                validator: _obrigatorio,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TipoEntrega>(
                initialValue: _tipoEntrega,
                decoration: const InputDecoration(labelText: 'Tipo de Entrega'),
                items: TipoEntrega.values
                    .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo.titulo)))
                    .toList(),
                validator: (value) => value == null ? 'Selecione o tipo de entrega' : null,
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
                    .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo.titulo)))
                    .toList(),
                validator: (value) {
                  if (_tipoEntrega == TipoEntrega.delivery && value == null) {
                    return 'Selecione o tipo de pagamento';
                  }
                  return null;
                },
                onChanged: (valor) => setState(() => _tipoPagamento = valor),
              ),
              if (_tipoEntrega == TipoEntrega.delivery) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _enderecoController,
                  decoration: const InputDecoration(labelText: 'Endereço'),
                  validator: _obrigatorio,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacaoController,
                decoration: const InputDecoration(labelText: 'Observação'),
              ),
              const Divider(height: 32),
              TextFormField(
                controller: _mesaController,
                decoration: const InputDecoration(labelText: 'Mesa'),
                validator: _obrigatorio,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _restricoesController,
                decoration: const InputDecoration(labelText: 'Restrições'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorPagamentoController,
                decoration: const InputDecoration(labelText: 'Valor Pagamento'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              _buildImagem(),
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
                  child: const Text('Fechar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _salvando ? null : _onGravar,
                  child: const Text('Gravar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagem() {
    final imagemAtual = widget.pedido.imagemPedidoRef;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _novaFoto != null
              ? Image.file(_novaFoto!, height: 200, fit: BoxFit.cover)
              : (imagemAtual != null ? Image.file(File(imagemAtual), height: 200, fit: BoxFit.cover) : null),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OutlinedButton.icon(
            onPressed: _salvando ? null : _onTirarFoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Tirar Outra Foto'),
          ),
        ),
      ],
    );
  }

  String? _obrigatorio(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  Future<void> _onTirarFoto() async {
    final imagem = await ImagePicker().pickImage(source: ImageSource.camera);
    if (imagem == null) return;
    setState(() => _novaFoto = File(imagem.path));
  }

  Future<void> _onGravar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    var imagemPedidoRef = widget.pedido.imagemPedidoRef;
    final novaFoto = _novaFoto;
    if (novaFoto != null) {
      imagemPedidoRef = await ImagemPedidoStorage().salvar(widget.pedido.id!, novaFoto);
      if (!mounted) return;
    }

    final endereco = _enderecoController.text.trim();
    final observacao = _observacaoController.text.trim();
    final restricoes = _restricoesController.text.trim();
    final valorPagamento = double.tryParse(_valorPagamentoController.text.trim().replaceAll(',', '.'));

    final pedido = Pedido(
      id: widget.pedido.id,
      identificador: widget.pedido.identificador,
      fluxoAtendimentoId: widget.pedido.fluxoAtendimentoId,
      status: widget.pedido.status,
      cancelado: widget.pedido.cancelado,
      nomeCliente: _nomeClienteController.text.trim(),
      tipoEntrega: _tipoEntrega,
      tipoPagamento: _tipoPagamento,
      endereco: endereco.isEmpty ? null : endereco,
      observacao: observacao.isEmpty ? null : observacao,
      restricoes: restricoes.isEmpty ? null : restricoes,
      valorPagamento: valorPagamento,
      mesa: _mesaController.text.trim(),
      imagemPedidoRef: imagemPedidoRef,
      motivoCancelamento: widget.pedido.motivoCancelamento,
      motivoDevolucao: widget.pedido.motivoDevolucao,
      dataHoraAguardandoAtendimento: widget.pedido.dataHoraAguardandoAtendimento,
      dataHoraEmAtendimento: widget.pedido.dataHoraEmAtendimento,
      dataHoraEmExecucao: widget.pedido.dataHoraEmExecucao,
      dataHoraRetiradoNoBalcao: widget.pedido.dataHoraRetiradoNoBalcao,
      dataHoraEnviado: widget.pedido.dataHoraEnviado,
      dataHoraEntregue: widget.pedido.dataHoraEntregue,
      dataHoraDevolvido: widget.pedido.dataHoraDevolvido,
      dataHoraCancelamento: widget.pedido.dataHoraCancelamento,
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
