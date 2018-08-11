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

//================================
//Initialize global Magra objects.
//================================
static this()
{
    canvas = new Canvas;
    actors = new ActorList;
    gameLoop = new GameLoop;
}
