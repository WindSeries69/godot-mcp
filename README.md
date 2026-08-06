[🇫🇷 Français](#fr) · [🇬🇧 English](#en)

---

# <a id="fr"></a>godot-mcp

Pont MCP entre un assistant IA et l'éditeur Godot. 6 outils pour contrôler l'éditeur : scène, nœuds, scripts, capture d'écran, exécution GDScript, et 175+ méthodes via `godot_call`.

```
Assistant IA <--stdio/MCP--> godot-mcp <--WebSocket:6505--> Plugin Godot
```

## Installation

### Plugin Godot

Copiez le dossier `addons/godot_mcp/` dans `addons/` de votre projet Godot, puis activez-le : **Projet → Paramètres → Plugins → godot-mcp → Activer**

### Serveur

```bash
npm install && npm run build && npm start
```

### Configuration MCP

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

Le serveur écoute sur les ports **6505–6514** (`GODOT_MCP_PORT` pour changer). Le plugin Godot s'y connecte automatiquement.

## Outils

| Outil | Description |
|-------|-------------|
| `godot_call(method, params)` | Appelle n'importe quelle méthode du plugin (175+) |
| `godot_list_methods(category?)` | Liste les méthodes par catégorie |
| `godot_info` | Infos projet |
| `godot_screenshot` | Capture la vue éditeur en PNG |
| `godot_execute(code)` | Exécute du GDScript |
| `godot_status` | Vérifie la connexion |

## Licence

MIT

---

# <a id="en"></a>godot-mcp

MCP bridge between an AI assistant and the Godot editor. 6 tools to control the editor: scene, nodes, scripts, screenshots, GDScript execution, and 175+ methods via `godot_call`.

```
AI Assistant <--stdio/MCP--> godot-mcp <--WebSocket:6505--> Godot Plugin
```

## Setup

### Godot Plugin

Copy `addons/godot_mcp/` into your Godot project's `addons/` folder, then enable it: **Project → Project Settings → Plugins → godot-mcp → Enable**

### Server

```bash
npm install && npm run build && npm start
```

### MCP Config

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

Listens on ports **6505–6514** (`GODOT_MCP_PORT` to change). Auto-connects to Godot.

## Tools

| Tool | Description |
|------|-------------|
| `godot_call(method, params)` | Call any of the 175+ plugin methods |
| `godot_list_methods(category?)` | List methods by category |
| `godot_info` | Project info |
| `godot_screenshot` | Capture editor viewport as PNG |
| `godot_execute(code)` | Run GDScript |
| `godot_status` | Check connection |

## License

MIT
