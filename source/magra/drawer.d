module magra.drawer;

import std.exception;
import derelict.sdl2.sdl;

import magra.layer;

//======================================================
//A Drawer is a class that represents a rendering action
//that needs to be taken during a render.
//======================================================
class Drawer
{   
    //The action that is taken by the drawer. Note that this
    //function can be skipped -- there is no guarantee that
    //the function will ever be called.
    abstract void draw(SDL_Renderer* target);
}
