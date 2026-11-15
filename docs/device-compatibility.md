# Device compatibility checks

Gem targets iPhone and iPad on iOS/iPadOS 26 or later. Layout follows the
current window width: at 700 points or wider the menu can stay visible as a
300-point sidebar; below that it becomes a drawer. The sidebar is shown by
default. The leading toolbar button shows or hides it, including while a
thread is open, and the choice is preserved through window resizing.
Selecting a section or recent story keeps a visible wide sidebar open.
Narrow drawers leave at least 60 points of the main view visible. The same
navigation stack is used at every width.

The navigation stack is not clipped to the safe-area bounds, so its native
background can extend behind the status bar and home indicator. The app
uses the system background, while navigation content and sidebar controls
continue to respect their safe-area insets.

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
| Home in portrait and landscape, light and dark appearance | No contrasting strips above or below the navigation view; content stays clear of the status bar, camera cutout, and home indicator. |
| iPad portrait and landscape, including iPad mini | Native full-resolution app; sidebar is shown by default when the usable window width is at least 700 points. |
| Repeatedly press the leading sidebar toolbar button, including with a thread open | Sidebar shows and hides, main content uses the available width, and the thread and navigation path remain intact. |
| iPad Split View or window resizing | Sidebar changes to a drawer below 700 points; no stale drawer offset remains. |
| Repeated resizing across 699/700 points with a thread open | The thread, navigation path, and reading position remain intact. |
| Hide the wide sidebar, resize below 700 points, then widen again; repeat with it shown | The chosen wide-sidebar visibility is restored; compact windows still use the drawer. |
| Resize or rotate with a drawer gesture in progress | Drawer closes and temporary drag offset resets. |
| Switch among Home, Pins, Favorites, Replies, and Search | Highlight matches the selected section; switching returns to that section's root. The wide sidebar stays open after selection. |
| Open a recent story | Drawer closes and the story opens; on a wide window the sidebar stays visible. |
| Open Settings, profile, search, reply, or Safari sheets, then resize | Sheet remains usable and dismisses normally. |
| Share from a story menu or comment context menu | Native share UI opens from the active view; both story and HN links share correctly on iPad. |
| Show the keyboard in a short window | Login/settings controls and scrollable menu remain reachable. |

Also verify offline reading, deep links, the Time Machine gesture, and
VoiceOver navigation after rotation. Separate simultaneous app windows are
outside this change; navigation still uses the existing shared router.
