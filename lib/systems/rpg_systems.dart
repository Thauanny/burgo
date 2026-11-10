import 'dart:ui';
import '../domain/city_types.dart';
import 'art_profiles.dart';
import 'rpg_system.dart';

// Paleta medieval: reboco, pedra clara e ocre; telhas de barro, ardósia, musgo e palha.
const _fantasyWalls = [
  Color(0xFFEBDDBF),
  Color(0xFFD8C9A6),
  Color(0xFFF0E6CF),
  Color(0xFFE2C98F),
  Color(0xFFC9C2B0),
  Color(0xFFDDB9A0),
  Color(0xFFE9D3B0),
  Color(0xFFBDB59F),
];
const _fantasyRoofs = [
  Color(0xFFB5523F),
  Color(0xFF7A4B34),
  Color(0xFF5E6672),
  Color(0xFF5E7048),
  Color(0xFFC9A558),
  Color(0xFF9A4A3A),
  Color(0xFF6A5A4A),
];

class RpgSystems {
  static const generic = RpgSystem(
    id: 'generico',
    art: ArtProfiles.generic,
    name: 'Fantasia genérica',
    setting: 'Reino medieval de fantasia',
    era: 'Medieval fantástico',
    folk: ['Humanos', 'Anões', 'Elfos', 'Halflings'],
    grassA: Color(0xFF9ED98B),
    grassB: Color(0xFF93D181),
    roadColor: Color(0xFFD6CBB6),
    plazaColor: Color(0xFFEADFC4),
    soil: Color(0xFFB08968),
    walls: _fantasyWalls,
    roofs: _fantasyRoofs,
    cityA: [
      'Vale',
      'Porto',
      'Monte',
      'Rio',
      'Campo',
      'Pedra',
      'Santa',
      'Bela',
      'Lago',
      'Torre'
    ],
    cityB: [
      'Verde',
      'Dourado',
      'Claro',
      'das Brumas',
      'do Sol',
      'Velho',
      'Azul',
      'da Lua',
      'Alto'
    ],
    small: ['Casa', 'Chalé', 'Cabana'],
    medium: ['Sobrado', 'Taverna', 'Ferraria', 'Padaria', 'Boticário'],
    large: ['Estalagem', 'Mansão', 'Guilda', 'Templo'],
    suffixes: [
      'do Javali',
      'da Lua',
      'do Grifo',
      'do Moinho',
      'Carvalho',
      'Lírio',
      'Brisa',
      'do Ferreiro'
    ],
    hooks: [
      'Um mercador desapareceu a caminho da cidade e o cavalo voltou sozinho.',
      'A fonte da praça começou a jorrar um líquido que brilha à noite.',
      'O prefeito paga bem por quem descobrir quem anda roubando os sinos.',
      'Uma estalagem só aceita hóspedes que contem uma história inédita.',
    ],
    props: [
      PropType.tree,
      PropType.pine,
      PropType.sakura,
      PropType.toro,
      PropType.torii,
      PropType.elfLamp,
      PropType.bush,
      PropType.well,
      PropType.fountain,
      PropType.stall,
      PropType.lamp
    ],
  );

