import 'dart:ui';
import '../domain/city_types.dart';
import '../domain/era.dart';
import 'art_profile.dart';
import 'settlement_type.dart';

typedef _K = BuildingKind;
typedef _P = PropType;

/// Tipos de assentamento por cenário. Os textos de "lore" citam a fonte consultada em 9 nov 2026;
/// itens marcados "(confirmar)" vieram de wikis/blogs e devem ser conferidos nos livros oficiais.
abstract final class SettlementTypes {
  // ------------------------------------------------------------------ Tormenta20
  static const t20Capital = SettlementType(
    id: 'capital',
    // Valkaria (Tormenta Wiki): metrópole cosmopolita; humanos maioria, com Bairro dos Anões,
    // Vila Élfica, Favela dos Goblins e bairros de hynne e minotauros.
    population: [PropWeight(_P.raceHuman, 58), PropWeight(_P.raceGoblin, 8), PropWeight(_P.raceDwarf, 7), PropWeight(_P.raceElf, 6), PropWeight(_P.raceHalfling, 5), PropWeight(_P.raceMinotaur, 4), PropWeight(_P.raceQareen, 3), PropWeight(_P.raceDahllan, 2), PropWeight(_P.raceLefou, 2), PropWeight(_P.raceKliren, 1), PropWeight(_P.raceOsteon, 1), PropWeight(_P.raceTrog, 1), PropWeight(_P.raceMedusa, 0.5), PropWeight(_P.raceSuraggel, 0.5), PropWeight(_P.raceMermaid, 0.5), PropWeight(_P.raceGolem, 0.5)],
    name: 'Capital do Reinado (Valkaria)',
    lore:
        'Valkaria, "a Cidade sob a Deusa", capital de Deheon: metrópole cosmopolita e murada, de mais de dois milhões de habitantes em períodos de pico, com edifícios altos e densos dentro das muralhas (intramuros) e o campo fora delas (extramuros). A muralha é quase oval, com cinco portões (Norte, Oeste, Leste, Sul e Sudoeste). No centro está a imensa estátua da deusa, oca por dentro e com um labirinto subterrâneo, cercada por lagos concêntricos. Os bairros seguem o mapa oficial: Centro, Mercado, Baixa Vila de Lena, Bairro do Recoleço, Distrito Imperial (Palácio Imperial e Catedral), Refúgio da Felicidade, Cidade da Praia, Nitamu-ra, Vila Élfica, Favela dos Goblins, Campo de Keenn, Repouso Milicieno, Praça de Diversões e Maravilhas Grimbo, Rocha Cinzenta e Portão da Queda. Não tem Área da Tormenta. Norte em cima na vista 2D. Fontes: mapa oficial e descrição enviada por você; confirmar no suplemento "Valkaria: Cidade sob a Deusa" (Jambô). Faltam os canais, os aquedutos e o labirinto subterrâneo.',
    kinds: [
      KindWeight(_K.tallHouse, 4),
      KindWeight(_K.timber, 3),
      KindWeight(_K.cottage, 2),
      KindWeight(_K.manor, 1.5),
    ],
    walls: true,
    oval: true,
    minTiles: 120,
    noZone: true,
    noLandmark: true,
    ovalRiver: true,
    radialStreets: 8,
    aqueducts: [
      PathSpec('Aqueduto Nerull Superior', [-0.42, -1.15, -0.3, -0.55, -0.03, -0.06]),
      PathSpec('Aqueduto da Fonte Gelada', [0.54, -1.08, 0.42, -0.3, 0.39, 0.08, 0.04, 0.65]),
      PathSpec('', [0.42, -0.3, 0.78, -0.07], label: false),
      PathSpec('', [0.39, 0.08, 0.1, 0.08], label: false),
      PathSpec('', [0.39, 0.08, 0.6, 0.35], label: false),
      PathSpec('Aqueduto Arcos do Poente', [-1.1, -0.68, -0.79, -0.08, -0.51, 0.68]),
      PathSpec('', [-0.6, -0.14, -0.27, -0.59], label: false),
      PathSpec('', [-0.02, -0.68, 0.34, -0.65], label: false),
    ],
    spirals: [0.54, -0.12, 0.73, 0.09],
    statueRadius: 9.6,
    defaultMode: SettlementMode.cityOnly,
    gates: [
      GateSpec('Portão Norte', -0.15, -1.0),
      GateSpec('Portão Oeste', -1.0, -0.05),
      GateSpec('Portão Leste', 1.0, 0.0),
      GateSpec('Portão Sul', 0.22, 1.0),
      GateSpec('Portão Sudoeste', -0.68, 0.74),
    ],
    extras: [
      ExtraBuilding(_K.colossus, 'Estátua de Valkaria'),
      ExtraBuilding(_K.castle, 'Palácio Imperial', u: 0.20, v: -0.18),
      ExtraBuilding(_K.arena, 'Arena de Valkaria', u: 0.0, v: -0.55, minBlocks: 12),
    ],
    districts: [
      DistrictSpec(
        name: 'Centro',
        u: 0.04,
        v: 0.09,
        kinds: [KindWeight(_K.tallHouse, 5), KindWeight(_K.manor, 3), KindWeight(_K.temple, 1.5)],
        names: {
          _K.tallHouse: ['Banco Tibar', 'Casa de guilda', 'Sobrado de mercador', 'Casa de câmbio'],
          _K.manor: ['Mansão nobre', 'Casa de guilda', 'Solar'],
          _K.temple: ['Templo de Khalmyr', 'Templo de Valkaria'],
        },
      ),
      DistrictSpec(
        name: 'Mercado',
        u: -0.11,
        v: 0.27,
        kinds: [KindWeight(_K.timber, 4), KindWeight(_K.tallHouse, 3)],
        filler: [PropWeight(_P.stall, 5), PropWeight(_P.crate, 2), PropWeight(_P.barrel, 2), PropWeight(_P.cart, 1.5)],
        names: {
          _K.timber: ['Loja', 'Taverna', 'Padaria', 'Boticário', 'Ferraria'],
          _K.tallHouse: ['Armazém-residência', 'Casa de comércio', 'Banco'],
        },
      ),
      DistrictSpec(
        name: 'Baixa Vila de Lena',
        u: 0.14,
        v: 0.34,
        kinds: [KindWeight(_K.cottage, 3), KindWeight(_K.timber, 3), KindWeight(_K.temple, 0.6)],
        names: {
          _K.cottage: ['Casa', 'Cortiço', 'Casa de curandeira'],
          _K.timber: ['Estalagem', 'Hospedaria', 'Padaria'],
          _K.temple: ['Templo de Lena', 'Hospício de Lena'],
        },
      ),
      DistrictSpec(
        name: 'Bairro do Recoleço',
        population: [PropWeight(_P.raceDwarf, 60), PropWeight(_P.raceHuman, 30), PropWeight(_P.raceGoblin, 5), PropWeight(_P.raceKliren, 5)],
        u: -0.19,
        v: -0.22,
        kinds: [KindWeight(_K.cottage, 5), KindWeight(_K.timber, 2)],
        wallColors: [Color(0xFFD9CBB0), Color(0xFFC9B79A), Color(0xFFB5A58A)],
        roofColors: [Color(0xFF9B6B4A), Color(0xFF7A5A3A), Color(0xFF8A5E3C)],
        names: {
          _K.cottage: ['Casa', 'Cortiço', 'Choupana'],
          _K.timber: ['Taverna', 'Estalagem', 'Oficina'],
        },
      ),
      DistrictSpec(
        name: 'Distrito Imperial',
        population: [PropWeight(_P.raceHuman, 80), PropWeight(_P.raceElf, 8), PropWeight(_P.raceDwarf, 6), PropWeight(_P.raceQareen, 4), PropWeight(_P.raceSuraggel, 2)],
        u: 0.2,
        v: -0.18,
        kinds: [KindWeight(_K.manor, 5), KindWeight(_K.temple, 3), KindWeight(_K.tallHouse, 1)],
        wallColors: [Color(0xFFF1ECE0), Color(0xFFE7E1D2), Color(0xFFDCD6C6)],
        roofColors: [Color(0xFF3F5E8A), Color(0xFF4A5A70), Color(0xFF5B6E84)],
        trees: [PropType.tree],
        filler: [PropWeight(_P.tree, 4), PropWeight(_P.bush, 3), PropWeight(_P.statue, 1.2), PropWeight(_P.banner, 1)],
        names: {
          _K.manor: ['Palacete nobre', 'Embaixada', 'Casa de guilda'],
          _K.temple: ['Catedral de Valkaria', 'Templo de Valkaria', 'Templo de Khalmyr'],
        },
      ),
      DistrictSpec(
        name: 'Refúgio da Felicidade',
        u: 0.1,
        v: -0.72,
        kinds: [KindWeight(_K.timber, 5), KindWeight(_K.manor, 1)],
        filler: [PropWeight(_P.banner, 3), PropWeight(_P.stall, 2), PropWeight(_P.barrel, 2), PropWeight(_P.tree, 1)],
        names: {
          _K.timber: ['Casa de jogos', 'Taverna', 'Casa de festas', 'Estalagem'],
          _K.manor: ['Casa de espetáculos', 'Salão de festas'],
        },
      ),
      DistrictSpec(
        name: 'Cidade da Praia',
        population: [PropWeight(_P.raceHuman, 70), PropWeight(_P.raceMermaid, 15), PropWeight(_P.raceHalfling, 8), PropWeight(_P.raceQareen, 7)],
        u: -0.5,
        v: -0.42,
        canals: true,
        kinds: [KindWeight(_K.timber, 3), KindWeight(_K.cottage, 3), KindWeight(_K.tallHouse, 1)],
        filler: [PropWeight(_P.barrel, 3), PropWeight(_P.crate, 3), PropWeight(_P.cart, 1.5), PropWeight(_P.chicken, 1)],
        names: {
          _K.timber: ['Estalagem', 'Peixaria', 'Armazém', 'Taverna do canal'],
          _K.cottage: ['Casa de pescador', 'Casa'],
        },
      ),
      DistrictSpec(
        name: 'Nitamu-ra',
        population: [PropWeight(_P.raceHuman, 96), PropWeight(_P.raceKliren, 2), PropWeight(_P.raceGoblin, 2)],
        u: 0.71,
        v: -0.45,
        kinds: [KindWeight(_K.eastHouse, 7), KindWeight(_K.pagoda, 2)],
        wallColors: [Color(0xFFF3EBDD), Color(0xFFE9DFC9), Color(0xFFD9CBB0)],
        roofColors: [Color(0xFF2F3A44), Color(0xFF8E2B2B), Color(0xFF3A2F2A)],
        trees: [PropType.sakura, PropType.sakura, PropType.pine],
        filler: [PropWeight(_P.toro, 3), PropWeight(_P.torii, .5), PropWeight(_P.bush, 2)],
        names: {
          _K.eastHouse: ['Casa de chá', 'Dojô', 'Casa de banho', 'Residência'],
          _K.pagoda: ['Pagode', 'Santuário tamuraniano'],
        },
      ),
      DistrictSpec(
        name: 'Vila Élfica',
        population: [PropWeight(_P.raceElf, 88), PropWeight(_P.raceHuman, 8), PropWeight(_P.raceDahllan, 4)],
        u: 0.64,
        v: 0.1,
        kinds: [KindWeight(_K.elfHouse, 1)],
        wallColors: [Color(0xFFF4F1E8), Color(0xFFE8EEE6), Color(0xFFDDE8DD)],
        roofColors: [Color(0xFF4F8F6A), Color(0xFF3E7F6B), Color(0xFF6BA37A), Color(0xFF2F6F63)],
        trees: [PropType.tree],
        filler: [PropWeight(_P.elfLamp, 3), PropWeight(_P.tree, 3), PropWeight(_P.bush, 2)],
        names: {_K.elfHouse: ['Casa élfica', 'Salão de canto', 'Casa-árvore']},
      ),
      DistrictSpec(
        name: 'Favela dos Goblins',
        population: [PropWeight(_P.raceGoblin, 80), PropWeight(_P.raceHuman, 10), PropWeight(_P.raceKliren, 5), PropWeight(_P.raceTrog, 5)],
        u: -0.33,
        v: 0.75,
        kinds: [KindWeight(_K.workshop, 1)],
        wallColors: [Color(0xFF6E5B4A), Color(0xFF5F5A55), Color(0xFF7A6A58)],
        roofColors: [Color(0xFF3B3B3F), Color(0xFF4A3F3A), Color(0xFF6E4A2E)],
        filler: [PropWeight(_P.crate, 3), PropWeight(_P.barrel, 3), PropWeight(_P.cart, 2), PropWeight(_P.dog, 1)],
        names: {_K.workshop: ['Oficina de engenhocas', 'Casa de engrenagens', 'Fundição goblin', 'Barraco']},
      ),
      DistrictSpec(
        name: 'Campo de Keenn',
        u: -0.57,
        v: 0.62,
        kinds: [KindWeight(_K.tower, 3), KindWeight(_K.cottage, 3)],
        wallColors: [Color(0xFFB9B2A4), Color(0xFFA8A194)],
        roofColors: [Color(0xFF6B5A4A), Color(0xFF7A6A5A)],
        filler: [PropWeight(_P.banner, 3), PropWeight(_P.hay, 2), PropWeight(_P.barrel, 1)],
        names: {
          _K.tower: ['Torre de vigia', 'Quartel'],
          _K.cottage: ['Alojamento', 'Casa de oficial'],
        },
      ),
      DistrictSpec(
        name: 'Repouso Milicieno',
        u: -0.92,
        v: 0.07,
        kinds: [KindWeight(_K.temple, 2), KindWeight(_K.cottage, 1)],
        wallColors: [Color(0xFFCFCBC0), Color(0xFFBAB6AA)],
        trees: [PropType.pine],
        filler: [PropWeight(_P.grave, 6), PropWeight(_P.pine, 2), PropWeight(_P.statue, .6)],
        names: {
          _K.temple: ['Mausoléu', 'Capela do repouso'],
          _K.cottage: ['Casa do coveiro'],
        },
      ),
      DistrictSpec(
        name: 'Praça de Diversões e Maravilhas Grimbo',
        u: 0.34,
        v: 0.52,
        kinds: [KindWeight(_K.timber, 4), KindWeight(_K.manor, 1)],
        filler: [PropWeight(_P.stall, 5), PropWeight(_P.banner, 4), PropWeight(_P.cart, 1.5)],
        names: {
          _K.timber: ['Casa de jogos', 'Teatro', 'Circo', 'Tenda de maravilhas'],
          _K.manor: ['Grande salão de maravilhas'],
        },
      ),
      DistrictSpec(
        name: 'Rocha Cinzenta',
        u: -0.43,
        v: 0.4,
        kinds: [KindWeight(_K.tower, 2), KindWeight(_K.manor, 2), KindWeight(_K.tallHouse, 2)],
        wallColors: [Color(0xFF9FA3A6), Color(0xFF8E9296), Color(0xFFAEB1B2)],
        roofColors: [Color(0xFF3F4650), Color(0xFF4A4F55)],
        names: {
          _K.tower: ['Torre da Rocha'],
          _K.manor: ['Solar de pedra'],
          _K.tallHouse: ['Casa de pedra'],
        },
      ),
      DistrictSpec(
        name: 'Portão da Queda',
        u: -0.11,
        v: -0.9,
        kinds: [KindWeight(_K.cottage, 3), KindWeight(_K.tower, 1)],
        wallColors: [Color(0xFFA29C90), Color(0xFF8F8A7E)],
        roofColors: [Color(0xFF4A4F55), Color(0xFF5A4A44)],
        filler: [PropWeight(_P.crate, 2), PropWeight(_P.grave, 1), PropWeight(_P.bush, 2)],
        names: {
          _K.cottage: ['Ruína', 'Casa abandonada'],
          _K.tower: ['Torre em ruínas'],
        },
      ),
      DistrictSpec(
        name: 'Parque Oeste',
        showLabel: false,
        u: -0.45,
        v: -0.1,
        density: .1,
        kinds: [KindWeight(_K.cottage, 1)],
        trees: [PropType.tree],
        filler: [PropWeight(_P.tree, 5), PropWeight(_P.bush, 3), PropWeight(_P.statue, .4)],
      ),
      DistrictSpec(
        name: 'Jardins do Norte',
        showLabel: false,
        u: 0.26,
        v: -0.72,
        density: .1,
        kinds: [KindWeight(_K.cottage, 1)],
        trees: [PropType.tree],
        filler: [PropWeight(_P.tree, 5), PropWeight(_P.bush, 3), PropWeight(_P.statue, .4)],
      ),
      DistrictSpec(
        name: 'Zona Comercial Norte',
        showLabel: false,
        u: 0.15,
        v: -0.42,
        kinds: [KindWeight(_K.timber, 4), KindWeight(_K.tallHouse, 3)],
        wallColors: [Color(0xFFB4B0A6), Color(0xFFA7A398), Color(0xFFC2BEB2)],
        names: {
          _K.timber: ['Armazém', 'Loja', 'Casa de comércio', 'Ferraria'],
          _K.tallHouse: ['Armazém-residência', 'Casa de guilda', 'Banco'],
        },
        filler: [PropWeight(_P.crate, 3), PropWeight(_P.barrel, 3), PropWeight(_P.stall, 2), PropWeight(_P.cart, 1.5)],
      ),
      DistrictSpec(
        name: 'Zona Comercial Leste',
        showLabel: false,
        u: 0.95,
        v: -0.25,
        kinds: [KindWeight(_K.timber, 4), KindWeight(_K.tallHouse, 3)],
        wallColors: [Color(0xFFB4B0A6), Color(0xFFA7A398), Color(0xFFC2BEB2)],
        names: {
          _K.timber: ['Armazém', 'Loja', 'Casa de comércio', 'Ferraria'],
          _K.tallHouse: ['Armazém-residência', 'Casa de guilda', 'Banco'],
        },
        filler: [PropWeight(_P.crate, 3), PropWeight(_P.barrel, 3), PropWeight(_P.stall, 2), PropWeight(_P.cart, 1.5)],
      ),
      DistrictSpec(
        name: 'Cortiços do Oeste',
        showLabel: false,
        u: -0.74,
        v: 0.22,
        kinds: [KindWeight(_K.cottage, 5), KindWeight(_K.timber, 1)],
        wallColors: [Color(0xFFC9B79A), Color(0xFFB5A58A), Color(0xFFA89878)],
        roofColors: [Color(0xFF8A5E3C), Color(0xFF7A5A3A), Color(0xFF6E4A2E)],
        names: {
          _K.cottage: ['Cortiço', 'Casa', 'Choupana'],
          _K.timber: ['Taverna', 'Oficina'],
        },
      ),
      DistrictSpec(
        name: 'Cortiços do Sudoeste',
        showLabel: false,
        u: -0.82,
        v: 0.45,
        kinds: [KindWeight(_K.cottage, 5), KindWeight(_K.timber, 1)],
        wallColors: [Color(0xFFC9B79A), Color(0xFFB5A58A), Color(0xFFA89878)],
        roofColors: [Color(0xFF8A5E3C), Color(0xFF7A5A3A), Color(0xFF6E4A2E)],
        names: {
          _K.cottage: ['Cortiço', 'Casa', 'Choupana'],
          _K.timber: ['Taverna', 'Oficina'],
        },
      ),
      DistrictSpec(
        name: 'Cortiços do Sul',
        showLabel: false,
        u: 0.0,
        v: 0.62,
        kinds: [KindWeight(_K.cottage, 5), KindWeight(_K.timber, 1)],
        wallColors: [Color(0xFFC9B79A), Color(0xFFB5A58A), Color(0xFFA89878)],
        roofColors: [Color(0xFF8A5E3C), Color(0xFF7A5A3A), Color(0xFF6E4A2E)],
        names: {
          _K.cottage: ['Cortiço', 'Casa', 'Choupana'],
          _K.timber: ['Taverna', 'Oficina'],
        },
      ),
      DistrictSpec(
        name: 'Cortiços do Nordeste',
        showLabel: false,
        u: 0.42,
        v: -0.74,
        kinds: [KindWeight(_K.cottage, 5), KindWeight(_K.timber, 1)],
        wallColors: [Color(0xFFC9B79A), Color(0xFFB5A58A), Color(0xFFA89878)],
        roofColors: [Color(0xFF8A5E3C), Color(0xFF7A5A3A), Color(0xFF6E4A2E)],
        names: {
          _K.cottage: ['Cortiço', 'Casa', 'Choupana'],
          _K.timber: ['Taverna', 'Oficina'],
        },
      ),
      DistrictSpec(
        name: 'Bairro Médio Oeste',
        showLabel: false,
        u: -0.62,
        v: -0.14,
        kinds: [KindWeight(_K.timber, 3), KindWeight(_K.cottage, 3), KindWeight(_K.tallHouse, 0.6)],
        wallColors: [Color(0xFFF0E2BC), Color(0xFFE6D6A8), Color(0xFFE9DDB8)],
        names: {
          _K.timber: ['Casa de comerciante', 'Taverna', 'Padaria', 'Oficina'],
          _K.cottage: ['Casa', 'Chalé'],
          _K.tallHouse: ['Sobrado'],
        },
      ),
      DistrictSpec(
        name: 'Bairro Médio Sul',
        showLabel: false,
        u: 0.05,
        v: 0.82,
        kinds: [KindWeight(_K.timber, 3), KindWeight(_K.cottage, 3), KindWeight(_K.tallHouse, 0.6)],
        wallColors: [Color(0xFFF0E2BC), Color(0xFFE6D6A8), Color(0xFFE9DDB8)],
        names: {
          _K.timber: ['Casa de comerciante', 'Taverna', 'Padaria', 'Oficina'],
          _K.cottage: ['Casa', 'Chalé'],
          _K.tallHouse: ['Sobrado'],
        },
      ),
      DistrictSpec(
        name: 'Bairro Médio Leste',
        showLabel: false,
        u: 0.52,
        v: 0.58,
        kinds: [KindWeight(_K.timber, 3), KindWeight(_K.cottage, 3), KindWeight(_K.tallHouse, 0.6)],
        wallColors: [Color(0xFFF0E2BC), Color(0xFFE6D6A8), Color(0xFFE9DDB8)],
        names: {
          _K.timber: ['Casa de comerciante', 'Taverna', 'Padaria', 'Oficina'],
          _K.cottage: ['Casa', 'Chalé'],
          _K.tallHouse: ['Sobrado'],
        },
      ),
      DistrictSpec(
        name: 'Bairro Médio Nordeste',
        showLabel: false,
        u: 0.48,
        v: -0.15,
        kinds: [KindWeight(_K.timber, 3), KindWeight(_K.cottage, 3), KindWeight(_K.tallHouse, 0.6)],
        wallColors: [Color(0xFFF0E2BC), Color(0xFFE6D6A8), Color(0xFFE9DDB8)],
        names: {
          _K.timber: ['Casa de comerciante', 'Taverna', 'Padaria', 'Oficina'],
          _K.cottage: ['Casa', 'Chalé'],
          _K.tallHouse: ['Sobrado'],
        },
      ),
      DistrictSpec(
        name: 'Ruínas do Sul',
        showLabel: false,
        u: -0.2,
        v: 0.46,
        density: .55,
        kinds: [KindWeight(_K.cottage, 3), KindWeight(_K.tower, 1)],
        wallColors: [Color(0xFFA29C90), Color(0xFF8F8A7E)],
        roofColors: [Color(0xFF4A4F55), Color(0xFF5A4A44)],
        names: {
          _K.cottage: ['Ruína', 'Casa abandonada'],
          _K.tower: ['Torre em ruínas'],
        },
        filler: [PropWeight(_P.crate, 2), PropWeight(_P.grave, 1.5), PropWeight(_P.bush, 3)],
      ),
      DistrictSpec(
        name: 'Ruínas do Leste',
        showLabel: false,
        u: 0.5,
        v: 0.34,
        density: .55,
        kinds: [KindWeight(_K.cottage, 3), KindWeight(_K.tower, 1)],
        wallColors: [Color(0xFFA29C90), Color(0xFF8F8A7E)],
        roofColors: [Color(0xFF4A4F55), Color(0xFF5A4A44)],
        names: {
          _K.cottage: ['Ruína', 'Casa abandonada'],
          _K.tower: ['Torre em ruínas'],
        },
        filler: [PropWeight(_P.crate, 2), PropWeight(_P.grave, 1.5), PropWeight(_P.bush, 3)],
      ),
    ],
    names: {
      _K.timber: ['Taverna', 'Estalagem', 'Ferraria', 'Padaria'],
      _K.temple: ['Templo de Khalmyr', 'Templo de Lena', 'Templo de Valkaria'],
      _K.manor: ['Mansão nobre', 'Casa de guilda', 'Solar'],
      _K.tower: ['Torre de vigia', 'Torre de mago'],
    },
    filler: [
      PropWeight(_P.stall, 3),
      PropWeight(_P.barrel, 2),
      PropWeight(_P.crate, 2),
      PropWeight(_P.cart, 1.5),
      PropWeight(_P.tree, 1),
      PropWeight(_P.bush, 1),
      PropWeight(_P.dog, 1),
      PropWeight(_P.chicken, 1)
    ],
    street: [
      PropWeight(_P.lamp, 3),
      PropWeight(_P.banner, 2),
      PropWeight(_P.stall, 2),
      PropWeight(_P.statue, .5)
    ],
    farmShare: .25,
    crops: [
      CropType.wheat,
      CropType.vineyard,
      CropType.orchard,
      CropType.pasture
    ],
  );

