# Device compatibility checks

Gem targets iPhone and iPad on iOS/iPadOS 26 or later. Layout follows the
current window width: at 800 points or wider the menu stays visible as a
300-point sidebar; below that it becomes a drawer. Narrow drawers leave at
least 60 points of the main view visible. The same navigation stack is used
at every width.

“iPhone Duo” is treated as a resizable/foldable iPhone layout. No model-name
checks or assumed hardware dimensions are required. Hardware-specific
validation is pending access to the device and its SDK/simulator.

## Automated checks

The iOS compatibility PR workflow builds the Gem scheme for a generic iOS
Simulator in Debug and Release without signing. It checks the built app's
Info.plist for both device families, iPhone landscape support, all four iPad
orientations, and absence of a full-screen requirement.

## Manual validation on macOS

Run the Gem scheme in Xcode on an iPhone and an iPad simulator with iOS 26+
and repeat in light and dark appearance. These checks require a simulator
or device; the workflow does not exercise the UI.

| Scenario | Expected behavior |
| --- | --- |
| iPhone portrait, including a narrow window | Drawer opens from the menu button or left-edge swipe; rows and footer remain reachable. |
| iPhone landscape | Content respects the camera cutout and home indicator; header, menu list, and footer fit or scroll. |
| iPad portrait and landscape | Native full-resolution app; sidebar appears when the usable window width is at least 800 points. |
| iPad Split View or window resizing | Sidebar changes to a drawer below 800 points; no stale drawer offset remains. |
| Repeated resizing across 799/800 points with a thread open | The thread, navigation path, and reading position remain intact. |
| Resize or rotate with a drawer gesture in progress | Drawer closes and temporary drag offset resets. |
| Switch among Home, Pins, Favorites, Replies, and Search | Highlight matches the selected section; switching returns to that section's root. |
| Open a recent story | Drawer closes and the story opens; on a wide window the sidebar stays visible. |
| Open Settings, profile, search, reply, or Safari sheets, then resize | Sheet remains usable and dismisses normally. |
| Share from a story menu or comment context menu | Native share UI opens from the active view; both story and HN links share correctly on iPad. |
| Show the keyboard in a short window | Login/settings controls and scrollable menu remain reachable. |

Also verify offline reading, deep links, the Time Machine gesture, and
VoiceOver navigation after rotation. Separate simultaneous app windows are
outside this change; navigation still uses the existing shared router.
