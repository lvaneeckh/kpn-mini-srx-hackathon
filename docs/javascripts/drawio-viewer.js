(function () {
  if (window.mxgraph) return;

  const script = document.createElement("script");
  script.type = "text/javascript";
  script.src = "https://viewer.diagrams.net/js/viewer-static.min.js";
  script.async = true;
  document.head.appendChild(script);
})();
