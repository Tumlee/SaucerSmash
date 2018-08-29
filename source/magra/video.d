module magra.video;

import derelict.sdl2.sdl;
import std.exception;

//The SDL window and renderer.
SDL_Renderer* renderer;
SDL_Window* window;

//The parameters passed to SDL_RenderSetLogicalSize()
int logicalScreenwidth;
int logicalScreenheight;

//In fullscreen mode, this is the actual screen resolution chosen by SDL.
int actualScreenwidth;
int actualScreenheight;

void setLogicalRendererSize(SDL_Renderer* renderer, int w, int h)
{
    logicalScreenwidth = w;
    logicalScreenheight = h;
    SDL_RenderSetLogicalSize(renderer, w, h);
}

//Stores the actual screen dimensions for later use.
//This function should be called whenever the video mode changes.
void updateActualScreenDimensions()
{
    SDL_DisplayMode displayMode;

    int statusCode = SDL_GetCurrentDisplayMode(0, &displayMode);
    enforce(statusCode == 0, "Call to SDL_GetCurrentDisplayMode() failed");
    
    actualScreenwidth = displayMode.w;
    actualScreenheight = displayMode.h;
}
