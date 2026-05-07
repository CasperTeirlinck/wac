## User preferences (drawio skill)

Personal styling and workflow preferences. Apply these on top of the base skill instructions above. These preferences override the base skill where they conflict.

### File layout for diagrams in a project

When generating multiple diagrams in the same docs folder, keep all `.drawio` source files and their exported `.svg` variants under an `img/` subfolder, with the markdown files one level up. Markdown references look like `./img/<name>.drawio.light.svg`. Never write `.drawio` or `.svg` directly into the docs root.

### Workflow

#### Don't auto-open after every edit

When the user already has draw.io desktop open, **do not** run `open -a "draw.io" ...` after each edit — the desktop app syncs file changes automatically and re-opening is noise. Only run `open` on the very first creation of a new `.drawio` file in a session, or when the user explicitly asks. This overrides step 5 of the base "How to create a diagram" flow when the user is in an iterative session.

#### Don't export PNG and read it back

Exporting a `.drawio` to PNG and then reading the PNG via the Read tool risks an "invalid_request_error: Could not process image" 400 from the API. The error sticks to the conversation history, breaking subsequent requests. Default to **SVG** for any export — SVG is text and has no image-processing path even on accidental Read.

#### Image feedback loop — disabled by default

The "export PNG → Read it → look at the rendering → iterate" loop sounds useful but in practice produces churn — small visual issues are easier for the user to fix in draw.io desktop than for the assistant to iterate via PNG inspection. Wait for an explicit request before using this loop.

When explicitly requested:

- Export PNG with `--width 1400`, no `-e` (no embedded XML, smaller file).
- Verify file size with `ls`.
- Use `Read` on the PNG.
- Suggest **targeted edge fixes only**. Don't propose restructuring the layout.

### Export — light + dark SVG variants

Default to exporting **two** SVG variants per diagram (light and dark) so the markdown can serve the right one per viewer theme:

```bash
DRAWIO=<platform-specific draw.io CLI path; see base skill>
SRC=/path/to/file.drawio
"$DRAWIO" -x -f svg -e -b 10 --svg-theme light -o "${SRC%.drawio}.drawio.light.svg" "$SRC" >/dev/null 2>&1; LIGHT=$?
"$DRAWIO" -x -f svg -e -b 10 --svg-theme dark  -o "${SRC%.drawio}.drawio.dark.svg"  "$SRC" >/dev/null 2>&1; DARK=$?
echo "light:$LIGHT dark:$DARK"
ls -la "${SRC%.drawio}.drawio"*.svg
```

Rules:

- Always redirect stdout AND stderr to `/dev/null` so no binary or noise leaks into context.
- Verify only with `ls` (size + path). Never `Read` an exported image file.
- Always `-f svg`, not `-f png` or `-f pdf`.
- Always include `-e` (embed-diagram) so the SVG is round-trippable in draw.io.
- **Always include `--svg-theme <theme>`** — `light` for `*.drawio.light.svg`, `dark` for `*.drawio.dark.svg`. The CLI default is `auto`, which inherits the desktop app's theme. The `adaptiveColors` attribute on `<mxGraphModel>` is irrelevant for CLI exports — only `--svg-theme` controls the rendered theme.
- Use explicit theme suffixes (`.light.svg` / `.dark.svg`) — never plain `.svg` (ambiguous).
- **Never delete the source `.drawio` after export.** The user iterates on it. This overrides the base skill's "delete the intermediate `.drawio` file" instruction.

### Markdown reference pattern

Use **plain markdown image syntax** referencing the **light** SVG. The `<picture>` element with `prefers-color-scheme` is tempting for theme-aware switching, but Bitbucket Cloud's markdown renderer doesn't strip the `<picture>`/`<source>` wrapper tags — it shows them as literal text while still rendering the inner `<img>`, which looks broken. Plain markdown is the lowest common denominator and renders cleanly everywhere.

The dark SVG is still emitted (so anyone can open it directly) and is referenced as a link in prose.

```markdown
## Architecture

![<topic> architecture](./img/<topic>.drawio.light.svg)

Source: [`<topic>.drawio`](./img/<topic>.drawio). Dark-theme variant: [`<topic>.drawio.dark.svg`](./img/<topic>.drawio.dark.svg).
```

When the docs run on a renderer that supports MDX (Docusaurus, Astro), the theme-aware swap can be re-introduced via a `<ThemedImage>` (Docusaurus) or equivalent component.

### Grid alignment (10pt grid)

