document$.subscribe(function () {
  mermaid.initialize({
    startOnLoad: false,
    theme: "default",
    securityLevel: "loose",
    flowchart: { curve: "basis", useMaxWidth: true },
  });
  mermaid.run({ querySelector: ".mermaid, pre.mermaid, code.language-mermaid" });
});
