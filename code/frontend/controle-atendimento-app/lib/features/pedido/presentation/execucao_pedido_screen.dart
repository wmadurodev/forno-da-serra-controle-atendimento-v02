import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/storage/imagem_pedido_storage.dart';
import '../data/pedido_repository.dart';
import '../domain/pedido.dart';

/// Tela 6 — Execução de Pedido (`docs/controle-atendimento-prototype.md` §3.6,
/// `docs/controle-atendimento-functional.md` §6.2 (3.4)).
class ExecucaoPedidoScreen extends StatefulWidget {
  const ExecucaoPedidoScreen({super.key, required this.pedido});

  final Pedido pedido;

  @override
  State<ExecucaoPedidoScreen> createState() => _ExecucaoPedidoScreenState();
}

class _ExecucaoPedidoScreenState extends State<ExecucaoPedidoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mesaController = TextEditingController();
  final _restricoesController = TextEditingController();
  final _valorPagamentoController = TextEditingController();

  File? _foto;
  bool _salvando = false;
  String? _erroFoto;

  @override
  void dispose() {
    _mesaController.dispose();
    _restricoesController.dispose();
    _valorPagamentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Execução — ${widget.pedido.identificador}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildFoto(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mesaController,
                decoration: const InputDecoration(labelText: 'Mesa'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a mesa';
                  }
                  return null;
                },
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

  Widget _buildFoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_foto != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_foto!, height: 200, fit: BoxFit.cover),
          ),
        if (_erroFoto != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_erroFoto!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OutlinedButton.icon(
            onPressed: _salvando ? null : _onTirarFoto,
            icon: const Icon(Icons.camera_alt),
            label: Text(_foto == null ? 'Tirar Foto' : 'Tirar Outra Foto'),
          ),
        ),
      ],
    );
  }

  Future<void> _onTirarFoto() async {
    final imagem = await ImagePicker().pickImage(source: ImageSource.camera);
    if (imagem == null) return;
    setState(() {
      _foto = File(imagem.path);
      _erroFoto = null;
    });
  }

  Future<void> _onGravar() async {
    final formValido = _formKey.currentState!.validate();
    final foto = _foto;

    if (foto == null) {
      setState(() => _erroFoto = 'A foto do pedido é obrigatória');
    }
    if (!formValido || foto == null) return;

    setState(() => _salvando = true);

    final imagemPedidoRef = await ImagemPedidoStorage().salvar(widget.pedido.id!, foto);
    if (!mounted) return;

    final restricoes = _restricoesController.text.trim();
    final valorPagamento = double.tryParse(_valorPagamentoController.text.trim().replaceAll(',', '.'));

    final pedido = Pedido(
      id: widget.pedido.id,
      identificador: widget.pedido.identificador,
      fluxoAtendimentoId: widget.pedido.fluxoAtendimentoId,
      status: PedidoStatus.emExecucao,
      cancelado: widget.pedido.cancelado,
      nomeCliente: widget.pedido.nomeCliente,
      tipoEntrega: widget.pedido.tipoEntrega,
      tipoPagamento: widget.pedido.tipoPagamento,
      endereco: widget.pedido.endereco,
      observacao: widget.pedido.observacao,
      restricoes: restricoes.isEmpty ? null : restricoes,
      valorPagamento: valorPagamento,
      mesa: _mesaController.text.trim(),
      imagemPedidoRef: imagemPedidoRef,
      motivoCancelamento: widget.pedido.motivoCancelamento,
      motivoDevolucao: widget.pedido.motivoDevolucao,
      dataHoraAguardandoAtendimento: widget.pedido.dataHoraAguardandoAtendimento,
      dataHoraEmAtendimento: widget.pedido.dataHoraEmAtendimento,
      dataHoraEmExecucao: widget.pedido.dataHoraEmExecucao ?? DateTime.now(),
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
