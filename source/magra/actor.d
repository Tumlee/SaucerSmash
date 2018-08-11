module magra.actor;

import magra.actorlist;

//=======================================
//The base class for all actors in Magra.
//=======================================
class Actor
{
    //The container tells us which list this actor belongs to.
    ActorList container;
    
    //An actor's tick() function is called every time the actorlist
    //ticks. If this function returns false, the actor is immediately
    //removed from the game.
    abstract bool tick();
}
