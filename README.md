[🇫🇷 Français](#fr) · [🇬🇧 English](#en)

---

# <a id="fr"></a>godot-mcp

Pont MCP entre un assistant IA et l'éditeur Godot.

```
Assistant IA <---stdio/MCP---> godot-mcp <---WebSocket:6505---> Plugin Godot
```

**6 outils MCP** pour piloter l'éditeur : `godot_call` (175+ méthodes), `godot_list_methods`, `godot_info`, `godot_screenshot`, `godot_execute`, `godot_status`.

## Installation

### 1. Plugin Godot

Copiez le dossier `plugin/` dans `addons/plugin/` de votre projet Godot.

```
votre-projet/
└── addons/
    └── plugin/          ← copiez plugin/ ici
```

Activez-le : **Projet → Paramètres du projet → Plugins → godot-mcp → Activer**

### 2. Serveur

```bash
npm install && npm run build && npm start
```

### 3. Client MCP

Ajoutez à la config de votre client IA (`.mcp.json`, `claude.json`, `opencode.json`) :

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "node",
      "args": ["/chemin/vers/godot-mcp/dist/index.js"]
    }
  }
}
```

## Outils

| Outil | Description |
|-------|-------------|
| `godot_call` | Appelle n'importe quelle méthode (175+) |
| `godot_list_methods` | Liste les méthodes par catégorie |
| `godot_info` | Infos projet |
| `godot_screenshot` | Capture éditeur en PNG |
| `godot_execute` | Exécute du GDScript |
| `godot_status` | Vérifie la connexion |

## Arborescence

```
godot-mcp/
├── plugin/              ← Plugin Godot (à copier dans votre projet)
├── src/index.ts         ← Serveur MCP (Node.js)
├── package.json
├── tsconfig.json
├── README.md
└── LICENSE              ← MIT
```

## Licence

MIT

---

# <a id="en"></a>godot-mcp

MCP bridge between an AI assistant and the Godot editor.

```
AI Assistant <---stdio/MCP---> godot-mcp <---WebSocket:6505---> Godot Plugin
```

**6 MCP tools** to control the editor: `godot_call` (175+ methods), `godot_list_methods`, `godot_info`, `godot_screenshot`, `godot_execute`, `godot_status`.

## Setup

### 1. Godot Plugin

Copy the `plugin/` folder into your project's `addons/plugin/`.

```
your-project/
└── addons/
    └── plugin/          ← copy plugin/ here
```

Enable it: **Project → Project Settings → Plugins → godot-mcp → Enable**

### 2. Server

```bash
npm install && npm run build && npm start
```

### 3. MCP Client

Add to your AI client config (`.mcp.json`, `claude.json`, `opencode.json`):

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "node",
      "args": ["/path/to/godot-mcp/dist/index.js"]
    }
  }
}
```

## Tools

| Tool | Description |
|------|-------------|
| `godot_call` | Call any method (175+) |
| `godot_list_methods` | List methods by category |
| `godot_info` | Project info |
| `godot_screenshot` | Editor screenshot in PNG |
| `godot_execute` | Run GDScript |
| `godot_status` | Check connection |

## Structure

```
godot-mcp/
├── plugin/              ← Godot plugin (copy to your project)
├── src/index.ts         ← MCP server (Node.js)
├── package.json
├── tsconfig.json
├── README.md
└── LICENSE              ← MIT
```

## License

MIT
