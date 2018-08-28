module magra.gameloop;

import derelict.sdl2.sdl;
import std.exception;
import magra.globals;
import magra.input;
import magra.sound;

//======================================================================
//A GameLoop contains the main loop for a game using the Magra engine.
//It also contains essential data necessary to run the loop, such as the
//number of ticks that need to be run per second, and what should happen
//before ticking actors.
//======================================================================
class GameLoop
{
    bool quitting = false;
    
    float tickRate = 30.0;
    void function() preTick = null;
    void function() postTick = null;
    void function(SDL_Event) eventHandler = null;
    
    //==========================
    //Runs the actual game loop.
    //==========================
    void run()
    {
        //Record the time that the loop actually started.
        auto startTime = SDL_GetTicks();
        
        for(int gameTick = 1; !quitting; gameTick++)
        {
            //Our "goal" time is the time by which we need to have
            //the next frame ready (the end of the tick).
            auto goalTime = startTime + (gameTick * (1000 / tickRate));
            auto frameStartTime = SDL_GetTicks();
            
            //Update the input devices.
            inputList.tick();
            
            //Process all events and send them to the appropriate place.
            SDL_Event event;

            while(SDL_PollEvent(&event))
            {
                //Pass this event to the input devices
                //to see if it's anything they can handle.
                inputList.handleEvent(event);
                
                //Pass this event to the text buffer.
                textBuffer.handleEvent(event);

                //Pass this event to the gamecontrollers.
                foreach(gamepad; gamepads)
                    gamepad.handleEvent(event);

                if(event.type == SDL_CONTROLLERDEVICEADDED ||
                    event.type == SDL_CONTROLLERDEVICEREMOVED ||
                    event.type == SDL_CONTROLLERDEVICEREMAPPED)
                {
                    registerGamepads();
                }
                    
                //Pass it to the user-defined event handler too.
                if(eventHandler !is null)
                    eventHandler(event);
            }
            
            //Run the game logic.
            runGameLogic();
                
            //Re-enable the canvas so it doesn't get stuck.
            canvas.enabled = true;
            
            //Render the game scene, if we're not behind.
            if(goalTime > SDL_GetTicks())
            {
                canvas.draw();
                canvas.clear();
            }
            
            //Wait for goal time.
            auto timeToWait = goalTime - SDL_GetTicks();
            
            if(timeToWait > 0)
            {
                SDL_Delay(cast(uint) timeToWait);
                
                //Flip the display.
                SDL_RenderPresent(renderer);

                //Clear it afterwards. This prevents issues where leftover junk
                //can get stuck off the boundaries of the display in Fullscreen mode.
                SDL_RenderClear(renderer);
            }
            else
            {
                //Disable rendering to all layers for the next tic.
                canvas.enabled = false;
            }
        }
    }
    
    //===================================================
    //Run the game logic, first by calling preTick,
    //then ticking the actors, and then calling postTick.
    //===================================================
    void runGameLogic()
    {
        if(preTick !is null)
            preTick();
        
        actors.tick();

        if(postTick !is null)
            postTick();
    }
    
    //==============================
    //Run the given number of ticks.
    //==============================
    void skipTicks(uint numTicks)
    {
        //Disable sound and graphics while doing this.
        lockSound();
        canvas.enabled = false;
    
        //Run the given number of ticks as fast as we can.
        foreach(t; 0 .. numTicks)
            runGameLogic();
        
        //Reenable it now that we're done.
        unlockSound();
        canvas.enabled = true;
    }
}

