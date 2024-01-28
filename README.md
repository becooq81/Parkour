# Parkour-Keyboard

A FlutterFlow project with a focus on a custom keyboard widget. 
This keyboard is implemented to be used as part of developing a machine learning model for the Parkour project.

## Functionalities
- Custom keyboard appears upon a tap on the text field (Default keyboard is not triggered)
- Upon a tap on 'Copy and Export' button, the cumulative coordinates touched by user are sent to parkour's official email
- Upon a tap on the spacebar, the cumulative coordinates are sent to server (server is not set up yet)
- Control keys (Shift, Enter, Spacebar, Backspace, etc.) acquire significantly big (impossible values in context of keyboard coordinates) coordinates to signify their property as special keys
- Special key options are narrowed down to extend touch interfaces for each key
- User can use Quick Ssentence menu for frequently used sentences

## Getting Started

FlutterFlow projects are built to run on the Flutter _stable_ release.
