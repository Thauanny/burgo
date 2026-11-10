# Burgo — gerador de cidades para RPG (Flutter Web)

Gerador e editor de cidades isométricas (estilo fofo, inspirado em jogos de vida/construção)
para mesas de RPG, jogos e livros.

## Como rodar

```bash
flutter pub get
flutter run -d chrome
flutter analyze && flutter test
```

## O que já tem (v0.1)

- Cidade procedural com ruas, quarteirões, praça central, casas, prédios, árvores e postes (seed reproduzível).
- **Presets de sistema**: Tormenta20, D&D 5e, Tales from the Loop, Ordem Paranormal, Call of Cthulhu,
  Cyberpunk RED e Fantasia genérica. Cada um muda paleta, nomes, tipos de prédio, povos e ganchos de aventura.
- **Áreas especiais** pintáveis: Área de Tormenta, Perímetro do Loop, Zona de Membrana Fina, Região do Culto,
  Zona de Combate, Terras Selvagens.
- Editor: mover construções/objetos, construtor (andares, largura, profundidade, telhado, cores, chaminé),
  pintar ruas, colocar objetos, apagar.

## Adicionar um sistema novo

Inclua um `RpgSystem` em `RpgSystems.all` (`lib/systems/rpg_systems.dart`). Na Fase 1 isso passa a ser um arquivo JSON.

## Próximos passos

Salvar/carregar JSON, exportar PNG, desfazer/refazer, rios e muros, interiores e masmorras.

## Visual por sistema

Cada sistema tem uma identidade própria (`lib/systems/art_profiles.dart`): construções (castelo, moinho, templo, torres, laboratório, arranha-céus...), animais, objetos, ruas, céu e uma área especial animada. Para ver as imagens: `SNAPSHOT_DIR=/pasta flutter test test/render_snapshot_test.dart` (e `SNAPSHOT_SHOWCASE=1` para a vitrine de assets).

## Tipos de assentamento e fazendas

Cada cenário tem tipos de assentamento (capital, cidade voadora, porto, Velho Oeste, fazendas do Loop...) e três composições: cidade + fazendas, só cidade, só fazendas. Há ferramentas para pintar água, muros e colocar fazendas. Toda a arte é desenhada em código (nenhum pacote de terceiros); créditos e referências no menu Ajuda.

## Projetos, abas e masmorras

O app abre vários projetos em abas (cidade, só fazendas, cidade + fazendas, masmorra). Tudo é salvo automaticamente no navegador; o menu Arquivo salva na biblioteca, exporta/importa `.json`. Ctrl/⌘+Z desfaz. A visão pode ser isométrica ou de cima.

## Estrutura

`domain/` (modelos e regras) · `geometry/` (projeção isométrica) · `generation/` (geradores) · `systems/` (presets) ·
`editor/` (estado, câmera e ferramentas) · `render/` (camadas de desenho) · `ui/` (telas e painel).
Detalhes e regras de código em `Burgo — Requisitos do projeto.md`.
