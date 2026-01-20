| Concept     | Program level | Node Level |
|-------------|---------------|------------|
| Coordinator | Game          |EventManager| 
| Thing       | Level         | Event      |
| Pieces      | Interactables | Nodes      |

This abstraction can be applied at any scale, from the most minute scripts to larger systems. 
By seperating concerns this way scripts and nodes become more flexible to novel changes;
They become less error prone by being able to handle any errant states it encounters; 

The Coordinators job is to track, communicate, and coordinate between all the 
things its in charge of.
The Things are autonomous and have specific, singular purposes.
The Pieces are what Things use to accomplish their purpose.
	
Examples:
	Program
	- Game: Keeps track of the current state of the program; what and when to render,
	the settings, meta level progression, etc.
	- Level: Spawns and coordinates between the digital world and the logic that determines the world.
	- Nodes: Buildings blocks for various features within the game engine.
	Node:
	- EventManger: Keeps track of all the events assigned to it and 
	communicates with the parent level node based on event states.
	- Event: A goal, moment, or specific instance of something occuring within the world. 
	- Interactable/Item: Anything within the game world that the player interacts with, directly or indirectly.
