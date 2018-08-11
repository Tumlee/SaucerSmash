module magra.actorlist;

import std.range;
import std.algorithm;
import std.exception;

import magra.actor;

//===============================================================
//An object that stores references to Actors. It is in control of
//ticking, spawning, and despawning them.
//===============================================================
class ActorList
{
    //Array of references to the contained actors.
    Actor[] actors;
    
    //A flag to tell us whether the list is curently
    //in the middle of its tick() function.
    bool ticking = false;
    
    //=========================================================
    //Spawns a new actor into the game and adds it to the list.
    //=========================================================
    void spawn(Actor actor)
    {
        enforce(actor !is null, "Spawned a null actor");
    
        actors ~= actor;
        actor.container = this;
    }
    
    //======================================================================
    //Runs though the entire list of actors, calling their tick() functions.
    //When one of these calls return false, the actor is removed.
    //======================================================================
    void tick()
    {    
        enforce(!ticking, "Ticked an already-ticking ActorList");
        
        ticking = true;
        
        //Don't use a foreach loop here, as that creates a copy
        //of all the references, which makes it difficult to officially
        //remove an actor in the middle of a tick.
        for(int i = 0; i < actors.length; i++)
        {
            if(actors[i].tick() == false)
                actors[i] = null;
        }
        
        actors = actors.filter!(a => a !is null).array;
        ticking = false;
    }
    
    //=================================================
    //Returns a list of all the actors of a given type.
    //By default, it just returns a list of all actors.
    //=================================================
    T[] actorsOf(T = Actor)()
    {
        T[] returnList;
    
        foreach(actor; actors)
        {
            auto casted = cast(T) actor;
            
            if(casted !is null)
                returnList ~= casted;
        }
        
        return returnList;
    }
    
    //=====================================================
    //Removes all actors of the given type.
    //By default, it removes all actors regardless of type.
    //=====================================================
    void clear(T = Actor)()
    {
        //Clearing actors from a ticking list is dangerous!
        enforce(!ticking, "Cleared from a ticking ActorList");
        
        actors = actors.filter!(a => cast(T) a is null).array;
    }
}
