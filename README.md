## Exploration in Multiplayer

For more information on progress navigate to the docs folder, where logs are saved when I can work on this project.

Explicit goals from outset:

- Allow up to 4 players to connect to a **HEADLESS** server. COMPLETE 2NOV25
- Spawn zombies on server side.
- Register hits and damage to zombies, shared across all clients.
- Procedurally Generated Map.

- Potentially Show at Incubator Showcase.

This study is conducted by JP at Columbia University.

## Setup
On windows if you haven't done so already add the directory the Godot executable is in to your path variable
(Optional) Rename the executable to godot.exe for eaiser use

To start the server navigate to the "multi" project directory in your terminal and run
```bash
godot --headless --path . --server
```
Now you can press play in Godot to connect to the server
(Optional) To run more then one instance at a time go to Debug -> Custom Run Instances -> Enable Multiple instances.
