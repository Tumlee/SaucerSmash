module magra.init;

import std.exception;
import std.string;
import std.conv;

import magra.base;

//===========================================================
//Class that oversees the initialization of Derelict and SDL.
//===========================================================
class InitSettings
{
    int screenWidth = 640;
    int screenHeight = 480;
    bool fullscreen = false;
    
    string windowTitle = "Magra Game";

    int soundChannels = 32;
    int soundSampleRate = 44100;
    int soundBufferSize = 1024;
    
    //==========================================================
    //Just initializes Derelict and SDL-related libraries. This
    //is needed so we can grab configuration files, for example,
    //before we can continue on with the rest of the setup.
    //==========================================================
    void initializeSDL()
    {
        static bool loadedSDL = false;
        
        if(loadedSDL == false)
        {
            //Load up Derelict.
            DerelictSDL2.load();
            DerelictSDL2Image.load();
            DerelictSDL2Mixer.load();
            DerelictSDL2ttf.load();
            
            //Initialize the sdl-img and sdl-ttf functions.
            IMG_Init(IMG_INIT_PNG);
            TTF_Init();

            //DerelictSDL does not initialize Gamepad support by default.
            //No better place to do this than here!
            SDL_Init(SDL_INIT_GAMECONTROLLER);
            
            loadedSDL = true;
        }
    }

    //====================================================
    //Intializes the renderer and sets up the main window.
    //====================================================
    void initializeGraphics()
    {
        canvas = new Canvas;
    
        auto windowFlags = SDL_WINDOW_OPENGL;
        
        if(fullscreen)
            windowFlags |= osSpecificFullscreenFlag;
        
        //Create the SDL window and renderer.
        window = SDL_CreateWindow(  windowTitle.toStringz,
                                    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                    screenWidth, screenHeight,
                                    windowFlags);
                                                                                    
        renderer = SDL_CreateRenderer(window, -1, cast(SDL_RendererFlags)0);
        enforce(renderer, "Failed to set up an SDL renderer.");
        
        SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "Bilinear");
        SDL_RenderSetLogicalSize(renderer, screenWidth, screenHeight);

        canvas.target = renderer;
    }

    //==================
    //Initializes sound.
    //==================
    void initializeSound()
    {
        enforce(Mix_OpenAudio(soundSampleRate, AUDIO_S16SYS, 2, soundBufferSize) == 0,
                "Failed to initialize audio mixer.");
                
        Mix_AllocateChannels(soundChannels);
        Mix_Volume(-1, MIX_MAX_VOLUME);
    }

    //======================================
    //Initializes any input devices we find.
    //======================================
    void initializeInput()
    {
        //Create the Mouse, Keyboard, and TextBuffer objects.
        mouse = new Mouse;
        keyboard = new Keyboard;      
        textBuffer = new TextBuffer;
    
        //Register the mouse and keyboard as input devices.
        inputList.devices["mouse"] = mouse;
        inputList.devices["keyboard"] = keyboard;
      
        //Load gamepad databases, the one in the resources should be loaded first so
        //that the one in the preferences path can take precedence.
        SDL_GameControllerAddMappingsFromFile((resourcesPath() ~ "gamecontrollerdb.txt").toStringz);
        SDL_GameControllerAddMappingsFromFile((preferencesPath() ~ "gamecontrollerdb.txt").toStringz);
  
        //Load any game controllers we find.
        registerGamepads();
    }

    //==============================================================
    //Initializes many of the Derelict and SDL-related libraries and
    //other services such as graphics and sound.
    //==============================================================
    void initializeEngine()
    {
        initializeSDL();   
        initializeSound();
        initializeGraphics();
        initializeInput();
       
        actors = new ActorList;
        gameLoop = new GameLoop;
    }
}