  static const tormenta20 = RpgSystem(
    id: 't20',
    art: ArtProfiles.tormenta20,
    name: 'Tormenta20',
    setting: 'Arton — Reinado e reinos vizinhos',
    era: 'Fantasia heroica',
    folk: [
      'Humanos',
      'Anões',
      'Elfos',
      'Goblins',
      'Hynne',
      'Minotauros',
      'Qareen',
      'Dahllan',
      'Lefou'
    ],
    grassA: Color(0xFFA2DC8A),
    grassB: Color(0xFF97D47F),
    roadColor: Color(0xFFD9CBB0),
    plazaColor: Color(0xFFEBDDBE),
    soil: Color(0xFFB08968),
    walls: _fantasyWalls,
    roofs: _fantasyRoofs,
    cityA: ['Nova', 'Porto', 'Vila', 'Forte', 'Monte', 'Vale', 'Sant', 'Pedra'],
    cityB: [
      'Valkaria',
      'Deheon',
      'Brumas',
      'do Grifo',
      'Alvorada',
      'Azgher',
      'da Lena',
      'Rubra'
    ],
    small: ['Casa', 'Choupana', 'Chalé'],
    medium: [
      'Taverna',
      'Sobrado',
      'Ferraria',
      'Loja de Poções',
      'Posto da Guarda',
      'Armeiro'
    ],
    large: [
      'Templo de Khalmyr',
      'Templo de Lena',
      'Templo de Azgher',
      'Templo de Wynna',
      'Guilda de Aventureiros',
      'Academia Arcana',
      'Estalagem'
    ],
    suffixes: [
      'do Javali',
      'da Aurora',
      'do Grifo',
      'do Dragão',
      'do Aventureiro',
      'da Luz',
      'do Machado'
    ],
    hooks: [
      'Uma chuva vermelha caiu a oeste e os animais fugiram da floresta.',
      'Um lefou ferido pede abrigo e jura que viu "o céu sangrar".',
      'A guilda precisa de heróis para escoltar suprimentos até a borda da Área de Tormenta.',
      'Um tesouro de um antigo herói de Arton foi marcado num mapa rasgado.',
      'Um sacerdote de Khalmyr acusa o prefeito de acobertar um julgamento falso.',
    ],
    props: [
      PropType.tree,
      PropType.pine,
      PropType.bush,
      PropType.well,
      PropType.fountain,
      PropType.stall,
      PropType.lamp,
      PropType.anomaly
    ],
    zoneName: 'Área de Tormenta',
    zoneNote:
        'Terreno rubro e corrompido, cristais e raízes da Tormenta, criaturas lefeu. Aproximar-se corrói a sanidade e a realidade.',
    zoneColor: Color(0xFFD63A3A),
    anomalyName: 'Espinho da Tormenta',
  );

  static const dnd5e = RpgSystem(
    id: 'dnd5e',
    art: ArtProfiles.dnd5e,
    name: 'D&D 5e',
    setting: 'Faerûn / Costa da Espada (ou mundo próprio)',
    era: 'Fantasia medieval',
    folk: [
      'Humanos',
      'Anões',
      'Elfos',
      'Halflings',
      'Meio-orcs',
      'Tieflings',
      'Draconatos',
      'Gnomos'
    ],
    grassA: Color(0xFF9CD488),
    grassB: Color(0xFF90CB7C),
    roadColor: Color(0xFFD3C8B4),
    plazaColor: Color(0xFFE6DABF),
    soil: Color(0xFFA98462),
    walls: _fantasyWalls,
    roofs: _fantasyRoofs,
    cityA: [
      'Baldur',
      'Water',
      'Neverw',
      'Phand',
      'Elturel',
      'Daggerf',
      'Silver',
      'Luskan'
    ],
    cityB: ['ford', 'gate', 'deep', 'dale', 'mere', 'haven', 'watch', 'reach'],
    small: ['Casa', 'Chalé', 'Cabana'],
    medium: [
      'Taverna',
      'Ferraria',
      'Alquimista',
      'Mercado',
      'Posto da Guarda',
      'Curandeiro'
    ],
    large: [
      'Templo',
      'Guilda de Mercadores',
      'Casa Nobre',
      'Biblioteca',
      'Estalagem',
      'Torre de Mago'
    ],
    suffixes: [
      'do Dragão Dourado',
      'do Escudo Quebrado',
      'da Chama Eterna',
      'do Corvo',
      'do Lobo Cinzento'
    ],
    hooks: [
      'Uma Casa Nobre contrata aventureiros para sumir com um herdeiro inconveniente.',
      'Cultistas pregam em becos que um dragão adormecido acordará no solstício.',
      'A guilda de mercadores perdeu três caravanas na mesma estrada.',
      'Um mago excêntrico oferece um item mágico por um favor sem explicar o quê.',
    ],
    props: [
      PropType.tree,
      PropType.pine,
      PropType.bush,
      PropType.well,
      PropType.fountain,
      PropType.stall,
      PropType.lamp,
      PropType.anomaly
    ],
    zoneName: 'Zona de magia selvagem (travessia feérica)',
    zoneNote:
        'Lugar onde a Faéria (Feywild) vaza para o mundo material, como as travessias feéricas e as zonas de magia selvagem de D&D 5e: a magia fica instável (surtos de magia selvagem), pedras rúnicas brilham, faíscas coloridas flutuam, as plantas ganham cores impossíveis e os animais ficam encantados, flutuando num halo de luz. Use para uma travessia para a Faéria, ruínas arcanas, o covil de uma bruxa ou um bosque amaldiçoado.',
    zoneColor: Color(0xFF8A5CD6),
    anomalyName: 'Pedra rúnica',
  );