  static const t20Floating = SettlementType(
    id: 'voadora',
    // Vectora, Cidade das Nuvens: magos e mercadores de toda Arton; kliren e qareen comuns.
    population: [PropWeight(_P.raceHuman, 45), PropWeight(_P.raceKliren, 12), PropWeight(_P.raceQareen, 10), PropWeight(_P.raceElf, 10), PropWeight(_P.raceGoblin, 8), PropWeight(_P.raceDwarf, 5), PropWeight(_P.raceDahllan, 3), PropWeight(_P.raceSuraggel, 3), PropWeight(_P.raceGolem, 2), PropWeight(_P.raceMinotaur, 2)],
    name: 'Cidade voadora (Vectora)',
    lore:
        'Vectora, a Cidade nas Nuvens ou "Mercado nas Nuvens": cidade comercial quase toda criada por magia, sobre uma enorme rocha flutuante que viaja a centenas de metros do chão, governada pelo arquimago Vectorius e pelo Conselho dos Seis (conjuradores que controlam cada segmento da cidade). A cidade é redonda e murada, dividida por duas avenidas em cruz (Avenida das Estrelas e Avenida do Sol) em quatro bairros, Magus, Bara, Mucro e Numen, em volta da Praça do Conselho. Por fora da muralha corre a Avenida Circular, cercada pelos bosques Magus, Bara, Mucro e Numen. Ao norte, a montanha e o Castelo Vectorius; ao sul, a Praça de Entrada e o Ancoradouro dos dirigíveis. Há um Campo de Levitação e um Campo de Restrição em volta. Fontes: mapas enviados por você e o suplemento "Vectora: Cidade nas Nuvens" (Jambô); o estilo de cada bairro (cores, construções) foi tirado das imagens e precisa ser conferido no livro.',
    kinds: [
      KindWeight(_K.tallHouse, 4),
      KindWeight(_K.timber, 4),
      KindWeight(_K.manor, 1.5),
      KindWeight(_K.tower, 1),
    ],
    oval: true,
    ovalRatio: 1,
    island: true,
    centerWater: false,
    statueRadius: 4.4,
    minTiles: 96,
    noZone: true,
    noLandmark: true,
    walls: true,
    wallStone: Color(0xFFEFEDE6),
    wallRoof: Color(0xFF3E8F6B),
    floating: true,
    defaultMode: SettlementMode.cityOnly,
    gates: [
      GateSpec('Portão Norte', 0, -1),
      GateSpec('Portão Leste', 1, 0),
      GateSpec('Portão Sul', 0, 1),
      GateSpec('Portão Oeste', -1, 0),
    ],
    districts: [
      DistrictSpec(
        name: 'Magus',
        u: -0.5,
        v: -0.5,
        kinds: [
          KindWeight(_K.tower, 3),
          KindWeight(_K.manor, 3),
          KindWeight(_K.temple, 1),
        ],
        wallColors: [Color(0xFFF4F2EC), Color(0xFFE9ECEF)],
        roofColors: [Color(0xFF3E8F6B), Color(0xFF2F7A6A), Color(0xFF5E86C2)],
        names: {
          _K.tower: ['Torre arcana', 'Academia de magia', 'Observatório'],
          _K.manor: ['Casa de magos', 'Loja de itens mágicos', 'Biblioteca arcana'],
          _K.temple: ['Templo de Wynna'],
        },
        filler: [
          PropWeight(_P.elfLamp, 3),
          PropWeight(_P.tree, 2),
          PropWeight(_P.statue, 1),
          PropWeight(_P.banner, 1),
        ],
      ),
      DistrictSpec(
        name: 'Bara',
        u: 0.5,
        v: -0.5,
        kinds: [
          KindWeight(_K.timber, 4),
          KindWeight(_K.tallHouse, 3),
        ],
        wallColors: [Color(0xFFF0E2C6), Color(0xFFE7D2AE)],
        roofColors: [Color(0xFFB0472F), Color(0xFF9C3E2E), Color(0xFFC0613C)],
        trees: [PropType.sakura],
        names: {
          _K.timber: ['Loja', 'Mercador de especiarias', 'Casa de câmbio', 'Taverna das Nuvens'],
          _K.tallHouse: ['Casa de comércio', 'Armazém', 'Casa de guilda'],
        },
        filler: [
          PropWeight(_P.stall, 4),
          PropWeight(_P.crate, 2),
          PropWeight(_P.barrel, 2),
          PropWeight(_P.sakura, 1.5),
        ],
      ),
      DistrictSpec(
        name: 'Mucro',
        u: -0.5,
        v: 0.5,
        kinds: [
          KindWeight(_K.tallHouse, 4),
          KindWeight(_K.timber, 2),
        ],
        wallColors: [Color(0xFF8E8A82), Color(0xFF7A766E), Color(0xFF9A948A)],
        roofColors: [Color(0xFF3B3B3F), Color(0xFF4A3F3A), Color(0xFF5A2E2E)],
        names: {
          _K.tallHouse: ['Sobrado', 'Casa de penhores', 'Covil', 'Armazém fechado'],
          _K.timber: ['Taverna escura', 'Mercado Negro', 'Casa de jogo'],
        },
        filler: [
          PropWeight(_P.crate, 3),
          PropWeight(_P.barrel, 3),
          PropWeight(_P.lamp, 1),
        ],
      ),
      DistrictSpec(
        name: 'Numen',
        u: 0.5,
        v: 0.5,
        kinds: [
          KindWeight(_K.timber, 3),
          KindWeight(_K.cottage, 2),
          KindWeight(_K.temple, 1.5),
        ],
        wallColors: [Color(0xFFF2E6CC), Color(0xFFE9D9B8)],
        roofColors: [Color(0xFFD9A441), Color(0xFFB98A3A), Color(0xFF8A5E3C)],
        trees: [PropType.sakura, PropType.tree],
        names: {
          _K.timber: ['Estalagem', 'Casa de família', 'Hospedaria'],
          _K.cottage: ['Casa', 'Chalé'],
          _K.temple: ['Templo', 'Santuário'],
        },
        filler: [
          PropWeight(_P.sakura, 3),
          PropWeight(_P.tree, 2),
          PropWeight(_P.bush, 2),
        ],
      ),
    ],
    names: {
      _K.tower: ['Torre arcana'],
      _K.timber: ['Loja de itens mágicos', 'Mercador', 'Taverna das Nuvens'],
    },
    terrain: TerrainPalette(
      grassA: Color(0xFF9CC77E),
      grassB: Color(0xFF92BD74),
      road: Color(0xFFD9D3C4),
      plaza: Color(0xFFE6E0D2),
      soil: Color(0xFF8C7B68),
    ),
    filler: [
      PropWeight(_P.stall, 2),
      PropWeight(_P.banner, 2),
      PropWeight(_P.crate, 1),
      PropWeight(_P.barrel, 1),
    ],
    street: [
      PropWeight(_P.lamp, 3),
      PropWeight(_P.banner, 2),
      PropWeight(_P.stall, 1)
    ],
  );

