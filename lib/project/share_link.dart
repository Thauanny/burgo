import 'dart:convert';
import 'dart:typed_data';

import '../persistence/deflate.dart';

/// Receita de um mapa gerado e ainda não editado: com ela o mapa é gerado de novo, igual
/// (a geração é reproduzível pela semente). Vira um link bem curto.
class MapRecipe {
  const MapRecipe({
    required this.systemId,
    required this.settlementId,
    required this.mode,
    required this.seed,
    required this.tiles,
    required this.zone,
    required this.farmGap,
  });

  final String systemId, settlementId, mode;
  final int seed, tiles, farmGap;
  final bool zone;

  Map<String, dynamic> toJson() =>
      {'s': systemId, 't': settlementId, 'm': mode, 'r': seed, 'n': tiles, 'z': zone ? 1 : 0, 'g': farmGap};

  static MapRecipe fromJson(Map<String, dynamic> j) => MapRecipe(
        systemId: j['s'] as String,
        settlementId: j['t'] as String,
        mode: j['m'] as String,
        seed: (j['r'] as num).toInt(),
        tiles: (j['n'] as num).toInt(),
        zone: j['z'] == 1,
        farmGap: (j['g'] as num?)?.toInt() ?? 4,
      );
}

/// O que um link de compartilhamento traz: a receita (mapa sem edição) ou o projeto inteiro.
sealed class SharedMap {
  const SharedMap();
}

final class SharedRecipe extends SharedMap {
  const SharedRecipe(this.recipe);
  final MapRecipe recipe;
}

final class SharedProject extends SharedMap {
  const SharedProject(this.projectJson);
  final String projectJson;
}

/// Links de compartilhamento: o mapa vai no próprio endereço, depois do `#` (o navegador não
/// manda essa parte para servidor nenhum). `#g=` é a receita; `#p=` é o projeto comprimido.
abstract final class ShareLink {
  static String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

  static Uint8List _unb64(String s) => base64Url.decode(s.padRight((s.length + 3) ~/ 4 * 4, '='));

  static String recipeFragment(MapRecipe r) => 'g=${_b64(utf8.encode(jsonEncode(r.toJson())))}';

  static Future<String> projectFragment(String projectJson) async {
    // sem espaços: o texto do projeto fica bem menor antes de comprimir
    final compact = jsonEncode(jsonDecode(projectJson));
    return 'p=${_b64(await deflateRaw(Uint8List.fromList(utf8.encode(compact))))}';
  }

  /// Lê o que vem depois do `#` (com ou sem o `#`). Nulo se não for um link do Burgo.
  static Future<SharedMap?> parse(String fragment) async {
    final f = fragment.startsWith('#') ? fragment.substring(1) : fragment;
    if (f.startsWith('g=')) {
      final json = jsonDecode(utf8.decode(_unb64(f.substring(2))));
      return SharedRecipe(MapRecipe.fromJson(json as Map<String, dynamic>));
    }
    if (f.startsWith('p=')) {
      return SharedProject(utf8.decode(await inflateRaw(_unb64(f.substring(2)))));
    }
    return null;
  }
}
