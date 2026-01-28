# German Law XML Tools

Tools zum Herunterladen und Durchsuchen deutscher Gesetze von gesetze-im-internet.de.

## Voraussetzungen

- Podman oder Docker

## Shell-Scripts (lokale Nutzung)

### 1. Gesetz herunterladen
```bash
./law-xml-downloader.sh <gesetz-name>
./law-xml-downloader.sh --force-update <gesetz-name>
```

### 2. Inhaltsverzeichnis anzeigen
```bash
./table-of-contents.sh <gesetz-name>
```

### 3. Paragraph extrahieren
```bash
./get-para.sh <paragraph> <gesetz-name> [absatz]
```

**Beispiele:**
```bash
./law-xml-downloader.sh estg
./table-of-contents.sh estg
./get-para.sh "§ 70" estg              # Ganzer Paragraph
./get-para.sh "§ 70" estg 2            # Nur Absatz 2
./get-para.sh "§ 70" estg "[1,3]"      # Absätze 1 und 3
```

## MCP Server (Claude Code Integration)

### Container bauen und starten

```bash
podman build -t german-law-mcp -f mcp/Dockerfile .
podman run -d --name german-law-mcp-server -v ./laws:/app/laws:Z german-law-mcp
```

### MCP in Claude Code einbinden

Erstelle `.mcp.json` im Projektverzeichnis oder füge zu `~/.claude.json` hinzu:

```json
{
  "mcpServers": {
    "german-law": {
      "command": "podman",
      "args": ["exec", "-i", "german-law-mcp-server", "node", "src/index.js"]
    }
  }
}
```

### Verfügbare MCP Tools

| Tool | Beschreibung |
|------|--------------|
| `download_law` | Gesetz von gesetze-im-internet.de herunterladen |
| `list_contents` | Inhaltsverzeichnis (alle Paragraphen) anzeigen |
| `get_paragraph` | Paragraph extrahieren (optional mit Absatz-Filter) |

### Beispiel-Prompts

```
Lade das EStG herunter und zeige mir § 32
Zeig mir das Inhaltsverzeichnis der AO
Was steht in § 1 Absatz 3 EStG?
```

## Dateistruktur

```
laws/
├── estg/
│   └── estg.xml
└── ao_1977/
    └── ao_1977.xml
```

Das `laws/` Verzeichnis ist via Volume mit dem Container synchronisiert.

## Container neu starten

```bash
podman stop german-law-mcp-server && podman rm german-law-mcp-server
podman run -d --name german-law-mcp-server -v ./laws:/app/laws:Z german-law-mcp
```
