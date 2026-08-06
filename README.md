[🇫🇷 Français](#fr) · [🇬🇧 English](#en)

---

# <a id="fr"></a>godot-mcp

Pont MCP entre un assistant IA et l'éditeur Godot. Exécutez du GDScript, capturez l'écran, inspectez le projet — le tout depuis votre agent IA.

```
Assistant IA <--stdio/MCP--> godot-mcp <--WebSocket:6505--> Plugin Godot
```

## Installation

### Plugin Godot

Copiez ces 3 fichiers dans `addons/godot_mcp/` de votre projet Godot :

- `plugin.cfg`
- `plugin.gd`
- `ws.gd`

Activez le plugin : **Projet → Paramètres → Plugins → godot-mcp → Activer**

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
| `godot_execute(code)` | Exécute du GDScript dans l'éditeur. Le `return` est explicite. |
| `godot_info` | Infos du projet (nom, version) |
| `godot_screenshot` | Capture la vue éditeur en PNG |
| `godot_status` | Vérifie la connexion à Godot |

### Exemples godot_execute

```
Engine.get_version_info()
EditorInterface.get_open_scenes()
get_node("/root").get_children().map(func(n): return n.name)
var s = EditorInterface.get_selection().get_selected_nodes(); s.map(func(n): return n.name)
```

## Licence

MIT

---

# <a id="en"></a>godot-mcp

MCP bridge between an AI assistant and the Godot editor. Run GDScript, take screenshots, inspect your project — all from your AI agent.

```
AI Assistant <--stdio/MCP--> godot-mcp <--WebSocket:6505--> Godot Plugin
```

## Setup

### Godot Plugin

Copy these 3 files into your project's `addons/godot_mcp/`:

- `plugin.cfg`
- `plugin.gd`
- `ws.gd`

Enable it: **Project → Project Settings → Plugins → godot-mcp → Enable**

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
| `godot_execute(code)` | Run GDScript in the editor. Use explicit `return`. |
| `godot_info` | Project info (name, version) |
| `godot_screenshot` | Capture editor viewport as PNG |
| `godot_status` | Check Godot connection |

### godot_execute examples

```
Engine.get_version_info()
EditorInterface.get_open_scenes()
get_node("/root").get_children().map(func(n): return n.name)
var s = EditorInterface.get_selection().get_selected_nodes(); s.map(func(n): return n.name)
```

## License

MIT
