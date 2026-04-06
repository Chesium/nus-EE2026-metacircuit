
we have two main RAM modules to store the circuit data

- rotation constant:
  - 00: down
  - 01: right
  - 10: up
  - 11: left

- display coordinate convention:
  - (0,0) is at the top left
  - x axis is toward right (which column)
  - y axis is toward down (which row)

- screen size: 640x480@60Hz (pixels)
- circuit canvas cell size: 32x32 (pixels)
- circuit canvas grid size: 32x32 (cells) (`cellIndexWidth`: 5bit)

- CellStore (32x32 elements)
  - correspond to the cells in the circuit canvas grid
  - used for rendering
  - grid-like, each element contains:
    - sprite info
      - sprite index (like GND, horizontal wire, Resistor-Left)
      - sprite rotation type (two bits - four types of rotation)
    - corresponding component index `i` (full one for non-component e.g. wire/junctions/GNDs) so ComponentStore[i] would contain the component info for that cell
    - (metadata) other render specific bits like color overlay (reserved for future extension)

- number of nodes capped at 8 (`nodeIndexWidth`: 3bit)

- ComponentStore (64 elements (component number capped at 64))
  - correspond to each components (e.g. Resistors, Sources) in the circuit
  - later will be used as the netlist (an extension to the netlist, also containing the position & rotation metadata of the components)
  - array-like, each element contains:
    - component type (Resistor/Voltage Source/VCVS) (4 bit)
    - its value (resistor - resistance, voltage source - voltage, VCVS - gain) (10+3 bit, in XXXM form where XXX is three-digits decimal number and M is the magnitude "[000]nano(10^-9)/[001]micro(10^-6)/[010]mili(10^-3)/[011]none(10^0)/[100]kilo(10^3)/[101]mega(10^6)") 
    - node_1 & node_2 : placeholders for the flooding algorithm module to determine what nodes indices it is connected to (2×`nodeIndexWidth`bit)
    - (metadata) anchor position in the circuit canvas grid (x,y) (2x`cellIndexWidth` bit)
    - (metadata) rotation type in the circuit canvas (two bits)
    - example:
      - for a two-cell Resistor component whose anchor position (3,4) and rotation type 00, it should occupy cell (3,4) and (3,5)
      - for a two-cell Resistor component whose anchor position (1,2) and rotation type 11, it should occupy cell (1,2) and (0,2)
    - (metadata) other render specific bits like color overlay (reserved for future extension)

- frame rate: 60 frames per second (vsync rate)
- input clock rate: 100MHz
- derived pixel clock rate (for VGA display): 25MHz

- CellStore is implemented as a ping pong buffer (two copies) that get swapped at the ends of every frame (60Hz)
  - at the background, multiples steps are executed sequentially after each other to update the background CellStore and ComponentStore in one frame-processing session (about 1.66M cycle budget when using 100MHz clock)
  - part 1: interaction processing
    - mouse states are captured at the start of one frame-processing session
    - this mouse state will be fed into a FSM that takes account of the current "drawing mode" and prodcuce at most one "modifying command"
      - there are different drawing modes that can be selected by clicking the icons in the "Toolbar" window (outside of the circuit canvas display area).
        - wire drawing mode (effect: modify the cell where the cursor located to a horizontal wire - modify CellStore)
          - elbow-like wire drawing mode (ditto)
          - tee-like wire drawing mode (ditto)
          - junction-like wire drawing mode (ditto)
        - resistor drawing mode (effect: modify the cell where the cursor located to a horizontal resistor, note: this is done by modifying/appending to the ComponentStore instead of the CellStore, later we will use ComponentStore to update the component cells in the CellStore) more specifically, the anchor position will be set to the cell index where the mouse cursor is at and the rotation bits are set to the default 00
          - other component drawing mode (ditto)
        - rotate mode (effect: two cases: (1)when the user click(aka left-mousedown) on a wire/elbow/junction/tee aka non component cells, it would directly modify the CellStore and change the correponding rotation bits of the cell; (2) when the user click(aka left-mousedown) on a component cell, it would modify the rotation bits in the ComponentStore, this will later update the CellStore)
        - delete mode (two cases, delete non-component cells in the CellStore or delete the component in the ComponentStore, that may lead to some scenario where the ComponentStore is not continuous, there exists some empty component in the middle, in this case when creating components, it would try to find the smallest "empty" element to store that new component)
        - panning mode (move the canvas origin with respect to the canvas window coordinate in the screen, effectively "panning" the canvas when use is dragging inside the canvas window)
    - The above "interaction decode FSM" will output a single command (three cases)
      - empty command (like, when panning / user idle)
      - modifying CellStore (you decide the format)
      - modifying ComponentStore (you decide the format)
    - An outside "propeties editor" (link to keyboard) module will also provide such a command which will always be either:
      - empty, in this case use the command that "interaction decode FSM" provides
      - an "modifying ComponentStore" command that change the value bits of one component (use the same command format as above)
    - Now we get the command to be executed in this "frame session", the "command executor" will use one or two cycles to complete the editing
    - Use ComponentStore to update the CellStore
      - first use multiple cycles to traverse the background CellStore, clear those cells belong to a component
      - then traverse the ComponentStore and draw the two cells of each component to the background CellStore (using the anchor position & rotation bits metadata)
      - Now the CellStore is updated and is ready to be rendered in next frame session
  
    - Everything from here onward is belong to Backend

    - Flooding
      - use flooding_core to traverse the CellStore (in a Breadth-First-Search way) to fill in the node_1 and node_2 properties of the ComponentStore (also assign some nodes to be the GND)
    - Stamping
      - traverse the ComponentStore (essentially it's the netlist now), use the node_1/node_2/type/value data to build a single-precision (32bit) floating number matrix with size (8x8) and a vector with size 8
    - Solving
      - use LU Decomposition with partial pivoting algorithm to solve the linear equation and obtain the voltage value of the nodes

    - Everything from here onward is belong to Frontend
    - Use a visualization module to assign properties to the cells etc. to visualize the result.

currently we only have some kind of CircuitCanvas which corresponds to the CellStore we elaborate above

Can you explore and understand the current clumsy and chaotic codebase and try your best, take your time to find the correspondance between the existing modules and the structure we described above. Give me a report on the current situation: what parts are missing, what parts are implemented/designed/coupled poorly.

Also the current codebase has a lot issue of timing violation (as we don't have enough clock constraint specified in the .xdc file) and utilization issues (possibly due to the complex combinational logic inside the current top level module GlobalRender_top.v)

please make a concrete plan for a full refactoring and provide me with your insight and future suggestions.