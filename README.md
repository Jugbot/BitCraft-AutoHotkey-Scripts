```
Controls:
[F1] - Align the boxes to the corresponding UI elements. Alignments are saved to a config.
  ![image](https://github.com/user-attachments/assets/a9b8d5f0-860f-4643-aace-8129fccbbc26)
  stamina - Align covering the portion of the stamina bar you want to work in, e.g. if the stamina bar falls below the covered portion the script will do its thing.
  workbench - Align over where the workbench is in the world relative to the player. Clicking start will exit ui alignment mode.
  action - This covers the pause/resume/claim bit of the crafting ui.
  item - The item you are currently crafting under the "crafting" section on the right.
  claim - This should span the whole row of the "completed" section. Specifically, you want to make sure it encompasses the "claim" button when it appears.
[F2] - Start the crafting task
  This will continue to craft until stamina dips below a certain point. When it does, it will stop the current craft and wait until stamina recovers.
  You have to manually start the craft before running this
  *IMPORTANT* You will need to bind the interact key to `n` or modify the script.
[F3] - Automatic food refill
  This will press the eat hotket `Shift + E` every configurable minutes.
[F5] - Quit
```
