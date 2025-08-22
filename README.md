# Log Extender
[![Steam Workshop](assets/steam.svg)](https://steamcommunity.com/sharedfiles/filedetails/?id=1844524972)

Log Extender mod adds more logs to the Logs directory the Project Zomboid game.  

## Description
The Log Extender mod designed for Project Zomboid servers and adds log entries that helps administering the server. The mod allows you to save information about the levels of perk character, time of his survival, number of killed zombies and other information about the character. Log Extender also adds more building and action logs such as build campfire, light and extinguish campfires, toggle ovens and more actions with vehicles.

## How to Use
This mod does not work in single player mode. Therefore, it must be installed on a dedicated Project Zomboid server. You can see logs in Zomboid/Logs directory:

### _map.txt
```text
[20-01-22 04:31:34.042] 76561190000000000 "outdead" taken IsoGenerator (appliances_misc_01_0) at 10883,10085,0.
[20-01-22 03:39:53.389] 76561190000000000 "outdead" added Campfire (camping_01_6) at 10886,10087,0.
[20-01-22 03:41:57.489] 76561190000000000 "outdead" taken Campfire (camping_01_6) at 10886,10087,0.
[12-12-22 09:17:23.997] 76561190000000000 "outdead" taken Trap (constructedobjects_01_18) at 11644,8261,0.
```

### _cmd.txt
```text
[20-01-22 03:47:35.461] 76561190000000000 "outdead" campfire.light @ 10886,10087,0.
[20-01-22 03:43:27.888] 76561190000000000 "outdead" campfire.extinguish @ 10886,10087,0.
[20-01-22 03:12:51.212] 76561190000000000 "outdead" stove.toggle @ 10882,10080,0.
```

### _pvp.txt
```text
[07-07-22 03:24:29.174] user outdead (8241,11669,0) hit user Rob Zombie (8242,11668,0) with Base.Hammer damage 1.735.
```

### _vehicle.txt
```text
[19-01-22 17:02:05.649] 76561190000000000 "outdead" attach vehicle={"id":872,"type":"VanRadio","center":"12801,3692,0"} to vehicle={"id":871,"type":"Van","center":"12807,3692,0"} at 12804,3691,0.
[19-01-22 17:02:09.762] 76561190000000000 "outdead" enter vehicle={"id":871,"type":"Van","center":"12807,3692,0"} at 12807,3691,0.
[19-01-22 17:02:16.750] 76561190000000000 "outdead" exit vehicle={"id":871,"type":"Van","center":"12807,3692,0"} at 12807,3691,0.
[19-01-22 17:02:25.635] 76561190000000000 "outdead" detach vehicle={"id":872,"type":"VanRadio","center":"12801,3692,0"} from vehicle={"id":871,"type":"Van","center":"12807,3692,0"} at 12804,3691,0.
```

### _player.txt
```text
[20-01-22 04:39:40.784] 76561190000000000 "outdead" connected perks={"Aiming":2,"Axe":0,"Blunt":0,"Cooking":0,"Doctor":0,"Electricity":0,"Farming":0,"Fishing":0,"Fitness":8,"Lightfoot":0,"LongBlade":0,"Maintenance":0,"Mechanics":10,"MetalWelding":0,"Nimble":0,"PlantScavenging":0,"Reloading":0,"SmallBlade":0,"SmallBlunt":0,"Sneak":0,"Spear":0,"Sprinting":0,"Strength":9,"Tailoring":0,"Trapping":0,"Woodwork":0} traits=["Fit","HighThirst","KeenHearing","NightVision","Organized","Outdoorsman","SlowHealer","SlowReader","Smoker","Strong","Unlucky"] stats={"profession":"unemployed","kills":0,"hours":89.04} health={"health":100,"infected":false} safehouse owner=() safehouse member=(12698x3731 - 12714x3744) (12704,3738,0).
```
There can be `connected`, `levelup`, `tick` and `death` events.

### _safehouse.txt
```text
[23-02-22 17:31:51.126] 76561198200000000 "outdead" take safehouse 10909,9397,11,11 owner="outdead".
[23-02-22 18:04:53.263] 76561198200000000 "outdead" release safehouse 10909,9397,11,11 owner="outdead" members=["rez"].
[23-02-22 17:40:16.922] 76561198200000000 "outdead" remove player from safehouse 10909,9397,11,11 owner="outdead" target="rez".
[23-02-22 17:39:09.932] 76561198200000000 "outdead" join to safehouse 10880,9401,8,11 owner="rez".
[08-07-22 04:56:39.212] 76561198200000000 "outdead" send safehouse invite 10850,9875,12,10 owner="outdead" target="Rob Zombie".
[08-07-22 04:57:00.480] 76561198100000000 "Rob Zombie" join to safehouse 10850,9875,12,10 owner="outdead".
[08-07-22 04:57:59.129] 76561198200000000 "outdead" change safehouse owner 10850,9875,12,10 owner="Rob Zombie" target="Rob Zombie".
```

### _admin.txt
```text
[08-06-22 19:55:24.798] outdead added item Rope in rez_a's inventory.
[08-06-22 19:56:09.431] outdead added item Axe in rez_a's inventory.
[08-06-22 19:56:29.599] outdead added 1 Base.Rope in outdead's inventory.
[08-06-22 19:56:29.599] outdead removed 1 Base.Rope in rez_a's inventory.
[08-06-22 19:57:05.129] outdead removed 1 Base.Rope in rez_a's inventory.
[08-06-22 19:57:27.051] outdead added 5 Base.45Clip in outdead's inventory.
[08-06-22 19:57:32.232] outdead added 2 Base.Scotchtape in outdead's inventory.
[08-06-22 19:57:38.289] outdead added 13 Base.Aerosolbomb in outdead's inventory.
[08-06-22 19:57:41.223] outdead added 1 Base.Acorn in outdead's inventory.

[09-06-22 02:39:28.470] outdead teleported to 10997,9643,0.
[09-06-22 02:42:44.499] outdead teleported to 10982,9650,0.
[09-06-22 02:43:11.187] outdead teleported to 10982,9650,0.

[25-05-24 06:13:29.246] testuser repaired vehicle CarLights at 11813,6709,0.
[25-05-24 06:14:02.396] testuser set vehicle part condition CarLights at 11813,6709,0.
[25-05-24 06:14:24.026] testuser repaired vehicle part CarLights at 11813,6709,0.
[25-05-24 06:16:14.228] testuser removed vehicle CarLights at 11815,6708,0.
[25-05-24 06:16:40.072] testuser got vehicle key ModernCar at 11818,6710,0.
[25-05-24 06:16:43.519] testuser spawned vehicle Base.CarLights at 11813,6709,0.
```

### _map_alternative.txt
```text
[12-12-22 16:56:42.982] 76561190000000000 "outdead" removed IsoObject (location_restaurant_spiffos_02_25) at 11664,8298,0 (11665,8299,0).
[12-12-22 18:03:16.876] 76561190000000000 "outdead" disassembled IsoObject (location_shop_gas2go_01_21) at 11597,8304,0 (11596,8304,0).
[22-12-22 07:56:17.435] 76561190000000000 "outdead" pickedup IsoObject (furniture_seating_indoor_02_4) at 14109,5072,0 (14109,5073,0).
```

### _craft.txt
```text
[13-12-22 02:54:16.577] 76561190000000000 "outdead" crafted 1 Base.WhiskeyEmpty with recipe "Drink Exclusive Alcohol" (11606,8296,0).
[13-12-22 02:55:00.910] 76561190000000000 "outdead" crafted 1 Base.Molotov with recipe "Make Molotov Cocktail" (11606,8296,0).
[13-12-22 02:55:19.447] 76561190000000000 "outdead" crafted 1 Base.NailsBox with recipe "Place Nails in Box" (11606,8296,0).
[13-12-22 02:56:08.041] 76561190000000000 "outdead" crafted 1 Base.SmashedBottle with recipe "Smash Bottle" (11606,8296,0).
[13-12-22 02:56:53.508] 76561190000000000 "outdead" crafted 20 Base.Nails with recipe "Open Box of Nails" (11606,8296,0).
```

## Warning
Log Extender is under development and is being tested on the server [Last Day](https://last-day.wargm.ru). You can join our server or use the mod on your own server.
If you think you have found a bug, write about it in the [bug reporting topic](https://steamcommunity.com/workshop/filedetails/discussion/1844524972/1638668751263547005/)
the Steam workshop or create issue in [github repository](https://github.com/openzomboid/log-extender).

## License
Apache License 2.0, see [LICENCE](LICENSE)
