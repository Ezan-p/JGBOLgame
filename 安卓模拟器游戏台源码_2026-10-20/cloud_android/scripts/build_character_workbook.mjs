import fs from "node:fs/promises";
import path from "node:path";
import { Workbook, SpreadsheetFile } from "@oai/artifact-tool";

const outputDir = path.resolve(process.argv[2] || "outputs/characters-20261020");
const previewDir = path.resolve(".runtime/character-report-previews");
const report = JSON.parse(await fs.readFile(path.join(outputDir, "character_report.json"), "utf8"));
const workbook = Workbook.create();
await fs.mkdir(previewDir, { recursive: true });

function wrapCell(value, width) {
  if (typeof value !== "string") return value;
  const capacity = Math.max(6, width - 3);
  let line = "", used = 0;
  const lines = [];
  for (const c of value) {
    const weight = c.charCodeAt(0) > 255 ? 2 : 1;
    if (c === "\n" || used + weight > capacity) {
      lines.push(line); line = ""; used = 0;
      if (c === "\n") continue;
    }
    line += c; used += weight;
  }
  lines.push(line);
  return lines.join("\n");
}

for (const [index, data] of report.sheets.entries()) {
  const sheet = workbook.worksheets.add(data.name);
  sheet.showGridLines = false;
  if (index === 0) sheet.tabColor = "#653C70";
  const height = data.rows.length + 5;
  const grid = sheet.getRangeByIndexes(0, 0, height, data.columns.length);
  grid.format.font = { name: "Arial", size: 11, color: "#252A32" };
  grid.format.verticalAlignment = "top";
  sheet.getRange("A2").values = [[data.title]];
  sheet.getRange("A2").format.font = { name: "Arial", size: 17, bold: true, color: "#653C70" };
  sheet.getRange("A2").format.rowHeight = 32;
  sheet.getRange("A3").values = [[data.note]];
  sheet.getRange("A3").format.font = { name: "Arial", size: 11, italic: true, color: "#555B63" };
  const displayRows = data.rows.map(row => row.map((value, col) => wrapCell(value, data.widths[col])));
  sheet.getRangeByIndexes(4, 0, data.rows.length + 1, data.columns.length).values = [data.columns, ...displayRows];
  const header = sheet.getRangeByIndexes(4, 0, 1, data.columns.length);
  header.format.fill = "#46324E";
  header.format.font = { name: "Arial", size: 11, bold: true, color: "#FFFFFF" };
  header.format.horizontalAlignment = "center";
  header.format.verticalAlignment = "center";
  header.format.rowHeight = 30;
  header.format.borders = { insideVertical: { style: "thin", color: "#FFFFFF" } };
  const body = sheet.getRangeByIndexes(5, 0, data.rows.length, data.columns.length);
  body.format.wrapText = true;
  body.format.rowHeight = 33;
  data.widths.forEach((width, col) => {
    sheet.getRangeByIndexes(0, col, height, 1).format.columnWidth = width;
  });
  // Size only rows requiring long descriptions; keep full text visible after filtering.
  displayRows.forEach((values, row) => {
    let lines = 1;
    values.forEach((value, col) => {
      if (typeof value !== "string") return;
      const capacity = Math.max(6, data.widths[col] - 2);
      const count = value.split("\n").reduce((sum, part) => {
        const chars = [...part].reduce((n, c) => n + (c.charCodeAt(0) > 255 ? 2 : 1), 0);
        return sum + Math.max(1, Math.ceil(chars / capacity));
      }, 0);
      lines = Math.max(lines, count);
    });
    const range = sheet.getRangeByIndexes(row + 5, 0, 1, data.columns.length);
    range.format.rowHeight = Math.min(400, Math.max(33, lines * 16 + 10));
    if (row % 2 === 1) range.format.fill = "#F4F1F6";
  });
  const lastColumn = String.fromCharCode(64 + data.columns.length);
  const table = sheet.tables.add(`A5:${lastColumn}${height}`, true, "Characters" + index);
  table.style = "TableStyleLight1";
  table.showFilterButton = true;
  sheet.freezePanes.freezeRows(5);
  sheet.freezePanes.freezeColumns(Math.min(2, data.columns.length - 1));
  // Columns are wide intentionally: descriptive material should remain legible.
}
workbook.recalculate();
console.log((await workbook.inspect({
  kind: "table", range: "神仙介绍!A5:F9", include: "values,formulas",
  tableMaxRows: 5, tableMaxCols: 6, maxChars: 2500,
})).ndjson);
console.log((await workbook.inspect({
  kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#NUM!|#SPILL!",
  options: { useRegex: true, maxResults: 10 }, maxChars: 800,
})).ndjson);
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(path.join(outputDir, "神仙角色介绍表.xlsx"));
for (const data of report.sheets) {
  const preview = await workbook.render({
    sheetName: data.name, range: data.name === "阅读说明" ? "A1:B9" : "A1:F8",
    scale: 1, format: "png",
  });
  await fs.writeFile(path.join(previewDir, data.name + ".png"), new Uint8Array(await preview.arrayBuffer()));
}
console.log("Exported 神仙角色介绍表.xlsx");
