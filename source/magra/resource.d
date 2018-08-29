module magra.resource;

import magra.globals;
import magra.video;

import derelict.sdl2.sdl;
import derelict.sdl2.mixer;
import derelict.sdl2.image;
import derelict.sdl2.ttf;

import std.string;
import std.exception;

private string resourceDirectory = "resources/";

//==========================================================
//Sets the directory where the game will look for resources.
//==========================================================
void setResourceDirectory(string newPath)
{
    resourceDirectory = newPath;
}

//FIXME: These functions ought to throw exceptions rather than enforce
//the successful loading of resources.

//=====================================================================
//Loads a surface from a file in the resources folder, using SDL Image.
//=====================================================================
SDL_Surface* loadSurface(const char[] filename)
{
    return IMG_Load((resourceDirectory ~ filename).toStringz);
}

//====================================================
//Loads a texture from a file in the resources folder.
//====================================================
SDL_Texture* loadTexture(const char[] filename)
{
    enforce(renderer !is null, "Loaded a texture without a renderer.");
    
    auto surface = loadSurface(filename);
    
    if(surface is null)
        return null;
    
    auto texture = SDL_CreateTextureFromSurface(renderer, surface);
    
    SDL_FreeSurface(surface);
    
    return texture;
}

//===================================================================
//Loads a sound from a file in the resources folder, using SDL Mixer.
//===================================================================
Mix_Chunk* loadSound(const char[] filename)
{
    return Mix_LoadWAV((resourceDirectory ~ filename).toStringz);
}

//==============================================================
//Loads a music file from the resources folder, using SDL Mixer.
//==============================================================
Mix_Music* loadMusic(const char[] filename)
{
    return Mix_LoadMUS((resourceDirectory ~ filename).toStringz);
}

//==========================================================
//Loads a TTF Font from the resources folder, using SDL TTF.
//==========================================================
TTF_Font* loadFont(const char[] filename, int ptSize)
{
    auto font = TTF_OpenFont((resourceDirectory ~ filename).toStringz, ptSize);
    
    enforce(font !is null, "Failed to load font " ~ resourceDirectory ~ filename);
    
    return font;
}