  static const t20Port = SettlementType(
    id: 'porto',
    // Malpetrim, "terra de heróis": aventureiros de todas as raças; elfos (inclusive do mar) e
    // minotauros presentes (Tapista), humanos maioria.
    population: [PropWeight(_P.raceHuman, 55), PropWeight(_P.raceElf, 10), PropWeight(_P.raceMinotaur, 8), PropWeight(_P.raceDwarf, 7), PropWeight(_P.raceHalfling, 5), PropWeight(_P.raceGoblin, 4), PropWeight(_P.raceMermaid, 3), PropWeight(_P.raceQareen, 3), PropWeight(_P.raceDahllan, 2), PropWeight(_P.raceLefou, 2), PropWeight(_P.raceTrog, 1)],
    name: 'Malpetrim (cidade-porto)',
    lore:
        'Malpetrim, "a Cidade dos Heróis", porto na costa sudoeste e um dos pontos de parada de Vectora. Segue o mapa oficial: muralha do Portão Principal (oeste) ao Portão Sudeste, com o Portão Norte e o Portão Noroeste; um rio desce do norte e se divide em dois canais dentro da cidade; a cidade baixa é densa junto ao Porto de Malpetrim, com o Mercado, o Templo de Marah, a Arena de Malpetrim e as estalagens do Macaco Empalhado e da Águia Dourada; ao norte, casas espaçadas; a leste do rio, as Granjas dos Armadores. Mata ao norte e a sudeste. Fonte: mapas enviados por você; confirmar no livro (a busca na internet não achou descrição).',
    wallColors: [
      Color(0xFFE6E0D2),
      Color(0xFFCFDCE0),
      Color(0xFFE9CFA6),
      Color(0xFFBFCFC6)
    ],
    roofColors: [Color(0xFF4F6E8A), Color(0xFF8E4A3C), Color(0xFF5E6B73)],
    kinds: [
      KindWeight(_K.timber, 4),
      KindWeight(_K.tallHouse, 3),
      KindWeight(_K.cottage, 3),
      KindWeight(_K.manor, 1),
      KindWeight(_K.barn, 1),
      KindWeight(_K.temple, 0.5),
    ],
    noLandmark: true,
    names: {
      _K.barn: ['Armazém', 'Estaleiro', 'Depósito de redes'],
      _K.tower: ['Farol'],
      _K.timber: [
        'Taverna do Porto',
        'Mercado de peixe',
        'Guilda dos mercadores',
        'Estalagem do Marujo'
      ],
    },
    water: WaterLayout.coast,
    farmShare: .15,
    filler: [
      PropWeight(_P.barrel, 3),
      PropWeight(_P.crate, 3),
      PropWeight(_P.cart, 1),
      PropWeight(_P.tree, 1.5),
      PropWeight(_P.bush, 1.5),
      PropWeight(_P.dog, 1),
      PropWeight(_P.chicken, 1)
    ],
    street: [
      PropWeight(_P.lamp, 3),
      PropWeight(_P.barrel, 2),
      PropWeight(_P.crate, 2)
    ],
    layout: MapLayout.malpetrim,
    minTiles: 80,
    noZone: true,
    extras: [ExtraBuilding(_K.arena, 'Arena de Malpetrim')],
    defaultMode: SettlementMode.cityOnly,
  );

  static const t20Frontier = SettlementType(
    id: 'oeste',
    // Smokestone (Petrynia, Tormenta Wiki): humanos ~80-85%, goblins 5%, hynne 5%, minotauros.
    population: [PropWeight(_P.raceHuman, 82), PropWeight(_P.raceGoblin, 6), PropWeight(_P.raceHalfling, 5), PropWeight(_P.raceMinotaur, 4), PropWeight(_P.raceDwarf, 2), PropWeight(_P.raceLefou, 1)],
    era: Era.western,
    name: 'Smokestone (cidade sem lei)',
    lore:
        'Smokestone, cidade de clima de Velho Oeste em Petrynia, terra de pistoleiros e mercenários. Segue o mapa oficial: o povoado de ruas paralelas e saloons fica aos pés de grandes rochas vermelhas (uma mesa enorme a noroeste, pilares ao norte e a leste, uma agulha a oeste), cercado por uma estrada de terra; curral e cemitério ao sul; a oeste, o rio, os moinhos-bomba e as hortas. No mapa de Arton fica entre Tiberus e Nova Malpetrim. Fonte: mapas enviados por você; confirmar no livro.',
    wallColors: [
      Color(0xFFC9A06A),
      Color(0xFFB98A55),
      Color(0xFFD6B484),
      Color(0xFF9C6F43),
      Color(0xFFE0C79A)
    ],
    roofColors: [Color(0xFF7A5A3C), Color(0xFF5E4630), Color(0xFF8A6A4A)],
    kinds: [
      KindWeight(_K.saloon, 6),
      KindWeight(_K.house, 3),
      KindWeight(_K.barn, 1),
    ],
    noLandmark: true,
    names: {
      _K.saloon: [
        'Saloon',
        'Banco',
        'Escritório do xerife',
        'Ferraria',
        'Armazém geral',
        'Hotel',
        'Casa de apostas'
      ],
      _K.house: ['Casa', 'Cabana', 'Barraca'],
      _K.barn: ['Estábulo', 'Curral'],
    },
    terrain: TerrainPalette(
      grassA: Color(0xFFE6CA93),
      grassB: Color(0xFFDDBE82),
      road: Color(0xFFCDA770),
      plaza: Color(0xFFEBD6A4),
      soil: Color(0xFF9C6F43),
    ),
    farmShare: .2,
    crops: [CropType.corn, CropType.cotton, CropType.pasture],
    filler: [
      PropWeight(_P.cactus, 4),
      PropWeight(_P.barrel, 2),
      PropWeight(_P.crate, 1),
      PropWeight(_P.horse, 2),
      PropWeight(_P.cart, 1),
      PropWeight(_P.hay, 1),
      PropWeight(_P.dog, 1)
    ],
    street: [
      PropWeight(_P.horse, 2),
      PropWeight(_P.barrel, 2),
      PropWeight(_P.cactus, 2),
      PropWeight(_P.lamp, 1)
    ],
    layout: MapLayout.smokestone,
    mapRatio: .62,
    minTiles: 80,
    noZone: true,
    defaultMode: SettlementMode.cityOnly,
  );

