-- pandoc filter for md-show: render ```mermaid code blocks to inline SVG with mmdc, so pages need no script.
local config = pandoc.path.join({ pandoc.path.directory(PANDOC_SCRIPT_FILE), "mermaid.json" })
local count = 0

function CodeBlock(block)
  if not block.classes:includes("mermaid") then
    return nil
  end
  count = count + 1
  local ok, svg = pcall(pandoc.pipe, "mmdc", {
    "--input", "-", "--output", "-", "--outputFormat", "svg", "--quiet",
    "--theme", "neutral", "--backgroundColor", "transparent",
    "--configFile", config, "--svgId", "mermaid-" .. count,
  }, block.text)
  if not ok then
    io.stderr:write("md-show: Mermaid diagram " .. count .. " failed to render, shown as code\n")
    return nil
  end
  return pandoc.RawBlock("html", '<figure class="diagram">' .. svg .. "</figure>")
end
