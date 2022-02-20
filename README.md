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
```

### _cmd.txt
```text
[20-01-22 03:47:35.461] 76561190000000000 "outdead" campfire.light @ 10886,10087,0.
[20-01-22 03:43:27.888] 76561190000000000 "outdead" campfire.extinguish @ 10886,10087,0.
[20-01-22 03:12:51.212] 76561190000000000 "outdead" stove.toggle @ 10882,10080,0.
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
There can be `connected`, `levelup` and `tick` events.

## Warning
Log Extender is under development and is being tested on the server [Last Day](https://last-day.wargm.ru). You can join our server or use the mod on your own server.
If you think you have found a bug, write about it in the [bug reporting topic](https://steamcommunity.com/workshop/filedetails/discussion/1844524972/1638668751263547005/)
the Steam workshop or create issue in [github repository](https://github.com/openzomboid/log-extender).

## License
Apache License 2.0, see [LICENCE](LICENSE)