  static const t20Farmland = SettlementType(
    id: 'celeiro',
    // Sambúrdia, o Celeiro de Arton: camponeses humanos, hynne e dahllan.
    population: [PropWeight(_P.raceHuman, 78), PropWeight(_P.raceHalfling, 10), PropWeight(_P.raceDahllan, 6), PropWeight(_P.raceDwarf, 3), PropWeight(_P.raceGoblin, 3)],
    name: 'Sambúrdia (terras agrícolas)',
    lore:
        'Sambúrdia, o "celeiro de Arton": campos e sítios entre grandes florestas, cortados pelo Rio Sambúrdia, que desce até o mar. A capital murada fica a oeste; as Montanhas Sanguinárias, a nordeste; e há a Floresta das Escamas Verdes, a Torre de Erebo, a Tumba de Mokk Amhor, o Refúgio da Donzela, o Balneário de Zannar, o Formigueiro, o Buraco de Vectora e as Cataratas de Sambúrdia. Fonte: mapa do reino enviado por você; confirmar no livro.',
    kinds: [
      KindWeight(_K.cottage, 5),
      KindWeight(_K.timber, 2),
      KindWeight(_K.barn, 2),
      KindWeight(_K.windmill, 1.5),
      KindWeight(_K.temple, 0.6),
      KindWeight(_K.tower, 0.05),
      KindWeight(_K.manor, 0.05),
    ],
    landmark: _K.castle,
    defaultMode: SettlementMode.cityWithFarms,
    farmShare: .9,
    crops: [
      CropType.wheat,
      CropType.corn,
      CropType.vineyard,
      CropType.orchard,
      CropType.vegetables,
      CropType.pasture
    ],
    layout: MapLayout.samburdia,
    mapRatio: .75,
    minTiles: 88,
    noZone: true,
  );

  static const t20Fortress = SettlementType(
    id: 'fortaleza',
    // Yuden, reino militar: humanos quase só, com anões e minotauros nas tropas.
    population: [PropWeight(_P.raceHuman, 85), PropWeight(_P.raceDwarf, 6), PropWeight(_P.raceMinotaur, 6), PropWeight(_P.raceLefou, 3)],
    name: 'Cidade militar (como Yuden)',
    lore:
        'Yuden é o reino do "Exército com uma Nação", com capital em Kannilar; mais tarde virou a Supremacia Purista (fonte: O Cenário e T20 v1.1; confirmar no livro). Cidade murada, quartéis, torres de vigia e estandartes.',
    wallColors: [Color(0xFFCFC9BC), Color(0xFFBDB6A8), Color(0xFFD6D1C4)],
    roofColors: [Color(0xFF5A6677), Color(0xFF6B3F3A), Color(0xFF44505F)],
    kinds: [
      KindWeight(_K.manor, 3),
      KindWeight(_K.timber, 2),
      KindWeight(_K.tower, .8),
      KindWeight(_K.cottage, 2),
      KindWeight(_K.temple, .5),
    ],
    landmark: _K.castle,
    names: {
      _K.manor: ['Quartel', 'Armaria', 'Casa de oficiais'],
      _K.tower: ['Torre de vigia', 'Torre de arqueiros'],
      _K.timber: ['Intendência', 'Taverna dos soldados', 'Ferraria militar'],
    },
    walls: true,
    divisions: [Division.citadel],
    farmShare: .1,
    filler: [
      PropWeight(_P.banner, 2),
      PropWeight(_P.barrel, 2),
      PropWeight(_P.crate, 2),
      PropWeight(_P.statue, .5),
      PropWeight(_P.tree, 1)
    ],
    street: [
      PropWeight(_P.banner, 4),
      PropWeight(_P.lamp, 2),
      PropWeight(_P.statue, .5)
    ],
    noZone: true,
    buildDensity: .75,
  );

  static const t20Oriental = SettlementType(
    id: 'oriental',
    // Nitamu-ra: refugiados humanos de Tamu-ra (samurais e daymios), pouquíssimos de fora.
    population: [PropWeight(_P.raceHuman, 95), PropWeight(_P.raceGoblin, 2), PropWeight(_P.raceKliren, 2), PropWeight(_P.raceElf, 1)],
    name: 'Nitamu-ra (cidade oriental)',
    lore:
        'Nitamu-ra e o estilo tamuriano (Tamu-ra é a terra oriental de Arton; o bairro de Nitamu-ra fica em Valkaria): ruas apertadas de casas de chá, dojôs, casas de banho e residências de paredes brancas e madeira escura, telhados curvos, pagodes de vários andares, lanternas de pedra, portais torii e cerejeiras em flor.',
    wallColors: [Color(0xFFF3EBDD), Color(0xFFE9DFC9), Color(0xFFD9CBB0)],
    roofColors: [
      Color(0xFF2F3A44),
      Color(0xFF8E2B2B),
      Color(0xFF3A2F2A),
      Color(0xFF5B2A2A)
    ],
    kinds: [
      KindWeight(_K.eastHouse, 10),
      KindWeight(_K.pagoda, 1.6),
    ],
    trees: [_P.sakura, _P.sakura, _P.sakura, _P.pine],
    farmHouse: _K.eastHouse,
    farmBarn: _K.eastHouse,
    landmark: _K.pagoda,
    names: {
      _K.pagoda: ['Pagode', 'Grande pagode', 'Santuário do dragão'],
      _K.eastHouse: ['Casa de chá', 'Dojô', 'Casa de banho', 'Residência', 'Mercado coberto'],
      _K.temple: ['Pagode', 'Santuário', 'Grande pagode'],
      _K.manor: ['Casa de chá', 'Dojo', 'Residência nobre'],
      _K.cottage: ['Casa', 'Casa de artesão', 'Casa de pescador'],
      _K.timber: ['Casa de chá', 'Mercado', 'Casa de banho'],
      _K.tower: ['Torre de vigia', 'Torre do sino'],
    },
    terrain: TerrainPalette(
      grassA: Color(0xFFB9D6A2),
      grassB: Color(0xFFAECB96),
      road: Color(0xFFD8CBB0),
      plaza: Color(0xFFE6DCC6),
      soil: Color(0xFF9A7B58),
    ),
    crops: [
      CropType.rice,
      CropType.vegetables,
      CropType.orchard,
      CropType.pasture
    ],
    farmShare: .45,
    filler: [
      PropWeight(_P.sakura, 2),
      PropWeight(_P.toro, 2),
      PropWeight(_P.torii, .4),
      PropWeight(_P.bush, 1),
      PropWeight(_P.barrel, .6),
    ],
    street: [
      PropWeight(_P.toro, 3),
      PropWeight(_P.lamp, 2),
      PropWeight(_P.banner, 1)
    ],
    defaultMode: SettlementMode.cityWithFarms,
    noZone: true,
    buildDensity: .66,
    cityShare: .72,
  );

  static const t20Elven = SettlementType(
    id: 'elfica',
    // Lenórienn: a cidade élfica (hoje ocupada pela Aliança Negra, segundo a wiki); elfos.
    population: [PropWeight(_P.raceElf, 90), PropWeight(_P.raceHuman, 5), PropWeight(_P.raceDahllan, 3), PropWeight(_P.raceSylph, 2)],
    name: 'Lenórienn (cidade élfica)',
    lore:
        'Lenórienn, a antiga capital élfica (o reino caiu na guerra contra os hobgoblins; confirmar a história no T20). Estilo élfico e orgânico: construções integradas às árvores, mármore branco, telhados verdes em forma de folha e arquitetura delicada. Aqui: árvores-moradas com casas de mármore em plataformas, torres esguias com anéis dourados, casas élficas, lanternas verdes e muita mata entre as ruas, em volta de um lago.',
    wallColors: [Color(0xFFF4F1E8), Color(0xFFE8EEE6), Color(0xFFDDE8DD)],
    roofColors: [
      Color(0xFF4F8F6A),
      Color(0xFF3E7F6B),
      Color(0xFF6BA37A),
      Color(0xFF2F6F63)
    ],
    kinds: [
      KindWeight(_K.elfHouse, 6),
      KindWeight(_K.elfTree, 3),
      KindWeight(_K.elfTower, .7),
    ],
    farmHouse: _K.elfHouse,
    farmBarn: _K.elfHouse,
    landmark: _K.elfTree,
    names: {
      _K.elfHouse: ['Casa élfica', 'Salão de canto', 'Ateliê de arcos', 'Casa de poetas'],
      _K.elfTree: ['Árvore-morada', 'Casa na grande árvore', 'Salão das copas', 'Morada do conselho'],
      _K.elfTower: ['Torre de cristal', 'Torre dos magos', 'Mirante das estrelas'],
      _K.temple: ['Santuário de Glórienn', 'Santuário élfico'],
      _K.cottage: ['Casa na árvore', 'Casa élfica', 'Morada'],
      _K.timber: ['Salão de canto', 'Casa de ervas', 'Galeria de arte'],
      _K.tower: ['Torre de cristal', 'Mirante'],
      _K.manor: ['Casa de conselho', 'Residência nobre'],
    },
    defaultMode: SettlementMode.cityWithFarms,
    water: WaterLayout.lake,
    terrain: TerrainPalette(
      grassA: Color(0xFF86BC8A),
      grassB: Color(0xFF7AB07E),
      road: Color(0xFFDCD2B4),
      plaza: Color(0xFFEDE6CF),
      soil: Color(0xFF6E5A3E),
    ),
    crops: [CropType.orchard, CropType.vegetables, CropType.pasture],
    farmShare: .3,
    filler: [
      PropWeight(_P.tree, 3),
      PropWeight(_P.elfLamp, 2.5),
      PropWeight(_P.bush, 2),
      PropWeight(_P.statue, .4),
    ],
    street: [
      PropWeight(_P.elfLamp, 4),
      PropWeight(_P.banner, 1)
    ],
    noZone: true,
    buildDensity: .78,
    cityShare: .8,
  );

  static const t20Goblin = SettlementType(
    id: 'engenhoca',
    // Distrito de engenhocas: goblins e anões inventores, com kliren.
    population: [PropWeight(_P.raceGoblin, 45), PropWeight(_P.raceDwarf, 35), PropWeight(_P.raceKliren, 12), PropWeight(_P.raceHuman, 8)],
    name: 'Distrito de engenhocas (goblins e anões)',
    lore:
        'Inovação tecnológica estilo steampunk: oficinas, engrenagens, becos industriais, esgotos e fumaça de carvão (descrição de estilos enviada por você; confirmar no T20 quais cidades se encaixam). Arte nova pendente: engrenagens, chaminés e fumaça; por ora usa oficinas e torres de tom escuro.',
    wallColors: [
      Color(0xFF6E5B4A),
      Color(0xFF5F5A55),
      Color(0xFF7A6A58),
      Color(0xFF8A7660)
    ],
    roofColors: [
      Color(0xFF3B3B3F),
      Color(0xFF8A5A33),
      Color(0xFF4A3F3A),
      Color(0xFF6E4A2E)
    ],
    kinds: [
      KindWeight(_K.workshop, 1),
    ],
    farmHouse: _K.workshop,
    farmBarn: _K.workshop,
    landmark: _K.workshop,
    names: {
      _K.workshop: ['Oficina de engenhocas', 'Fundição', 'Casa de engrenagens', 'Laboratório goblin', 'Forja dwarven'],
      _K.tower: ['Torre de engrenagens', 'Grande chaminé'],
      _K.timber: [
        'Oficina de engenhoca',
        'Forja goblin',
        'Loja de peças',
        'Taverna do vapor'
      ],
      _K.manor: ['Fábrica de engrenagens', 'Fundição'],
      _K.barn: ['Galpão', 'Depósito de carvão'],
      _K.cottage: ['Casa de operário', 'Toca', 'Barraco'],
    },
    defaultMode: SettlementMode.cityWithFarms,
    terrain: TerrainPalette(
      grassA: Color(0xFF8F9A78),
      grassB: Color(0xFF858F6E),
      road: Color(0xFF8A8580),
      plaza: Color(0xFF9C968C),
      soil: Color(0xFF5E5048),
    ),
    farmShare: .1,
    filler: [
      PropWeight(_P.crate, 3),
      PropWeight(_P.barrel, 3),
      PropWeight(_P.cart, 2),
      PropWeight(_P.dog, .5),
      PropWeight(_P.bush, .6)
    ],
    street: [
      PropWeight(_P.lamp, 3),
      PropWeight(_P.barrel, 2),
      PropWeight(_P.crate, 2)
    ],
    buildDensity: .88,
    cityShare: .72,
  );

