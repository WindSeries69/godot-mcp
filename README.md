[🇫🇷 Français](#fr) · [🇬🇧 English](#en)

---

# <a id="fr"></a>godot-mcp

Pont MCP entre un assistant IA et l'éditeur Godot. 6 outils pour contrôler l'éditeur : scène, nœuds, scripts, capture d'écran, exécution GDScript.

```
Assistant IA <--stdio/MCP--> godot-mcp <--WebSocket:6505--> Plugin Godot
```

## Installation

### Plugin Godot

Copiez `addons/godot_mcp/` dans le dossier `addons/` de votre projet Godot, puis activez-le : **Projet → Paramètres du projet → Plugins → godot-mcp → Activer**.

### Serveur

```bash
npm install && npm run build && npm start
```

### Configuration MCP

Ajoutez à la config de votre client MCP (`.mcp.json`, `claude.json`, `opencode.json`) :

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

Le serveur écoute sur les ports **6505–6514** (configurable via `GODOT_MCP_PORT`). Le plugin Godot s'y connecte automatiquement.

## Outils

| Outil | Description |
|-------|-------------|
| `godot_call` | Appelle n'importe quelle méthode du plugin (175+) |
| `godot_list_methods` | Liste les méthodes disponibles par catégorie |
| `godot_info` | Infos projet |
| `godot_screenshot` | Capture la vue éditeur en PNG |
| `godot_execute` | Exécute du GDScript dans l'éditeur |
| `godot_status` | Vérifie la connexion à Godot |

## Fonctionnement

Le plugin Godot se connecte à ce serveur via WebSocket (JSON-RPC 2.0). Le serveur traduit les appels d'outils MCP en requêtes JSON-RPC vers Godot, et transmet les réponses en sens inverse.

Le serveur utilise le framing WebSocket natif (modules `http` + `crypto` de Node.js), sans bibliothèque externe. Compatible Godot 4.x.

## Licence

MIT

---

# <a id="en"></a>godot-mcp

MCP bridge between an AI assistant and the Godot editor. 6 tools to control the editor: scene, nodes, scripts, screenshots, GDScript execution.

```
AI Assistant <--stdio/MCP--> godot-mcp <--WebSocket:6505--> Godot Plugin
```

## Setup

### Godot Plugin

Copy `addons/godot_mcp/` into your Godot project's `addons/` folder, then enable it: **Project → Project Settings → Plugins → godot-mcp → Enable**.

### Server

```bash
npm install && npm run build && npm start
```

### MCP Configuration

Add to your MCP client config (`.mcp.json`, `claude.json`, `opencode.json`):

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

The server listens on ports **6505–6514** (configurable via `GODOT_MCP_PORT`). The Godot plugin connects automatically.

## Tools

| Tool | Description |
|------|-------------|
| `godot_call` | Call any of the 175+ plugin methods |
| `godot_list_methods` | List available methods by category |
| `godot_info` | Project info |
| `godot_screenshot` | Capture editor viewport as PNG image |
| `godot_execute` | Run GDScript in the editor |
| `godot_status` | Check connection to Godot |

## How it works

The Godot plugin connects to this server via WebSocket (JSON-RPC 2.0). The server translates MCP tool calls into JSON-RPC requests and forwards them to Godot. Responses come back through the same channel.

The server uses raw WebSocket framing (Node.js built-in `http` + `crypto`), no library dependency. Compatible with Godot 4.x.

## License

MIT
