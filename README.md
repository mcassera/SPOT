# S.P.O.T. (Satellite Position and Orbital Tracking)

S.P.O.T. is a SuperBASIC program for Wildbits K2/JR2 systems that tracks the International Space Station (ISS) in near real time.

The program connects to Wi-Fi through a WIZFi module, requests the ISS position from `api.open-notify.org`, and draws the current location on a world map. It also displays numeric latitude and longitude values on screen.

## What The Program Does

- Initializes graphics mode (bitmap + sprites).
- Initializes the WIZFi module with AT commands.
- Prompts for Wi-Fi credentials (or allows Enter if already connected).
- Opens a TCP connection to `api.open-notify.org:80`.
- Sends an HTTP request for `/iss-now.json`.
- Parses JSON fields:
  - `latitude`
  - `longitude`
- Converts latitude/longitude into screen coordinates on a 320x240 map.
- Draws a small ISS sprite at the current position.
- Leaves periodic trail points to show recent movement.
- Repeats continuously until you press `Q`.

## Display Behavior

- Draws a full world coastline map from built-in coordinate data.
- Prints a title banner and live ISS coordinates.
- Uses board LEDs / RGB indicators while sending and receiving WIZFi data.
- Shows reconnection attempts if position data is not parsed correctly.

## Controls

- `Q` - Exit program loop and clean up graphics state.

## Files In This Folder

- `iss.bas`
  - Main editable SuperBASIC source (line-numbered format).
- `iss.mls`
  - Upload-oriented variant of the same program (without line numbers).

Both files represent the same tracker logic and data (AT command setup, ISS sprite data, and coastline map data), just in different source formats for your workflow.

## Requirements

- Wildbits K2/JR2.
- Network connectivity with access to `api.open-notify.org`.

## Notes

- The parser is lightweight and tailored to the expected `+IPD` payload and JSON format from the API.
- HTTP is plain TCP on port 80 in this implementation.
- Timing is handled by simple delay loops, so update cadence depends on CPU speed and delay constants.
