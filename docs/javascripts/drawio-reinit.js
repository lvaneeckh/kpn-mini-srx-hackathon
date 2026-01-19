function initDrawio() {
  if (typeof window.mxgraph !== "undefined" && window.mxgraph.parse) {
    document.querySelectorAll(".mxgraph").forEach(el => {
      if (!el.hasAttribute("data-mxgraph-loaded")) {
        el.setAttribute("data-mxgraph-loaded", "true");
        window.mxgraph.parse(el);
      }
    });
  }
}

document.addEventListener("DOMContentLoaded", initDrawio);
document.addEventListener("navigation.instant", initDrawio);
document.addEventListener("navigation.pageChanged", initDrawio);
