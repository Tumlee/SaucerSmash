module magra.confighandler;

import std.stdio;
import std.conv;
import std.algorithm;
import std.array;
import std.string;
import std.exception;

//========================================================
//The base class for a ConfigValue. All have a way to
//get the value as a string and set the value to a string.
//========================================================
class ConfigValueBase
{    
    abstract string getString();
    abstract void set(string input);
}

//===============================================================
//A ConfigValue points to a variable of the given type T.
//It is used as an interface so the ConfigHandler can talk
//directly to the variables, getting and setting them as strings.
//===============================================================
class ConfigValue(T) : ConfigValueBase
{
    //The variable that this ConfigValue points to.
    T* variable;

    //===========================
    //Constructor for ConfigValue
    //===========================
    this(T* newVariable)
    {
        enforce(newVariable !is null, "Tried to construct a null ConfigValue.");
    
        variable = newVariable;
    }

    //=================================
    //Returns the variable as a string.
    //=================================
    override string getString()
    {
        return (*variable).to!string;
    }
    
    //============================================
    //Sets the variable based on the input string.
    //============================================
    override void set(string input)
    {
        try
        {
            *variable = input.to!T;
        }
        catch(std.conv.ConvException)
        {
            enforce(false, "Conversion error setting ConfigValue.");
        }
    }
}

//=============================================================
//A class that handles the saving and loading of variables into
//configuration files.
//=============================================================
class ConfigHandler
{
    //A list of configuration values, lookup by string.
    ConfigValueBase[string] values;
    
    //===========================================================
    //Registers the given variable in the ConfigHandler so it can
    //be written to, and read from, a configuration file.
    //===========================================================
    void add(T)(T* variable, string name)
    {
        //Having a space in a ConfigValue name will break the parser.
        enforce(!name.canFind(' '), "Added a ConfigValue with a space in its name.");
    
        values[name] = new ConfigValue!(T)(variable);
    }
    
    //=============================================================
    //Reads a single line in the form of "name value", and sets the
    //appropriate variable to the given value. Variable names that
    //are not recognized are simply skipped.
    //=============================================================
    void parseLine(string line)
    {
        auto split = line.strip.findSplit(" ");
        
        //Check each value in the split to ensure
        //that none of them are empty.
        foreach(s; split)
            enforce(!s.empty, "Syntax error reading configuration file.");
            
        //split[0] is the name of the ConfigValue.
        //split[2] is the actual value of the ConfigValue.
        if((split[0] in values) !is null)
            values[split[0]].set(split[2]);
    }
    
    //===========================================================
    //Loads a configuration file with the given filename. It then
    //sets its ConfigValues based on what is parsed.
    //===========================================================
    bool load(string fileName)
    {
        File configFile;

        try //Open the file, and return false if it cannot be opened.
        {
            configFile = File(fileName, "r");
        }
        catch(std.exception.ErrnoException)
        {
            return false;
        }
        
        //Ensure the file is always closed, even in the case of an error
        scope(exit)
            configFile.close();

        foreach(line; configFile.byLineCopy)
            parseLine(line);

        return true;
    }
    
    //=====================================================================
    //Saves all ConfigValues to a configuration file of the given filename.
    //=====================================================================
    bool save(string fileName)
    {
        File configFile;
    
        try //Open the file, return false if it cannot be opened.
        {
            configFile = File(fileName, "w");
        }
        catch(std.exception.ErrnoException)
        {
            return false;
        }
    
        //Save each ConfigValue to the file in the format of "name value".
        foreach(name; values.byKey())
            configFile.writefln("%s %s", name, values[name].getString());
        
        //Close the file and return.
        configFile.close();
        return false;
    }
}