  static const t20Forest = SettlementType(
    id: 'floresta',
    // Vila na floresta: humanos, dahllan e hynne.
    population: [PropWeight(_P.raceHuman, 60), PropWeight(_P.raceDahllan, 18), PropWeight(_P.raceHalfling, 12), PropWeight(_P.raceElf, 10)],
    name: 'Vila na floresta',
    lore:
        'Povoado pequeno numa clareira, cercado de mata fechada e ligado ao mundo por trilhas de terra. Serve para vilas de caçadores, druidas e madeireiros em qualquer reino (tipo genérico, não vem de um local do livro).',
    kinds: [
      KindWeight(_K.cottage, 6),
      KindWeight(_K.timber, 1.5),
      KindWeight(_K.barn, 1),
      KindWeight(_K.temple, .4),
    ],
    noLandmark: true,
    names: {
      _K.cottage: ['Cabana', 'Casa de lenhador', 'Casa de caçador'],
      _K.timber: ['Taverna da clareira', 'Serraria', 'Ferraria'],
      _K.barn: ['Estábulo', 'Depósito de lenha'],
      _K.temple: ['Santuário de Allihanna', 'Altar da natureza'],
    },
    defaultMode: SettlementMode.forestOnly,
    water: WaterLayout.lake,
    terrain: TerrainPalette(
      grassA: Color(0xFF7DB070),
      grassB: Color(0xFF72A664),
      road: Color(0xFFC9B58A),
      plaza: Color(0xFFD8CCA8),
      soil: Color(0xFF6E5A3E),
    ),
    farmShare: .3,
    filler: [
      PropWeight(_P.tree, 4),
      PropWeight(_P.pine, 2),
      PropWeight(_P.bush, 3),
      PropWeight(_P.hay, .6),
      PropWeight(_P.barrel, .6),
      PropWeight(_P.dog, .6)
    ],
  );

  static const t20Fey = SettlementType(
    id: 'feerica',
    // Pondsmânia (Enciclopédia de Arton): quase só fadas e criaturas mágicas; vilas humanas
    // raras e enfeitiçadas.
    population: [PropWeight(_P.raceSylph, 55), PropWeight(_P.raceDahllan, 25), PropWeight(_P.raceHuman, 12), PropWeight(_P.raceElf, 8)],
    name: 'Pondsmânia (floresta feérica)',
    lore:
        'Pondsmânia, o reino das fadas: uma floresta mágica onde nada obedece a regra nenhuma (confirmar no T20). Casas de cogumelo de todos os tamanhos e cores, chalés tortos, torres de flor, flores gigantes, luzes de fada flutuando, poças e lagos espalhados e ruas que se perdem. Também pode ter área da Tormenta.',
    wallColors: [
      Color(0xFFF2D9E6),
      Color(0xFFE3D5F0),
      Color(0xFFD5EBDD),
      Color(0xFFF6E7B8)
    ],
    roofColors: [
      Color(0xFFB04A6E),
      Color(0xFF7B5BB0),
      Color(0xFFD9703A),
      Color(0xFF4A9A8A)
    ],
    kinds: [
      KindWeight(_K.mushroom, 7),
      KindWeight(_K.cottage, 2),
      KindWeight(_K.elfTower, .8),
    ],
    farmHouse: _K.mushroom,
    farmBarn: _K.mushroom,
    noLandmark: true,
    names: {
      _K.mushroom: ['Casa de cogumelo', 'Toca de fada', 'Casinha de orvalho'],
      _K.cottage: ['Casa de cogumelo', 'Toca de fada', 'Chalé florido'],
      _K.timber: ['Casa de ervas', 'Salão das fadas'],
      _K.tower: ['Torre de flor', 'Mirante'],
      _K.elfTower: ['Torre de flor', 'Mirante das fadas', 'Torre torta'],
    },
    defaultMode: SettlementMode.cityWithFarms,
    terrain: TerrainPalette(
      grassA: Color(0xFF78C28A),
      grassB: Color(0xFF6BB87E),
      road: Color(0xFFE6D3A8),
      plaza: Color(0xFFF1E4C0),
      soil: Color(0xFF7A5E6E),
    ),
    filler: [
      PropWeight(_P.giantFlower, 4),
      PropWeight(_P.fairyLight, 3),
      PropWeight(_P.tree, 2),
      PropWeight(_P.bush, 2),
    ],
    street: [
      PropWeight(_P.fairyLight, 3),
      PropWeight(_P.giantFlower, 2),
    ],
    chaotic: true,
    noZone: true,
    crops: [],
    farmShare: 0,
  );

  static const t20Norba = SettlementType(
    id: 'norba',
    // Nova Ghondriann (Tormenta Wiki): humanos 92%, hynne 3%, outros 5%.
    population: [PropWeight(_P.raceHuman, 92), PropWeight(_P.raceHalfling, 3), PropWeight(_P.raceDwarf, 2), PropWeight(_P.raceDahllan, 2), PropWeight(_P.raceGoblin, 1)],
    name: 'Norba (vila na mata)',
    lore:
        'Norba, vila de Sambúrdia numa clareira cercada de mata fechada. Segue o mapa oficial: quatro estradas de terra saem da praça (uma delas para Sambúrdia), talhões coloridos a oeste, um bosque dentro da clareira e o lago a sudeste. Lugares da legenda: Posto Avançado de Norba, Prefeitura, O Pônei Rústico, Templo, Pena Centrífuga, Ferraria, Carpintaria, Herbalista e Pescados do Lago (nomes lidos do mapa; confirmar no livro).',
    kinds: [
      KindWeight(_K.cottage, 4),
      KindWeight(_K.timber, 3),
      KindWeight(_K.temple, .3),
      KindWeight(_K.manor, .2),
      KindWeight(_K.tower, .1),
    ],
    noLandmark: true,
    noZone: true,
    layout: MapLayout.norba,
    minTiles: 64,
    defaultMode: SettlementMode.cityWithFarms,
    names: {
      _K.cottage: ['Casa', 'Chalé', 'Casa do lenhador'],
      _K.timber: ['Casa de família', 'Oficina', 'Estalagem'],
    },
    crops: [CropType.wheat, CropType.vegetables, CropType.corn],
    terrain: TerrainPalette(
      grassA: Color(0xFF9CC77A),
      grassB: Color(0xFF92BD6F),
      road: Color(0xFFC9B58A),
      plaza: Color(0xFFD8CBA8),
      soil: Color(0xFF7A5E3E),
    ),
  );

  static const t20FreeCity = SettlementType(
    id: 'cidade_livre',
    name: 'Cidade ou vila livre (com área da Tormenta)',
    lore:
        'Cidade ou vila genérica de Arton para a sua campanha: não segue um local do livro. Cada geração sorteia se é cidade ou vila, a água (rio, lago, costa ou nenhuma), a muralha, o marco, as cores e a mistura de construções. Bairros de enxaimel, sobrados, mansões, templos e torres, rio e bosques em volta, e uma Área da Tormenta por perto (a chuva rubra, os cristais e os lefeu). Às vezes tem castelo e muralha.',
    kinds: [
      KindWeight(_K.timber, 4),
      KindWeight(_K.cottage, 3),
      KindWeight(_K.tallHouse, 2),
      KindWeight(_K.manor, 1.2),
      KindWeight(_K.temple, 1),
      KindWeight(_K.tower, .8),
      KindWeight(_K.church, .3),
      KindWeight(_K.barn, .2),
      KindWeight(_K.windmill, .2),
    ],
    landmark: _K.castle,
    landmarkChance: .45,
    wildZone: true,
    defaultMode: SettlementMode.cityWithFarms,
    varied: true,
  );


  static const t20 = [
    t20Capital,
    t20FreeCity,
    t20Floating,
    t20Port,
    t20Frontier,
    t20Farmland,
    t20Fortress,
    t20Oriental,
    t20Elven,
    t20Goblin,
    t20Forest,
    t20Norba,
    t20Fey
  ];

  // ------------------------------------------------------------------ Tales from the Loop
  static const loopMalaren = SettlementType(
    id: 'malaren',
    name: 'Ilhas Mälaren (Suécia, anos 80)',
    lore:
        'As Ilhas Mälaren, a oeste de Estocolmo, cenário principal do livro e da arte de Simon Stålenhag. Segue o mapa oficial da instalação (Riksenergi, 1981): Svartsjölandet, Munsö, Adelsö e Ekerö entre os fiordes do lago Mälaren (Björkfjärden, Prästfjärden, Långtarmen); o reator Bona com as torres de resfriamento em Munsö, sempre visíveis no horizonte com as luzes verdes; o anel do acelerador (o Prim 1 tem cerca de 30 km) e os portões North, East, South e West Gate; a Fábrica de Dävensö; povoados de chalés vermelhos como Stenhamra e Färentuna, matas, campos, balsas e máquinas abandonadas. Fontes: mapa enviado por você, Free League/Modiphius e r/TalesFromtheLoopRPG; confirmar no livro.',
    wallColors: [
      Color(0xFFB4432E),
      Color(0xFFC4583F),
      Color(0xFFD9A441),
      Color(0xFFF2EDE0),
      Color(0xFFE7D08A)
    ],
    roofColors: [Color(0xFF3E3B3A), Color(0xFF5A4A44), Color(0xFF7B3B2E)],
    kinds: [
      KindWeight(_K.faluCabin, 8),
      KindWeight(_K.barn, 1.5),
      KindWeight(_K.modern, 0.6),
      KindWeight(_K.lab, 0.05),
      KindWeight(_K.coolingTower, 0.05),
      KindWeight(_K.warehouse, 0.05),
    ],
    farmHouse: _K.faluCabin,
    farmBarn: _K.barn,
    noLandmark: true,
    names: {
      _K.faluCabin: ['Casa', 'Chalé', 'Casa de veraneio', 'Casa de família'],
      _K.house: ['Chalé vermelho', 'Casa de madeira', 'Casa de verão'],
      _K.barn: ['Garagem', 'Oficina', 'Galpão de barcos'],
    },
    water: WaterLayout.lake,
    farmShare: .45,
    crops: [
      CropType.wheat,
      CropType.pasture,
      CropType.vegetables,
      CropType.corn
    ],
    layout: MapLayout.malaren,
    mapRatio: .65,
    minTiles: 120,
    noZone: true,
    defaultMode: SettlementMode.cityOnly,
  );

  static const loopBoulder = SettlementType(
    id: 'boulder',
    name: 'Boulder City (Nevada, anos 80)',
    lore:
        'Boulder City, cenário americano do livro (no verso do mapa oficial): cidade construída em 1931 para os operários da Represa Hoover, a meia hora de Las Vegas e vizinha do Lago Mead. O traçado em leque parte do prédio do Bureau of Reclamation, com o parque Wilbur Square em frente; casas térreas, posto, escola, fliperama e locadora no centro; a nordeste o Lago Mead, a represa no Black Canyon e o Rio Colorado; no deserto, a instalação americana do Loop com as torres de resfriamento, robôs e postes. Fontes: descrição enviada por você, mapa oficial e história real de Boulder City; confirmar no livro.',
    wallColors: [
      Color(0xFFEAD9B8),
      Color(0xFFD9C29A),
      Color(0xFFE9E1D0),
      Color(0xFFC9B79A)
    ],
    roofColors: [Color(0xFF9B6B4A), Color(0xFF7A6A5A), Color(0xFFB9553A)],
    kinds: [
      KindWeight(_K.ranch, 6),
      KindWeight(_K.modern, 3),
      KindWeight(_K.house, 0.5),
      KindWeight(_K.block, 0.2),
      KindWeight(_K.lab, 0.05),
      KindWeight(_K.coolingTower, 0.05),
      KindWeight(_K.dam, 0.01),
    ],
    farmHouse: _K.ranch,
    farmBarn: _K.barn,
    noLandmark: true,
    names: {
      _K.ranch: ['Casa', 'Casa de aposentado', 'Casa de operário da represa'],
      _K.house: ['Casa', 'Casa de aposentado', 'Casa de operário da represa'],
      _K.modern: [
        'Loja de conveniência',
        'Fliperama',
        'Escola',
        'Posto de gasolina',
        'Locadora de fitas'
      ],
    },
    terrain: TerrainPalette(
      grassA: Color(0xFFE2CF9F),
      grassB: Color(0xFFD9C48F),
      road: Color(0xFFB9B3A8),
      plaza: Color(0xFFE9DEC0),
      soil: Color(0xFF9A7B58),
    ),
    farmShare: .15,
    crops: [CropType.cotton, CropType.pasture, CropType.vegetables],
    filler: [
      PropWeight(_P.cactus, 3),
      PropWeight(_P.car, 3),
      PropWeight(_P.dish, .8),
      PropWeight(_P.waterTower, .3),
      PropWeight(_P.dog, 1),
      PropWeight(_P.robot, .6)
    ],
    street: [
      PropWeight(_P.powerPole, 4),
      PropWeight(_P.car, 2),
      PropWeight(_P.lamp, 1)
    ],
    layout: MapLayout.boulder,
    mapRatio: .75,
    minTiles: 96,
    noZone: true,
    defaultMode: SettlementMode.cityOnly,
  );

