module ss.directories;

import magra.base;
import std.exception;
import std.conv;
import std.file;

string replayPath()
{
    string path = preferencesPath() ~ "replays/";
    
    try
    {
        mkdirRecurse(path);
    }
    catch(std.file.FileException)
    {
        enforce(false, "Unable to generate a replay directory");
    }

    return preferencesPath() ~ "replays/";
}
