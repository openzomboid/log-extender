# pz-mod-log-extender
Log Extender mod adds more logs to the Logs directory the Project Zomboid game. 

## Project Zomboid Lua mod
[README.md](Contents/mods/LogExtender/README.md)

## Perk Types

#### Json format
    
```json
{
  "Agility": {
    "Lightfoot": 10,
    "Nimble": 10,
    "Sneak": 10,
    "Sprinting": 10
  },
  "BladeParent": {
    "Axe": 10,
    "BladeGuard": 10,
    "BladeMaintenance": 10
  },
  "BluntParent": {
    "Blunt": 10,
    "BluntGuard": 10,
    "BluntMaintenance": 10
  },
  "Crafting": {
    "Cooking": 10,
    "Doctor": 10,
    "Electricity": 10,
    "Farming": 10,
    "Mechanics": 10,
    "MetalWelding": 10,
    "Woodwork": 10
  },
  "Firearm": {
    "Aiming": 10,
    "Reloading": 10
  },
  "Passiv": {
    "Fitness": 10,
    "Strength": 10
  },
  "Survivalist": {
    "Fishing": 10,
    "PlantScavenging": 10,
    "Trapping": 10
  }
}
```

#### Yaml format

```yaml
Agility:
  Lightfoot: 10
  Nimble: 10
  Sneak: 10
  Sprinting: 10
BladeParent:
  Axe: 10
  BladeGuard: 10
  BladeMaintenance: 10
BluntParent:
  Blunt: 10
  BluntGuard: 10
  BluntMaintenance: 10
Crafting:
  Cooking: 10
  Doctor: 10
  Electricity: 10
  Farming: 10
  Mechanics: 10
  MetalWelding: 10
  Woodwork: 10
Firearm:
  Aiming: 10
  Reloading: 10
Passiv:
  Fitness: 10
  Strength: 10
Survivalist:
  Fishing: 10
  PlantScavenging: 10
  Trapping: 10
```

#### Json Lite format 

```json
{
  "Lightfoot": 10,
  "Nimble": 10,
  "Sneak": 10,
  "Sprinting": 10,
  "Axe": 10,
  "BladeGuard": 10,
  "BladeMaintenance": 10,
  "Blunt": 10,
  "BluntGuard": 10,
  "BluntMaintenance": 10,
  "Cooking": 10,
  "Doctor": 10,
  "Electricity": 10,
  "Farming": 10,
  "Mechanics": 10,
  "MetalWelding": 10,
  "Woodwork": 10,
  "Aiming": 10,
  "Reloading": 10,
  "Fitness": 10,
  "Strength": 10,
  "Fishing": 10,
  "PlantScavenging": 10,
  "Trapping": 10
}
```

## License
Apache License 2.0, see [LICENCE](LICENSE)
