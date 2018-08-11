module magra.directories;

import magra.base;
import std.exception;
import std.conv;
import std.file;
import std.string;

//The name of the game as far as directories are concerned. This should normally
//be the name of your game, unless the name has special characters in it.
string gameDirName = null;

//TODO: Maybe add this to the engine?
string preferencesPath()
{
    enforce(gameDirName !is null, "Unable to generate a preferences path because gameDirName has not been set.");

    static bool generatedString = false;
    static string path;

    //Even though the documentation tells us to call SDL_Free() on the
    //string returned by SDL_GetPrefPath(), it generates a complication
    //error when we try it here. It's only a few byes of memory anyway.
    if(generatedString == false)
    {
        auto cPath = SDL_GetPrefPath(".", gameDirName.toStringz);
        
        enforce(cPath !is null, "Unable to generate a preferences path.");
        path = cPath.to!string;
        generatedString = true;
    }
    
    return path;
}

string resourcesPath()
{
    static bool generatedString = false;
    static string path;

    //Even though the documentation tells us to call SDL_Free() on the
    //string returned by SDL_GetBasePath(), it generates a complication
    //error when we try it here. It's only a few byes of memory anyway.
    if(generatedString == false)
    {
        auto cPath = SDL_GetBasePath();
        
        enforce(cPath !is null, "Unable to generate a preferences path.");
        path = cPath.to!string ~ "resources/";
        generatedString = true;
    }
    
    return path;
}