  static const loop = RpgSystem(
    id: 'loop',
    art: ArtProfiles.loop,
    name: 'Tales from the Loop',
    setting:
        'Ilhas de Mälaren (Suécia) ou Boulder City (EUA), anos 80 alternativos',
    era: '1980s retrofuturista',
    folk: [
      'Crianças e adolescentes',
      'Pais e professores',
      'Cientistas do Loop',
      'Gyrobots',
      'Animais mutantes'
    ],
    grassA: Color(0xFFB4D99A),
    grassB: Color(0xFFA9D18F),
    roadColor: Color(0xFFC9C6BE),
    plazaColor: Color(0xFFE2DDD0),
    soil: Color(0xFF9B8468),
    walls: [
      Color(0xFFE9C6A6),
      Color(0xFFD9B08C),
      Color(0xFFF0E2C4),
      Color(0xFFC9D9C3),
      Color(0xFFBBD2DC),
      Color(0xFFE5B7A8),
      Color(0xFFEFE0A8),
    ],
    roofs: [
      Color(0xFFA2503F),
      Color(0xFF6C6A66),
      Color(0xFF7C5B44),
      Color(0xFF4F6E8A),
      Color(0xFF8C3F3F)
    ],
    cityA: ['Mälar', 'Svart', 'Sjö', 'Vik', 'Björk', 'Boulder', 'Ljus', 'Ek'],
    cityB: ['ö', 'by', 'holm', 'strand', 'Heights', 'dal', 'viken'],
    small: ['Casa', 'Casa de campo', 'Garagem'],
    medium: [
      'Lanchonete',
      'Fliperama',
      'Loja de eletrônicos',
      'Posto de gasolina',
      'Escola',
      'Mercadinho'
    ],
    large: [
      'Escola',
      'Prédio residencial',
      'Biblioteca',
      'Centro de pesquisa',
      'Ginásio'
    ],
    suffixes: [
      'Lindqvist',
      'Nilsson',
      'do Lago',
      'da Estação',
      'Andersson',
      'do Cais',
      'Karlsson'
    ],
    hooks: [
      'Um gyrobot abandonado na floresta começou a repetir o nome de uma criança desaparecida.',
      'O relógio da escola parou, mas só as crianças percebem que o tempo ficou preso.',
      'Cabos novos foram instalados nos postes e as luzes piscam em código.',
      'Alguém viu uma nave enferrujada de magnetrina emergir do lago.',
    ],
    props: [
      PropType.tree,
      PropType.pine,
      PropType.bush,
      PropType.stall,
      PropType.lamp,
      PropType.freighter,
      PropType.anomaly
    ],
    zoneName: 'Perímetro do Loop',
    zoneNote:
        'O acelerador sob a terra e seu entorno cercado: gravidade estranha, máquinas antigas e ruídos que ninguém explica.',
    zoneColor: Color(0xFF5BA6C9),
    anomalyName: 'Torre do Loop',
    flatBias: 0.4,
  );

