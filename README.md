## Controls

### [F1] - Align UI Boxes
Align the boxes to the corresponding UI elements. Alignments are saved to a config.

![UI Alignment Example](https://github.com/user-attachments/assets/a9b8d5f0-860f-4643-aace-8129fccbbc26)

- **stamina**: Align to cover the portion of the stamina bar you want to monitor. If stamina falls below this, the script will act.
- **workbench**: Align over the workbench's position relative to the player. Clicking "Start" exits UI alignment mode.
- **action**: Covers the pause/resume/claim area of the crafting UI.
- **item**: The item currently being crafted under the "crafting" section on the right.
- **claim**: Should span the entire row of the "completed" section, ensuring it covers the "claim" button when it appears.

---

### [F2] - Start Crafting Task
Begins crafting and continues until stamina drops below a set threshold. The script will pause crafting and wait for stamina to recover.

> **Note:**  
> - You must manually start crafting before running this.
> - **IMPORTANT:** Bind the interact key to `n` or modify the script.

---

### [F3] - Automatic Food Refill
Automatically presses the eat hotkey (`Shift + E`) at configurable intervals.

---

### [F5] - Quit
Exits the script.