  static const loopForest = SettlementType(
    id: 'floresta_malaren',
    name: 'Floresta de Mälaren',
    lore:
        'Chalés vermelhos isolados entre pinheiros e lagos, longe da cidade, como nas ilhas de Mälaren (fonte: premissa do cenário e Free League; confirmar no livro). Trilhas de terra, postes de luz e, ao longe, a sombra do Loop.',
    wallColors: [
      Color(0xFFB4432E),
      Color(0xFFC4583F),
      Color(0xFFD9A441),
      Color(0xFFF2EDE0)
    ],
    roofColors: [Color(0xFF3E3B3A), Color(0xFF5A4A44), Color(0xFF7B3B2E)],
    kinds: [
      KindWeight(_K.faluCabin, 8),
      KindWeight(_K.barn, 1.2),
    ],
    farmHouse: _K.faluCabin,
    farmBarn: _K.barn,
    noLandmark: true,
    names: {
      _K.faluCabin: ['Chalé', 'Cabana de pesca', 'Casa de verão'],
      _K.house: ['Chalé vermelho', 'Casa de verão', 'Cabana no lago'],
      _K.barn: ['Galpão de barcos', 'Garagem', 'Oficina'],
    },
    defaultMode: SettlementMode.forestOnly,
    water: WaterLayout.lake,
    terrain: TerrainPalette(
      grassA: Color(0xFF8DB77A),
      grassB: Color(0xFF82AC70),
      road: Color(0xFFC8B995),
      plaza: Color(0xFFD9D0B2),
      soil: Color(0xFF7A6A52),
    ),
    farmShare: .25,
    filler: [
      PropWeight(_P.pine, 5),
      PropWeight(_P.tree, 2),
      PropWeight(_P.bush, 2),
      PropWeight(_P.powerPole, .8),
      PropWeight(_P.car, .4),
      PropWeight(_P.dog, .6),
      PropWeight(_P.robot, .3)
    ],
    street: [PropWeight(_P.powerPole, 4), PropWeight(_P.car, 1)],
  );

  static const loopFarms = SettlementType(
    id: 'fazendas_loop',
    name: 'Fazendas ao redor do Loop',
    lore:
        'Fazendas próximas ao Loop: campos, silos, celeiros e linhas de energia, com gyrobots abandonados nas plantações e torres ao longe. Combina com a premissa de máquinas estranhas no campo (fonte: premissa do cenário; confirmar locais no livro).',
    kinds: [
      KindWeight(_K.faluCabin, 3),
      KindWeight(_K.barn, 3),
    ],
    farmHouse: _K.faluCabin,
    farmBarn: _K.barn,
    noLandmark: true,
    defaultMode: SettlementMode.farmsOnly,
    farmShare: .9,
    crops: [
      CropType.wheat,
      CropType.corn,
      CropType.pasture,
      CropType.vegetables
    ],
    filler: [
      PropWeight(_P.robot, .7),
      PropWeight(_P.tractor, .5),
      PropWeight(_P.powerPole, 2),
      PropWeight(_P.pine, 2),
      PropWeight(_P.cow, 1),
      PropWeight(_P.horse, .5),
      PropWeight(_P.hay, 2),
      PropWeight(_P.crate, .8),
      PropWeight(_P.freighter, .25)
    ],
    street: [PropWeight(_P.powerPole, 5), PropWeight(_P.tractor, 1)],
  );

  static const loopCampus = SettlementType(
    id: 'campus',
    name: 'Instalação do Loop',
    lore:
        'O complexo de pesquisa e seu entorno cercado: laboratórios, torres de resfriamento, antenas e carros do pessoal; gravidade estranha e máquinas antigas (fonte: premissa do cenário).',
    wallColors: [Color(0xFFE4E6E4), Color(0xFFD6DAD8)],
    roofColors: [Color(0xFF6A727B), Color(0xFF8D9AA3)],
    kinds: [
      KindWeight(_K.lab, 3),
      KindWeight(_K.modern, 2),
      KindWeight(_K.block, 1),
      KindWeight(_K.coolingTower, 1.2),
    ],
    landmark: _K.lab,
    farmHouse: _K.modern,
    farmBarn: _K.warehouse,
    names: {
      _K.lab: [
        'Torre de resfriamento',
        'Laboratório do Loop',
        'Central de dados',
        'Sala do reator'
      ],
      _K.modern: ['Alojamento', 'Refeitório', 'Portaria', 'Garagem'],
    },
    defaultMode: SettlementMode.cityOnly,
    terrain: TerrainPalette(
      grassA: Color(0xFFBFD3B0),
      grassB: Color(0xFFB5CBA5),
      road: Color(0xFFB8BBBC),
      plaza: Color(0xFFD6D9D8),
      soil: Color(0xFF8E8A82),
    ),
    filler: [
      PropWeight(_P.dish, 2),
      PropWeight(_P.car, 2),
      PropWeight(_P.robot, 1.5),
      PropWeight(_P.powerPole, 1),
      PropWeight(_P.pine, 1),
      PropWeight(_P.freighter, .4)
    ],
    street: [
      PropWeight(_P.powerPole, 3),
      PropWeight(_P.lamp, 2),
      PropWeight(_P.car, 1.5)
    ],
  );

  static const loopMercer = SettlementType(
    id: 'mercer',
    name: 'Mercer (Ohio, série da Amazon)',
    lore:
        'Mercer, Ohio: a cidade da série Tales from the Loop (Amazon, 2020). Uma cidadezinha do meio-oeste construída em cima do Loop, o Mercer Center for Experimental Physics, onde um acelerador subterrâneo e o orbe negro chamado Eclipse fazem o impossível acontecer. Rua principal com igreja, prefeitura, escola, lanchonete e caixa d’água; casas de madeira; campos de milho, sítios com silo e celeiro; um bosque com robôs abandonados e o lago. Fontes: descrição enviada por você e resenhas da série; a geografia é inventada a partir da série.',
    kinds: [
      KindWeight(_K.house, 6),
      KindWeight(_K.modern, 1.5),
      KindWeight(_K.farmhouse, .5),
      KindWeight(_K.barn, .5),
      KindWeight(_K.silo, .3),
      KindWeight(_K.church, .1),
      KindWeight(_K.block, .1),
      KindWeight(_K.lab, .05),
      KindWeight(_K.coolingTower, .05),
    ],
    noLandmark: true,
    noZone: true,
    layout: MapLayout.mercer,
    mapRatio: .8,
    minTiles: 90,
    defaultMode: SettlementMode.cityOnly,
    wallColors: [
      Color(0xFFF2EDE0),
      Color(0xFFDCE3E6),
      Color(0xFFE9D9B8),
      Color(0xFFC9D6C8)
    ],
    roofColors: [Color(0xFF4A4F55), Color(0xFF6B4A3A), Color(0xFF7A3B2E)],
    names: {
      _K.house: ['Casa', 'Casa de família', 'Casa de madeira'],
      _K.farmhouse: ['Sítio', 'Fazenda'],
    },
    crops: [CropType.corn, CropType.wheat, CropType.pasture],
  );

  static const loop = [
    loopMalaren,
    loopBoulder,
    loopMercer,
    loopFarms,
    loopCampus,
    loopForest
  ];

  // ------------------------------------------------------------------ Call of Cthulhu
  static const cocArkham = SettlementType(
    id: 'arkham',
    name: 'Cidade universitária (como Arkham)',
    lore:
        'Arkham é a cidade da Universidade Miskatonic, inspirada em Salem (fonte: Lovecraft Country/Wikipedia; confirmar no livro). Ruas de pedra, casas de tijolo e telhados de ardósia, mansões antigas, igreja e biblioteca, sempre sob neblina.',
    wallColors: [
      Color(0xFFA5523A),
      Color(0xFF8F4A38),
      Color(0xFFB5654A),
      Color(0xFFC9B79A)
    ],
    roofColors: [Color(0xFF3F4650), Color(0xFF5A4A44), Color(0xFF4A4F55)],
    kinds: [
      KindWeight(_K.gambrel, 6),
      KindWeight(_K.manor, 3),
      KindWeight(_K.church, 1.2),
      KindWeight(_K.tower, 0.6),
    ],
    farmHouse: _K.gambrel,
    farmBarn: _K.barn,
    names: {
      _K.gambrel: ['Casa', 'Casa de professor', 'Casa antiga', 'Pensão'],
      _K.manor: [
        'Universidade Miskatonic',
        'Biblioteca Orne',
        'Casa Antiga',
        'Hospital Santa Maria',
        'Mansão'
      ],
      _K.house: ['Casa', 'Pensão', 'Casa de professor'],
      _K.tower: ['Torre do relógio', 'Torre da universidade'],
    },
    terrain: TerrainPalette(
      grassA: Color(0xFFA7B79A),
      grassB: Color(0xFF9CAD8F),
      road: Color(0xFFB4B0A4),
      plaza: Color(0xFFCFCABB),
      soil: Color(0xFF7A6E5C),
    ),
  );

  static const cocKingsport = SettlementType(
    id: 'kingsport',
    name: 'Porto nevoento (como Kingsport)',
    lore:
        'Kingsport é a cidade portuária antiga da Nova Inglaterra, de casas coloniais e ladeiras junto ao mar (fonte: Lovecraft Country/Wikipedia; confirmar no livro). Cais, faróis, armazéns e neblina.',
    wallColors: [Color(0xFFB9C2C4), Color(0xFFA9B4B8), Color(0xFFCFC6B0)],
    roofColors: [Color(0xFF4A5560), Color(0xFF5E4A44), Color(0xFF3F4A55)],
    kinds: [
      KindWeight(_K.gambrel, 5),
      KindWeight(_K.manor, 1.5),
      KindWeight(_K.barn, 1.5),
      KindWeight(_K.church, 0.8),
      KindWeight(_K.tower, 0.6),
    ],
    farmHouse: _K.gambrel,
    farmBarn: _K.barn,
    noLandmark: true,
    names: {
      _K.gambrel: ['Casa de capitão', 'Casa colonial', 'Casa de pescador'],
      _K.barn: ['Armazém', 'Cais de pesca', 'Cordoaria'],
      _K.tower: ['Farol', 'Torre da igreja'],
      _K.house: ['Casa colonial', 'Casa de capitão', 'Pensão do porto'],
    },
    water: WaterLayout.coast,
    farmShare: .1,
    filler: [
      PropWeight(_P.barrel, 2),
      PropWeight(_P.crate, 2),
      PropWeight(_P.dog, .7),
      PropWeight(_P.tree, 1),
      PropWeight(_P.bush, 1),
      PropWeight(_P.grave, .3)
    ],
  );

  static const cocWoods = SettlementType(
    id: 'bosque',
    name: 'Bosque sombrio (como os de Dunwich)',
    lore:
        'Mata cerrada e silenciosa em volta de poucas casas isoladas, com cemitérios e pedras antigas, como nas colinas de Dunwich (fonte: Lovecraft Country/Wikipedia; confirmar no livro).',
    wallColors: [Color(0xFFB5AB98), Color(0xFF9C9482), Color(0xFFA8A38C)],
    roofColors: [Color(0xFF4A4A44), Color(0xFF5E5242)],
    kinds: [
      KindWeight(_K.gambrel, 4),
      KindWeight(_K.farmhouse, 1.5),
      KindWeight(_K.barn, 1),
      KindWeight(_K.church, 0.4),
    ],
    farmHouse: _K.gambrel,
    farmBarn: _K.barn,
    noLandmark: true,
    names: {
      _K.house: ['Casebre', 'Casa isolada', 'Casa abandonada'],
      _K.church: ['Capela abandonada', 'Igreja'],
    },
    defaultMode: SettlementMode.forestOnly,
    terrain: TerrainPalette(
      grassA: Color(0xFF7E8C6E),
      grassB: Color(0xFF738263),
      road: Color(0xFFA89C80),
      plaza: Color(0xFFB8AE92),
      soil: Color(0xFF5E5240),
    ),
    farmShare: .2,
    filler: [
      PropWeight(_P.pine, 4),
      PropWeight(_P.tree, 3),
      PropWeight(_P.bush, 2),
      PropWeight(_P.grave, .8),
      PropWeight(_P.scarecrow, .3)
    ],
  );