All shape top-left corners and edge waypoints must be at multiples of 10 (the standard draw.io 10pt grid). When the user has grid-snap enabled and tries to move an off-grid element, it jumps unexpectedly.

Audit checklist:

- All `<mxGeometry x="..." y="...">` values multiples of 10.
- All `<mxPoint x="..." y="..."/>` waypoint values multiples of 10.
- Container/box `width` and `height` multiples of 10.

Vendor stencil icons (AWS resourceIcons at 78x78, Kubernetes pod icons at 38.54x37, etc.) are conventionally not multiples of 10 — leave their sizes intact, but always position their top-left at multiples of 10.

### Padding inside nested containers

Use **40 px** of padding between a container's edges and its children — "1 grid block" of 4×10 px units. Apply recursively (e.g., 40 px between an outer cloud-account container and an inner cluster, 40 px between the cluster and its inner pods).

### First version is often best — don't aggressively restructure

When asked to revise a diagram layout based on issues, prefer **targeted fixes to specific arrows / labels** over wholesale layout rewrites. The first layout produced is usually closer to the user's mental model.

If the user says "the arrows are spaghetti", the answer is usually:

1. Fix individual edge anchors and waypoints.
2. Possibly re-order siblings within a container so paths don't cross icons.

Not:

- Wholesale move of containers / repositioning major components / merging components that should stay separate.

If the user explicitly asks for a layout restructure, do it. Otherwise, edit minimally.

### Edge style defaults

Every edge should use this base style snippet:

```
edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;labelBackgroundColor=none;endArrow=blockThin;endFill=1;jumpStyle=arc;
```

Pieces:

- `endArrow=blockThin;endFill=1;` — thin filled block arrowhead. Reads as more architectural / less "casual flowchart".
- `labelBackgroundColor=none` — default. The label sits transparent on the line; offset it perpendicular (see below) so the line and text don't overlap.
- `jumpStyle=arc` — when this edge crosses another edge, render a small arc bump so it's clear which line is "above" the other. Setting this on every edge is harmless when no crossings occur.

#### Edge anchor points

Without explicit anchors, draw.io picks a face on the source/target shape and the resulting routing often crosses other shapes. Pin both ends to specific edges using `entryX/entryY/entryDx/entryDy` and `exitX/exitY/exitDx/exitDy`:

- Left edge, vertical middle: `entryX=0;entryY=0.5;entryDx=0;entryDy=0;` (or `exit*` for source)
- Right edge: `entryX=1;entryY=0.5;`
- Top: `entryX=0.5;entryY=0;`
- Bottom: `entryX=0.5;entryY=1;`

When an edge goes from a shape inside one container to a shape outside it (or simply across a busy area), set explicit anchors on at least the side facing the other shape. For paired edges that should appear parallel (e.g., two arrows going from a hub to two stacked targets), pin them to the same face of the hub.

#### Edge waypoints

Use `<Array as="points">` with `<mxPoint x="..." y="..." />` entries to force the edge to bend at specific coordinates. Useful for routing through empty corridors so multiple parallel edges don't cross each other or run through other shapes:

```xml
<mxGeometry relative="1" as="geometry">
  <Array as="points">
    <mxPoint x="360" y="259"/>
    <mxPoint x="360" y="200"/>
  </Array>
</mxGeometry>
```

#### Label positioning

The `x` and `y` attributes on the edge's `<mxGeometry>` control the label's position:

- `x` is **fractional position along the edge** (0 = at source, 1 = at target).
- `y` is the **perpendicular offset in pixels**. Positive = below the line, negative = above.

Default: offset the label slightly off the line so it doesn't overlap the arrow.

- Label above the line: `y="-10"`.
- Label below the line: `y="10"`.

#### Label background

- **Default**: `labelBackgroundColor=none` + perpendicular y offset that keeps the label clear of any shape. Simplest and cleanest when there's open space around the edge.
- **Use `labelBackgroundColor=default`** (white) only when the label *cannot* avoid overlapping a shape's stroke or another visual element. The opaque background hides what's underneath so the text stays readable.

#### Bidirectional arrows for fetch / query / pull

A round-trip relationship (clone, pull, query, fetch where data comes back) is drawn as a **bidirectional arrow**: add both `startArrow=blockThin;startFill=1;` and `endArrow=blockThin;endFill=1;`.

Heuristic: if the operation is "I send a request and the meaningful response is a payload" (clones, pulls, large responses), use bidirectional. If the meaningful direction is just "I write or read once and continue", use one-way.

