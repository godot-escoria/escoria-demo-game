# Game configuration

Aside from the common [Godot project settings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html), Escoria includes some special settings to configuration the Escoria components. These settings can be found in the "Escoria"-section in the project settings:

| Section  | Setting                 | Description                                                  |
| -------- | ----------------------- | ------------------------------------------------------------ |
| Main     | Game Start Script       | ESC-script that will be executed when the game starts        |
|          | Force Quit              | Allow quitting the game using the operating system's quit commands (Alt-F4 on Windows, Cmd-Q on macOS, etc.) |
|          | Text Lang               | Default language of texts displayed in the game              |
|          | Voice Lang              | Default language of voices                                   |
| Debug    | Terminate On Warnings   | If an Escoria warning is received, quit the game             |
|          | Terminate On Errors     | If an Escoria error is received, quit the game               |
|          | Development Lang        | Basic language the game is developed in. Useful for translation management |
|          | Log Level               | Level of log files produced. Even if this is set to DEBUG, debugging logs will not be available in production builds |
| Ui       | Tooltip Follows Mouse   | The tooltips for items in the scene follows the mouse cursor (used e.g. for mouse cursor icons UI) |
|          | Dialogs Folder          | Folder containing UI scenes related to dialogs               |
|          | Default Dialog Scene    | The scene used for dialogs                                   |
|          | Main Menu Scene         | The scene used for menus                                     |
|          | Pause Menu Scene        | The scene used when the game is paused                       |
|          | Game Scene              | The game UI used                                             |
|          | Items Autoregister Path | Path that holds ESCItems that aren't registered in a scene before, but are added to the inventory for example |
| Sound    | Music Volume            | The volume used for music                                    |
|          | Sound Volume            | The volume used for sound                                    |
|          | Speech Volume           | The volume used for voices                                   |
|          | Master Volume           | The master volume for all channels                           |
| Platform | Skip Cache              | Wether to skip caching scenes. Some platforms might not have the enough amount of memory required for this (e.g. mobile platforms) and should have this setting set to true for their respective targets |