  static const cocDunwich = SettlementType(
    id: 'dunwich',
    name: 'Vila rural isolada (como Dunwich)',
    lore:
        'Dunwich fica no interior de Massachusetts, comunidade rural decadente de colinas (fonte: Lovecraft Country/Wikipedia; confirmar no livro).',
    wallColors: [Color(0xFFB5AB98), Color(0xFF9C9482), Color(0xFFA8A38C)],
    roofColors: [Color(0xFF4A4A44), Color(0xFF5E5242)],
    kinds: [
      KindWeight(_K.gambrel, 3),
      KindWeight(_K.farmhouse, 2),
      KindWeight(_K.barn, 2),
      KindWeight(_K.church, 0.6),
    ],
    farmHouse: _K.gambrel,
    farmBarn: _K.barn,
    noLandmark: true,
    defaultMode: SettlementMode.farmsOnly,
    farmShare: .85,
    crops: [
      CropType.corn,
      CropType.wheat,
      CropType.pasture,
      CropType.vegetables
    ],
  );

  static const cocInnsmouth = SettlementType(
    id: 'innsmouth',
    name: 'Porto decadente (como Innsmouth)',
    lore:
        'Innsmouth é um porto em declínio na costa de Essex, modelado em Gloucester e Newburyport (fonte: Lovecraft Country/Wikipedia; confirmar no livro).',
    wallColors: [Color(0xFF9FAAA0), Color(0xFF8E9A92), Color(0xFFB5B8A8)],
    roofColors: [Color(0xFF3F4A4A), Color(0xFF4E5A52)],
    kinds: [
      KindWeight(_K.gambrel, 4),
      KindWeight(_K.manor, 3),
      KindWeight(_K.barn, 2),
      KindWeight(_K.church, 0.8),
    ],
    farmHouse: _K.gambrel,
    farmBarn: _K.barn,
    noLandmark: true,
    names: {
      _K.barn: ['Cais de pesca', 'Armazém de peixe', 'Cordoaria'],
    },
    water: WaterLayout.coast,
    farmShare: .1,
  );

  static const coc = [
    cocArkham,
    cocDunwich,
    cocInnsmouth,
    cocKingsport,
    cocWoods
  ];

  // ------------------------------------------------------------------ D&D 5e
  static const dndWaterdeep = SettlementType(
    id: 'metropole_murada',
    // Waterdeep (Forgotten Realms Wiki): humanos 64%, anões 10%, elfos 10%, halflings 5%,
    // meio-elfos 5%, gnomos 3%, meio-orcs 2%.
    population: [PropWeight(_P.raceHuman, 69), PropWeight(_P.raceDwarf, 10), PropWeight(_P.raceElf, 10), PropWeight(_P.raceHalfling, 5), PropWeight(_P.raceGnome, 3), PropWeight(_P.raceHalfOrc, 2), PropWeight(_P.raceTiefling, 1)],
    name: 'Waterdeep (Cidade dos Esplendores)',
    lore:
        'Waterdeep, a maior cidade da Costa da Espada. O mar a oeste; o Monte Waterdeep com o Castelo Waterdeep na costa; o Porto de Águas Profundas e a Ilha Deepwater ao sul; faróis; muralha com a muralha interna do norte. Os distritos (wards): Sea Ward (templos e casas nobres), North Ward (casas nobres e estalagens), Castle Ward (governo, no monte, com o Palácio e o Portal Escancarado), Trades Ward (comércio), Southern Ward (caravanas e estábulos), Dock Ward (docas e estaleiros), Field Ward (pobre, entre as muralhas do norte) e a Cidade dos Mortos (cemitério murado, aberto só de dia). Fontes: Forgotten Realms Wiki e páginas de fãs (que discordam em detalhes); confirmar em Waterdeep: Dragon Heist.',
    kinds: [
      KindWeight(_K.tallHouse, 4),
      KindWeight(_K.timber, 3),
      KindWeight(_K.manor, 2),
      KindWeight(_K.cottage, 2),
      KindWeight(_K.temple, 1),
      KindWeight(_K.tower, .5),
      KindWeight(_K.barn, 1),
      KindWeight(_K.castle, .01),
      KindWeight(_K.lighthouse, .01),
      KindWeight(_K.farmhouse, .01),
    ],
    noLandmark: true,
    noZone: true,
    layout: MapLayout.waterdeep,
    mapRatio: .85,
    minTiles: 96,
    defaultMode: SettlementMode.cityOnly,
    filler: [
      PropWeight(_P.barrel, 3),
      PropWeight(_P.crate, 3),
      PropWeight(_P.cart, 1.5),
      PropWeight(_P.tree, 1),
    ],
  );

  static const dndBaldursGate = SettlementType(
    id: 'cidade_comercial',
    // Baldur's Gate: grande maioria humana; elfos a seguir; anões, halflings e gnomos.
    population: [PropWeight(_P.raceHuman, 72), PropWeight(_P.raceElf, 10), PropWeight(_P.raceDwarf, 7), PropWeight(_P.raceHalfling, 6), PropWeight(_P.raceGnome, 2), PropWeight(_P.raceHalfOrc, 2), PropWeight(_P.raceTiefling, 1)],
    name: "Baldur's Gate",
    lore:
        "Baldur's Gate, cidade-porto de comércio na Costa da Espada. O Rio Chionthar ao sul e o Porto Cinzento (Gray Harbor) entrando na cidade; a Cidade Alta, murada primeiro, plana e rica, com o High Hall e o Templo de Gond; a Cidade Baixa em crescente descendo até o porto, com o mercado do Amplo e a Elfsong Tavern; a Cidade de Fora sem muralha, de barracos, cercados e estábulos; o Portão Basilisco no Caminho do Comércio; a Rocha do Wyrm, fortaleza do Punho Flamejante numa ilha do rio, entre as pontes; e Rivington na margem sul. Fontes: D&D Beyond, Forgotten Realms Wiki e Baldur's Gate: Descent into Avernus; confirmar no livro.",
    kinds: [
      KindWeight(_K.tallHouse, 4),
      KindWeight(_K.timber, 4),
      KindWeight(_K.cottage, 3),
      KindWeight(_K.manor, 2),
      KindWeight(_K.temple, .6),
      KindWeight(_K.barn, 1),
      KindWeight(_K.castle, .01),
    ],
    noLandmark: true,
    noZone: true,
    layout: MapLayout.baldursGate,
    mapRatio: .8,
    minTiles: 96,
    defaultMode: SettlementMode.cityOnly,
    filler: [
      PropWeight(_P.barrel, 3),
      PropWeight(_P.crate, 3),
      PropWeight(_P.stall, 2),
      PropWeight(_P.cart, 1.5),
    ],
  );

  static const dndNeverwinter = SettlementType(
    id: 'neverwinter',
    // Neverwinter (Forgotten Realms Wiki): humanos e meio-elfos, minoria de anões; tieflings
    // comuns e uma tribo de orcs assentada.
    population: [PropWeight(_P.raceHuman, 66), PropWeight(_P.raceElf, 12), PropWeight(_P.raceDwarf, 8), PropWeight(_P.raceTiefling, 6), PropWeight(_P.raceHalfOrc, 5), PropWeight(_P.raceHalfling, 3)],
    name: 'Neverwinter (Joia do Norte)',
    lore:
        'Neverwinter, a Joia do Norte, reconstruída depois da erupção do Monte Hotenow em 1451 DR. O rio quente que nunca congela atravessa a cidade até o Mar das Espadas, com a Ponte do Golfinho, a do Wyvern Alado e a do Dragão Adormecido; ao sul, o Enclave do Protetor (sede do poder, do Lorde Neverember) e o Salão da Justiça, templo de Tyr no penhasco sobre o rio; ao norte, o Castelo Never em parte arruinado e o distrito de Blacklake com o lago; a leste, o Abismo selado e o Distrito do Rio; ao fundo, o Monte Hotenow e a Floresta de Neverwinter. Fontes: Forgotten Realms Wiki, D&D Beyond e páginas de fãs; confirmar no Sword Coast Adventurer\'s Guide.',
    kinds: [
      KindWeight(_K.tallHouse, 3),
      KindWeight(_K.timber, 4),
      KindWeight(_K.manor, 2),
      KindWeight(_K.cottage, 3),
      KindWeight(_K.temple, .5),
      KindWeight(_K.castle, .01),
    ],
    noLandmark: true,
    noZone: true,
    layout: MapLayout.neverwinter,
    mapRatio: .8,
    minTiles: 90,
    defaultMode: SettlementMode.cityOnly,
    roofColors: [Color(0xFF3F5E8A), Color(0xFF4A5A70), Color(0xFF6B4A3A), Color(0xFF55606B)],
  );

  static const dndPhandalin = SettlementType(
    id: 'phandalin',
    // Phandalin (Forgotten Realms Wiki): humanos, anões, elfos, gnomos, meio-elfos e halflings.
    population: [PropWeight(_P.raceHuman, 62), PropWeight(_P.raceDwarf, 14), PropWeight(_P.raceHalfling, 10), PropWeight(_P.raceElf, 8), PropWeight(_P.raceGnome, 6)],
    name: 'Phandalin (vila de fronteira)',
    lore:
        'Phandalin, vila de fronteira refeita sobre as ruínas da antiga Phandalin, na Trilha de Triboar ao pé da Floresta de Neverwinter (cenário de A Mina Perdida de Phandelver). Sem muralha; ruínas antigas espalhadas; Stonehill Inn, Barthen\'s Provisions, Lionshield Coster, Salão do Mestre da Vila, Santuário da Sorte (Tymora), Sleeping Giant, Companhia dos Mineiros, Fazenda Alderleaf, Pomar de Edermath e as ruínas da Mansão Tresendar no morro a leste. Fonte: Lost Mine of Phandelver.',
    kinds: [
      KindWeight(_K.cottage, 5),
      KindWeight(_K.timber, 2),
      KindWeight(_K.barn, .6),
      KindWeight(_K.manor, .1),
      KindWeight(_K.temple, .1),
    ],
    noLandmark: true,
    noZone: true,
    layout: MapLayout.phandalin,
    minTiles: 64,
    defaultMode: SettlementMode.cityWithFarms,
  );

  static const dndBrynShander = SettlementType(
    id: 'bryn_shander',
    // Bryn Shander (Dez Cidades): humanos; anões da Cairn de Kelvin no comércio; poucos halflings.
    population: [PropWeight(_P.raceHuman, 84), PropWeight(_P.raceDwarf, 12), PropWeight(_P.raceHalfling, 4)],
    name: 'Bryn Shander (Vale do Vento Gélido)',
    lore:
        'Bryn Shander, a maior das Dez Cidades do Vale do Vento Gélido: cidade murada num morro na tundra coberta de neve, entre três lagos (Maer Dualdon, Lac Dinneshere e Redwaters), com o Monte de Kelvin a nordeste e estradas para as outras cidades (Termalaine, Targos, Easthaven, Caer-Dineval). Casas baixas de pedra e madeira de telhados cobertos de neve, a estalagem Northlook, o Salão do Porta-Voz e o templo da Senhora da Manhã. Fontes: Icewind Dale: Rime of the Frostmaiden e páginas de fãs; confirmar no livro.',
    kinds: [
      KindWeight(_K.cottage, 5),
      KindWeight(_K.timber, 3),
      KindWeight(_K.barn, .6),
      KindWeight(_K.manor, .1),
      KindWeight(_K.temple, .1),
    ],
    noLandmark: true,
    noZone: true,
    layout: MapLayout.brynShander,
    minTiles: 80,
    defaultMode: SettlementMode.cityOnly,
    wallColors: [Color(0xFF9A8F80), Color(0xFF8A7F70), Color(0xFFB0A898)],
    roofColors: [Color(0xFFF4F6F8), Color(0xFFE6ECF0), Color(0xFFDCE4EA)],
    trees: [_P.pine],
    terrain: TerrainPalette(
      grassA: Color(0xFFF2F5F7),
      grassB: Color(0xFFE6ECF0),
      road: Color(0xFFC9C3B6),
      plaza: Color(0xFFDDD8CE),
      soil: Color(0xFF7A7470),
    ),
  );

