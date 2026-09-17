import 'package:flutter/material.dart';

/// Tema base do app. Decisões de design visual (cores, tipografia) estão
/// fora do escopo de `docs/controle-atendimento-prototype.md` — este tema
/// é apenas um ponto de partida neutro.
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.deepOrange,
  inputDecorationTheme: InputDecorationTheme(
    // `WidgetStateTextStyle` (em vez de um `TextStyle` fixo) só é aplicado ao
    // rótulo "em repouso" (campo vazio/sem foco, posição de hint) — quando o
    // campo ganha foco ou é preenchido e o rótulo "flutua", o Flutter cai de
    // volta no `floatingLabelStyle` (aqui deliberadamente não definido, então
    // usa o padrão do Material), pois um `WidgetStateTextStyle` usado sem
    // resolução de estado (o fallback interno do Flutter quando não há
    // `floatingLabelStyle` próprio) se comporta como um `TextStyle()` vazio.
    labelStyle: WidgetStateTextStyle.resolveWith(
      (states) => TextStyle(fontSize: 15.6, color: Colors.grey.shade400),
    ),
  ),
);
