meta = document.createElement("meta");
meta.name = "theme-color";
meta.content = "#232325";

document
  .querySelector('meta[name="theme-color"]')
  .setAttribute("content", meta.content);
