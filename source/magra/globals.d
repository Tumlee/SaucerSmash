module magra.globals;

import derelict.sdl2.sdl;

import magra.canvas;
import magra.input;
import magra.actorlist;
import magra.gameloop;

//Various global objects used by the Magra engine.
Canvas canvas;
Mouse mouse;
Keyboard keyboard;
ActorList actors;
GameLoop gameLoop;
TextBuffer textBuffer;

//The SDL window and renderer.
SDL_Renderer* renderer;
SDL_Window* window;

//In the Windows version of SDL2, there appears to be a bug where the cursor
//is allowed to escape outside of the play area in the fake "fullscreen" mode.
//Therefore, we have to use a different fullscreen flag in Windows versus other
//operating systems.
version(Windows)
{
    enum int osSpecificFullscreenFlag = SDL_WINDOW_FULLSCREEN;
}
else
{
    enum int osSpecificFullscreenFlag = SDL_WINDOW_FULLSCREEN_DESKTOP;
}