  static const ordem = RpgSystem(
    id: 'ordem',
    art: ArtProfiles.ordem,
    name: 'Ordem Paranormal',
    setting: 'Brasil contemporâneo, cidade com uma fenda para o Outro Lado',
    era: 'Moderno / horror investigativo',
    folk: [
      'Civis',
      'Agentes da Ordem',
      'Cultistas',
      'Sobreviventes',
      'Criaturas do Outro Lado'
    ],
    grassA: Color(0xFFA7CFA0),
    grassB: Color(0xFF9BC694),
    roadColor: Color(0xFFBDBBB8),
    plazaColor: Color(0xFFD9D4CA),
    soil: Color(0xFF8D7A6B),
    walls: [
      Color(0xFFE6DDD0),
      Color(0xFFCFD6DC),
      Color(0xFFE8CFC6),
      Color(0xFFD5DCC8),
      Color(0xFFEADFA8),
    ],
    roofs: [
      Color(0xFF8A5648),
      Color(0xFF6E6F73),
      Color(0xFF4F5B66),
      Color(0xFF9C6B52)
    ],
    cityA: ['São', 'Nova', 'Vila', 'Santa', 'Porto', 'Bom'],
    cityB: [
      'Jorge',
      'Esperança',
      'Vitória',
      'Clara',
      'do Norte',
      'da Serra',
      'Horizonte'
    ],
    small: ['Casa', 'Sobrado', 'Barraco'],
    medium: ['Padaria', 'Delegacia', 'Farmácia', 'Escola', 'Igreja', 'Bar'],
    large: [
      'Hospital',
      'Prédio comercial',
      'Condomínio',
      'Casarão abandonado',
      'Universidade'
    ],
    suffixes: [
      'Central',
      'São José',
      'da Praça',
      'do Bairro',
      'Aurora',
      'Esperança'
    ],
    hooks: [
      'Moradores de um condomínio relatam o mesmo sonho com um corredor sem fim.',
      'A Ordem recebe um chamado: um casarão abandonado "respira" à noite.',
      'Um grafite aparece em vários muros e quem o toca perde a memória do dia.',
      'O hospital recebeu pacientes que falam línguas que nunca aprenderam.',
    ],
    props: [
      PropType.tree,
      PropType.bush,
      PropType.stall,
      PropType.lamp,
      PropType.anomaly
    ],
    zoneName: 'Zona de Membrana Fina',
    zoneNote:
        'Região onde a Membrana entre a realidade e o Outro Lado está enfraquecida: símbolos, ecos e manifestações.',
    zoneColor: Color(0xFFB02E5C),
    anomalyName: 'Símbolo do Outro Lado',
    flatBias: 0.45,
  );

  static const coc = RpgSystem(
    id: 'coc',
    art: ArtProfiles.coc,
    name: 'Call of Cthulhu',
    setting: 'Cidade da Nova Inglaterra, anos 1920',
    era: '1920s / horror cósmico',
    folk: [
      'Investigadores',
      'Acadêmicos',
      'Policiais',
      'Imigrantes',
      'Cultistas'
    ],
    grassA: Color(0xFF93BC85),
    grassB: Color(0xFF89B27B),
    roadColor: Color(0xFFB8B0A2),
    plazaColor: Color(0xFFD6CDB8),
    soil: Color(0xFF7E6B58),
    walls: [
      Color(0xFFD8C7A8),
      Color(0xFFB9A58A),
      Color(0xFFC9B79C),
      Color(0xFFA9B5A8),
      Color(0xFFCFB8A8),
    ],
    roofs: [
      Color(0xFF5E4A44),
      Color(0xFF4C5560),
      Color(0xFF6A5340),
      Color(0xFF3F4A44)
    ],
    cityA: ['Arkh', 'Inns', 'Kings', 'Dun', 'Inn', 'Salem', 'Inver'],
    cityB: ['port', 'wich', 'am', 'ness', 'field', 'ford'],
    small: ['Casa', 'Chalé', 'Casebre'],
    medium: [
      'Pensão',
      'Emporium',
      'Gráfica',
      'Delegacia',
      'Taverna',
      'Funerária'
    ],
    large: [
      'Universidade',
      'Biblioteca',
      'Sanatório',
      'Igreja',
      'Hotel',
      'Museu'
    ],
    suffixes: [
      'do Porto',
      'da Colina',
      'do Pântano',
      'Whateley',
      'Pickman',
      'Marsh'
    ],
    hooks: [
      'Um professor da universidade some após encomendar um livro sem autor.',
      'Pescadores recusam sair ao mar e falam de cantos vindos do fundo.',
      'O sanatório recebeu um paciente que desenha sempre a mesma porta.',
      'Um testamento exige que os herdeiros passem uma noite na mansão da colina.',
    ],
    props: [
      PropType.tree,
      PropType.pine,
      PropType.bush,
      PropType.well,
      PropType.lamp,
      PropType.anomaly
    ],
    zoneName: 'Região do Culto',
    zoneNote:
        'Bosque, pântano ou casarão onde ritos antigos acontecem: obeliscos, pedras tortas e sons que não deveriam existir.',
    zoneColor: Color(0xFF4F8E6B),
    anomalyName: 'Obelisco estranho',
    flatBias: 0.2,
  );

