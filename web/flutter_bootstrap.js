{{flutter_js}}
{{flutter_build_config}}

// Carrega o CanvasKit da própria pasta do app (build/web/canvaskit/) em vez do CDN do Google:
// o Burgo abre mesmo sem acesso ao gstatic (rede bloqueada, offline) e no GitHub Pages.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