#### Sizing for connected boxes

When two boxes inside a container are connected by an arrow with a text label, leave **enough horizontal gap** so the label fits between the boxes without crowding either box's stroke or text. A reasonable default: gap between two horizontally-adjacent siblings ≥ ~120 px.

#### Label wording

Prefer slightly descriptive, terse labels: `credentials` rather than `creds`, `helm charts` rather than `clone (helm charts)`. Avoid parentheticals when the verb is clear from context.

### Custom service icons (non-vendor services)

For services that don't have a built-in stencil, prefer in this order:

1. **Built-in draw.io stencils** (smallest file size, no base64 needed). The `mxgraph.weblogos.<name>` family covers many tech logos (GitHub, etc.). Search the shape library by name. For cloud services, prefer `mxgraph.aws4.*`, `mxgraph.azure2.*`, `mxgraph.gcp.*`. For Kubernetes-related shapes, `mxgraph.kubernetes.*`.

2. **Embedded base64 PNG/SVG** for logos with no built-in stencil:

   ```
   shape=image;verticalLabelPosition=bottom;labelBackgroundColor=none;verticalAlign=top;aspect=fixed;imageAspect=0;image=data:image/png,<base64-payload>;
   ```

   For variants with the label to the right: `verticalLabelPosition=middle;verticalAlign=middle;align=left;labelPosition=right;`.

   **Data URL format gotcha**: draw.io expects the comma-only shorthand `data:image/<fmt>,<base64>`, NOT the standard MIME form `data:image/<fmt>;base64,<base64>`. With the standard form (with `;base64,`), the image renders as a missing-image icon both in the desktop app and the exported SVG.
   - SVG: `data:image/svg+xml,<base64>` ✓
   - PNG: `data:image/png,<base64>` ✓
   - SVG: `data:image/svg+xml;base64,<base64>` ✗ does not render

3. **Plain labeled rectangle** as a last resort.

#### Avoid `image=img/lib/...` runtime path references

The `image=img/lib/<vendor>/<File>.svg` references that appear when dragging stencils from draw.io's shape browser only resolve at runtime in the desktop app. They look fine in the editor but render as missing-image icons in CLI-exported SVGs (the export doesn't bundle the referenced file). Either use a vector stencil shape (`shape=mxgraph.<library>.<name>`) or embed the asset as a data URL.

#### Extracting logos from the draw.io app bundle

When you need to embed an `img/lib/...` asset that's only referenced as a runtime path:

```bash
# 1. Extract from the asar archive (path inside asar has NO leading slash)
TMPDIR=$(mktemp -d) && cd "$TMPDIR"
npx --yes @electron/asar extract-file \
  <path-to-app.asar> \
  drawio/src/main/webapp/img/lib/<vendor>/<File>.svg

# 2. Encode as base64
B64=$(base64 < <File>.svg | tr -d '\n')

# 3. Substitute into the .drawio (use comma-only data URL format)
sed -i.bak "s|image=img/lib/<vendor>/<File>.svg|image=data:image/svg+xml,$B64|g" /path/to/file.drawio
rm /path/to/file.drawio.bak
```

Locations of `app.asar`:

- macOS: `/Applications/draw.io.app/Contents/Resources/app.asar`
- Windows: `C:\Users\<user>\AppData\Local\Programs\draw.io\resources\app.asar`
- Linux: depends on install method (often `/opt/drawio/resources/app.asar` or `/usr/lib/drawio-desktop/resources/app.asar`)

### AWS service icon names

When using `shape=mxgraph.aws4.resourceIcon`, the `resIcon=` value uses the **short / acronym** form, not the expanded service name. Use the AWS service acronym (e.g., `eks`, `s3`, `ec2`, `rds`, `iam`, `lambda`, `vpc`, `ecr`). Fall back to the expanded form (`elastic_kubernetes_service`, `simple_storage_service`, etc.) only if the acronym doesn't render the inner glyph for that service.

For `aws4.group` containers, the `grIcon=` values use the `group_*` prefix (e.g., `group_aws_cloud_alt`, `group_account`, `group_vpc`).

### Schedule indicator

For services triggered on a schedule (e.g., a CodeBuild + EventBridge cron pair), prefer a `⏱️` emoji + cadence inline in the icon's label (e.g., `<service-name><br>⏱️<i>daily</i>`), **not** a separate scheduling-service icon. Keeps the diagram focused on functional components rather than the scheduling mechanism.