  static const cyber = RpgSystem(
    id: 'cyber',
    art: ArtProfiles.cyber,
    name: 'Cyberpunk RED',
    setting: 'Night City, 2045',
    era: 'Futuro distópico',
    folk: ['Corpos', 'Nômades', 'Netrunners', 'Solos', 'Techs', 'Fixers'],
    grassA: Color(0xFF6C7A86),
    grassB: Color(0xFF63717D),
    roadColor: Color(0xFF3F4650),
    plazaColor: Color(0xFF59616D),
    soil: Color(0xFF2E343C),
    walls: [
      Color(0xFF8F9BB0),
      Color(0xFFB07AC9),
      Color(0xFF5FB7C7),
      Color(0xFFD9A441),
      Color(0xFFC95F7A),
    ],
    roofs: [Color(0xFF2F3744), Color(0xFF4A3F5C), Color(0xFF3A5560)],
    cityA: ['Night', 'Neo', 'Port', 'Bay', 'Chrome', 'Neon'],
    cityB: ['City', 'Heights', 'Docks', 'Strip', 'Sector'],
    small: ['Apartamento', 'Cápsula', 'Oficina'],
    medium: [
      'Bar',
      'Clínica de cromo',
      'Loja de armas',
      'Noodle bar',
      'Garagem'
    ],
    large: ['Torre corporativa', 'Arcologia', 'Cassino', 'Fábrica', 'Hospital'],
    suffixes: [
      'Arasaka',
      'Militech',
      'Neon',
      'da Rua 7',
      'Afterlife',
      'Blackout'
    ],
    hooks: [
      'Um fixer oferece muito dinheiro por um chip que alguém jura não existir.',
      'Netrunners relatam um ICE que fala com a voz de um morto.',
      'Uma corporação demole um quarteirão inteiro sem aviso e há feridos.',
      'Um nômade chega com um comboio e uma carga que ninguém quer abrir.',
    ],
    props: [
      PropType.bush,
      PropType.stall,
      PropType.lamp,
      PropType.fountain,
      PropType.anomaly
    ],
    zoneName: 'Zona de Combate',
    zoneNote:
        'Distrito sem lei, controlado por gangues: neon, barricadas e fogo cruzado.',
    zoneColor: Color(0xFFE23E8F),
    anomalyName: 'Letreiro de neon',
    flatBias: 0.85,
    green: 0.2,
  );

  /// Sistemas oferecidos no app. Ordem Paranormal, Call of Cthulhu e Cyberpunk RED foram retirados
  /// da lista (as definições [ordem], [coc] e [cyber] seguem no código, desligadas).
  static const all = <RpgSystem>[generic, tormenta20, dnd5e, loop];
}
