# M2 UI assumptions

These extend the M1 assumptions. M1 human acceptance does not cover them.
Behavior is based on `docs/ComponentPropertyPanel_Verification.md`,
`docs/ComponentPropertyPanel_Fix.md`, `structure.md` and the extracted keypad
layout. The two property documents describe Enter/Escape keys and initialization
data that the current keypad/boot interface does not expose. The choices below
resolve that gap explicitly; they require M2 human validation.

## M2-A001 Selection and editing

A canvas press selects its cell, including an empty cell, wire or ground. Either
component half exposes the same editable value. Position text keeps the clicked
coordinates, while the component's stored coordinates identify its anchor.
Canvas selection closes editing. Clicking the value rectangle (224..335,
24..43) activates editing for a component. Other property-panel clicks retain
selection and close editing. Keypad clicks retain selection and editing state;
outside clicks clear selection. Tool actions still execute with M1 semantics.

## M2-A002 Immediate value edits

The keypad exposes digits, unit prefixes, dot, DEL and RST, so each accepted key
updates the component immediately. There is no separate commit/cancel operation.
The literal text has eight character positions. Resistance has a fixed three
digit BCD field; other parts have two digit positions. Digits fill positions from
left to right and unused positions contain zero. A dot is retained in display
text but does not introduce a floating-point exponent into the BCD storage.
The last unit prefix in the text determines the unit. Extra numeric characters
after the field width remain visible but do not add BCD positions.

DEL removes the last literal character and reconstructs the digits and unit from
the remaining text. In particular, deleting `k` from `123k` leaves BCD `123`.
The old RTL deleted a numeric digit for every DEL, including suffix deletion;
that violated the documented backspace action and was corrected. Both halves of
the component receive identical value, unit and display text.

## M2-A003 RST

In active editing, RST clears the selected component's numeric value, unit and
literal text. With no editable component selected, it clears the whole canvas.
With an editable component selected but editing inactive, keypad edits have no
effect. The scenario resets each field before editing so stored boot text cannot
ambiguously imply replace-versus-append behavior.

## M2-A004 Frame sampling

Keypad hover, pressed styling and press edges use the same frame-latched mouse
snapshot as cursor/toolbar/canvas. Each press emits one event; holding never
repeats, and dragging a held button onto another key never types it. Input takes
effect one frame after a back-porch update (A-003). The free-running 20 Hz mouse
sampling path is removed from the active VGA keypad. Key events toggle in the
pixel domain and synchronize into the system domain. Tests exercise single-frame
presses, suffix deletion, selection retention and inactive-edit rejection.