  static const dndForest = SettlementType(
    id: 'floresta_dnd',
    // Alto Bosque: elfos e humanos da fronteira, gnomos.
    population: [PropWeight(_P.raceElf, 50), PropWeight(_P.raceHuman, 35), PropWeight(_P.raceGnome, 8), PropWeight(_P.raceHalfling, 7)],
    name: 'Vila na floresta (Alto Bosque, com ruínas arcanas)',
    lore:
        'Tipo genérico: povoado numa clareira da mata, como as vilas do Alto Bosque (High Forest) da Costa da Espada, com cabanas, santuário druida, trilhas e uma área de ruínas arcanas por perto.',
    kinds: [
      KindWeight(_K.cottage, 6),
      KindWeight(_K.timber, 1.5),
      KindWeight(_K.temple, .5),
      KindWeight(_K.barn, 1),
      KindWeight(_K.elfTree, .8),
    ],
    noLandmark: true,
    names: {
      _K.cottage: ['Cabana', 'Casa de lenhador', 'Casa de caçador'],
      _K.timber: ['Taverna da clareira', 'Serraria', 'Posto de comércio'],
      _K.temple: ['Santuário druida', 'Capela da floresta'],
      _K.elfTree: ['Morada élfica', 'Casa na árvore'],
    },
    defaultMode: SettlementMode.forestOnly,
    water: WaterLayout.lake,
    terrain: TerrainPalette(
      grassA: Color(0xFF7DB070),
      grassB: Color(0xFF72A664),
      road: Color(0xFFC9B58A),
      plaza: Color(0xFFD8CCA8),
      soil: Color(0xFF6E5A3E),
    ),
    farmShare: .3,
    filler: [
      PropWeight(_P.tree, 4),
      PropWeight(_P.pine, 3),
      PropWeight(_P.bush, 3),
      PropWeight(_P.ruin, .6),
    ],
  );

  static const dndFrontier = SettlementType(
    id: 'vila_fronteira',
    // Vila de fronteira: humanos e halflings lavradores, anões.
    population: [PropWeight(_P.raceHuman, 72), PropWeight(_P.raceHalfling, 14), PropWeight(_P.raceDwarf, 8), PropWeight(_P.raceGnome, 3), PropWeight(_P.raceHalfOrc, 3)],
    name: 'Vila agrícola de fronteira',
    lore:
        'Tipo genérico: aldeia rodeada de plantações, moinhos e pastos, com ruínas antigas por perto, típica dos campos de aventura de D&D.',
    kinds: [
      KindWeight(_K.cottage, 5),
      KindWeight(_K.timber, 1.5),
      KindWeight(_K.barn, 2),
      KindWeight(_K.windmill, 1.5),
      KindWeight(_K.temple, .5),
    ],
    noLandmark: true,
    defaultMode: SettlementMode.farmsOnly,
    farmShare: .85,
    crops: [
      CropType.wheat,
      CropType.corn,
      CropType.vegetables,
      CropType.orchard,
      CropType.pasture
    ],
  );

  static const dndFreeCity = SettlementType(
    id: 'cidade_livre_dnd',
    name: 'Cidade ou vila livre (com área de magia)',
    lore:
        'Tipo genérico de Faerûn para a sua campanha: cada geração sorteia cidade ou vila, a água, a muralha, o marco, as cores e a mistura de construções, com uma área de magia instável (ruínas arcanas, pedras rúnicas) por perto.',
    kinds: [
      KindWeight(_K.timber, 4),
      KindWeight(_K.cottage, 3),
      KindWeight(_K.tallHouse, 2),
      KindWeight(_K.manor, 1),
      KindWeight(_K.temple, 1),
      KindWeight(_K.tower, 1),
    ],
    landmark: _K.castle,
    landmarkChance: .45,
    wildZone: true,
    varied: true,
    defaultMode: SettlementMode.cityWithFarms,
  );

  static const dnd = [
    SettlementType.standard,
    dndWaterdeep,
    dndBaldursGate,
    dndNeverwinter,
    dndPhandalin,
    dndBrynShander,
    dndFreeCity,
    dndForest,
    dndFrontier
  ];

  // ------------------------------------------------------------------ Ordem Paranormal
  static const ordemSmallTown = SettlementType(
    id: 'interior',
    name: 'Cidade do interior',
    lore:
        'Cidade pequena do interior brasileiro: praça com igreja matriz, casas baixas, comércio de rua e plantações ao redor (tipo genérico; confirmar locais nos livros da Ordem Paranormal).',
    wallColors: [
      Color(0xFFF2E3C6),
      Color(0xFFE9D2B0),
      Color(0xFFD8E3D0),
      Color(0xFFF0C8B0),
      Color(0xFFE7E0D4)
    ],
    roofColors: [Color(0xFFB5553A), Color(0xFF9C4A32), Color(0xFF7A5A4A)],
    kinds: [
      KindWeight(_K.townHouse, 7),
      KindWeight(_K.modern, 2),
      KindWeight(_K.church, 1.2),
    ],
    farmHouse: _K.townHouse,
    farmBarn: _K.barn,
    names: {
      _K.townHouse: ['Casa', 'Casa de dona Maria', 'Casa do seu João', 'Sobrado'],
      _K.house: ['Casa', 'Casa de esquina', 'Chácara'],
      _K.modern: [
        'Padaria',
        'Mercadinho',
        'Farmácia',
        'Escola municipal',
        'Delegacia',
        'Bar'
      ],
    },
    farmShare: .35,
  );

  static const ordemForest = SettlementType(
    id: 'floresta_ordem',
    name: 'Floresta com cabanas (estilo "O Segredo na Floresta")',
    lore:
        'Mata fechada com cabanas isoladas e a Membrana fina entre as realidades, no clima da aventura "O Segredo na Floresta" (confirmar nos livros da Ordem Paranormal). Liga a área paranormal por padrão.',
    wallColors: [Color(0xFFB79A78), Color(0xFF9C8466), Color(0xFFC9B08C)],
    roofColors: [Color(0xFF5A4A3E), Color(0xFF4A4036), Color(0xFF6A5444)],
    kinds: [
      KindWeight(_K.townHouse, 6),
      KindWeight(_K.modern, 0.4),
    ],
    farmHouse: _K.townHouse,
    farmBarn: _K.barn,
    noLandmark: true,
    names: {
      _K.house: ['Cabana', 'Casa abandonada', 'Posto de guarda florestal'],
      _K.barn: ['Galpão', 'Depósito'],
    },
    defaultMode: SettlementMode.forestOnly,
    wildZone: true,
    water: WaterLayout.lake,
    terrain: TerrainPalette(
      grassA: Color(0xFF6FA264),
      grassB: Color(0xFF649758),
      road: Color(0xFFB9A883),
      plaza: Color(0xFFC9BE9C),
      soil: Color(0xFF5E4E3A),
    ),
    farmShare: .2,
    filler: [
      PropWeight(_P.tree, 4),
      PropWeight(_P.pine, 2),
      PropWeight(_P.bush, 3),
      PropWeight(_P.grave, .4),
      PropWeight(_P.dog, .4)
    ],
  );

  static const ordemCoast = SettlementType(
    id: 'litoral',
    name: 'Cidade litorânea',
    lore:
        'Cidade de praia brasileira: casas simples, comércio, píer e barcos (tipo genérico).',
    kinds: [
      KindWeight(_K.townHouse, 4),
      KindWeight(_K.modern, 3),
      KindWeight(_K.block, 1.5),
      KindWeight(_K.church, 0.6),
    ],
    farmHouse: _K.townHouse,
    farmBarn: _K.barn,
    water: WaterLayout.coast,
    farmShare: .1,
  );

  static const ordem = [
    SettlementType.standard,
    ordemSmallTown,
    ordemForest,
    ordemCoast
  ];

  // ------------------------------------------------------------------ Cyberpunk RED
  // Todos os tipos mantêm 'lab' e 'modern' nas construções porque são o galpão e a estufa
  // dos sítios do futuro (ver Era.farmHouseKind).
  static const cyberCityCenter = SettlementType(
    id: 'city_center',
    name: 'Centro corporativo (como o City Center)',
    lore:
        'Distrito das torres das megacorporações e do comércio de luxo de Night City (fonte: Cyberpunk Wiki; confirmar no Cyberpunk RED). Arranha-céus, neon e drones.',
    kinds: [
      KindWeight(_K.skyscraper, 6),
      KindWeight(_K.block, 2),
      KindWeight(_K.modern, 2),
      KindWeight(_K.lab, .5),
    ],
    defaultMode: SettlementMode.cityOnly,
    farmShare: 0,
  );

  static const cyberWatson = SettlementType(
    id: 'watson',
    name: 'Distrito industrial e imigrante (como Watson)',
    lore:
        'Watson é um distrito de fábricas, blocos populares e comércio de rua de Night City (fonte: Cyberpunk Wiki; confirmar no Cyberpunk RED). Conjuntos habitacionais, oficinas e mercados noturnos.',
    kinds: [
      KindWeight(_K.block, 4),
      KindWeight(_K.modern, 3),
      KindWeight(_K.warehouse, 2),
      KindWeight(_K.lab, 1),
      KindWeight(_K.skyscraper, 0.8),
    ],
    names: {
      _K.modern: ['Mercado noturno', 'Oficina', 'Bar', 'Loja de ripper'],
      _K.lab: ['Fábrica', 'Armazém industrial'],
    },
    defaultMode: SettlementMode.cityOnly,
    farmShare: 0,
  );

  static const cyberHeywood = SettlementType(
    id: 'heywood',
    name: 'Bairro residencial (como Heywood)',
    lore:
        'Heywood é um distrito residencial de Night City, com blocos de apartamentos e comércio local (fonte: Cyberpunk Wiki; confirmar no Cyberpunk RED).',
    kinds: [
      KindWeight(_K.modern, 5),
      KindWeight(_K.block, 3),
      KindWeight(_K.skyscraper, .5),
      KindWeight(_K.lab, .3),
    ],
    defaultMode: SettlementMode.cityOnly,
    farmShare: 0,
  );

  static const cyberSantoDomingo = SettlementType(
    id: 'santo_domingo',
    name: 'Zona industrial (como Santo Domingo)',
    lore:
        'Santo Domingo concentra indústrias e vilas operárias de Night City (fonte: Cyberpunk Wiki; confirmar no Cyberpunk RED). Fábricas, galpões e blocos baixos.',
    kinds: [
      KindWeight(_K.warehouse, 4),
      KindWeight(_K.block, 3),
      KindWeight(_K.lab, 2),
      KindWeight(_K.modern, 1.5),
      KindWeight(_K.skyscraper, 0.3),
    ],
    names: {
      _K.warehouse: ['Galpão', 'Fábrica', 'Armazém de carga', 'Oficina clandestina'],
      _K.lab: ['Fábrica', 'Refinaria', 'Usina'],
      _K.modern: ['Galpão', 'Oficina', 'Bar de operários'],
    },
    defaultMode: SettlementMode.cityOnly,
    farmShare: 0,
  );

  static const cyberPacifica = SettlementType(
    id: 'pacifica',
    name: 'Zona de combate costeira (como Pacifica)',
    lore:
        'Pacifica é o distrito litorâneo abandonado e disputado por gangues, a Zona de Combate de Night City (fonte: Cyberpunk Wiki; confirmar no Cyberpunk RED). Liga a área de combate por padrão.',
    kinds: [
      KindWeight(_K.modern, 4),
      KindWeight(_K.block, 2),
      KindWeight(_K.skyscraper, 1),
      KindWeight(_K.lab, .3),
    ],
    water: WaterLayout.coast,
    wildZone: true,
    defaultMode: SettlementMode.cityOnly,
    farmShare: 0,
  );

  static const cyberBadlands = SettlementType(
    id: 'badlands',
    name: 'Terras áridas (como as Badlands)',
    lore:
        'Deserto fora de Night City com acampamentos nômades e fazendas hidropônicas (fonte: Cyberpunk Wiki; confirmar no Cyberpunk RED). Estufas, galpões, poeira e carros.',
    kinds: [
      KindWeight(_K.greenhouse, 4),
      KindWeight(_K.warehouse, 1.5),
      KindWeight(_K.modern, 2),
      KindWeight(_K.block, 0.3),
    ],
    noLandmark: true,
    names: {
      _K.greenhouse: ['Estufa hidropônica', 'Fazenda vertical', 'Estufa de algas'],
      _K.lab: ['Estufa hidropônica', 'Fazenda vertical', 'Tanque de algas'],
      _K.modern: ['Galpão', 'Oficina nômade', 'Posto de recarga'],
    },
    defaultMode: SettlementMode.farmsOnly,
    terrain: TerrainPalette(
      grassA: Color(0xFFD9BE8C),
      grassB: Color(0xFFCFB27C),
      road: Color(0xFFB5A58A),
      plaza: Color(0xFFE0CBA0),
      soil: Color(0xFF8A6A48),
    ),
    crops: [CropType.cotton, CropType.vegetables, CropType.pasture],
    farmShare: .7,
    filler: [
      PropWeight(_P.cactus, 4),
      PropWeight(_P.car, 1.5),
      PropWeight(_P.dish, .6),
      PropWeight(_P.crate, 1),
      PropWeight(_P.drone, .5)
    ],
  );

  static const cyber = [
    SettlementType.standard,
    cyberCityCenter,
    cyberWatson,
    cyberHeywood,
    cyberSantoDomingo,
    cyberPacifica,
    cyberBadlands
  ];
}
