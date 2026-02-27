const fs = require("fs");
const path = require("path");

const typesDecl = fs.readFileSync(
  path.join(__dirname, "../types/index.d.ts"),
  "utf8",
);
const distDecl = fs.readFileSync(
  path.join(__dirname, "../dist/index.d.ts"),
  "utf8",
);

const merged = typesDecl + "\n\n" + distDecl;

fs.writeFileSync(path.join(__dirname, "../dist/index.d.ts"), merged);

// Remove the triple-slash reference to types/index.d.ts from the compiled JS
// since types are now merged into dist/index.d.ts
const distJs = fs.readFileSync(
  path.join(__dirname, "../dist/index.js"),
  "utf8",
);

const cleanedJs = distJs.replace(
  '/// <reference path="./types/index.d.ts" />\n',
  "",
);

fs.writeFileSync(path.join(__dirname, "../dist/index.js"), cleanedJs);
