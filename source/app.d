import magra.base;
import magra.extras.graphics;
import ss.gamestate;

import ss.resources;
import ss.directories;
import ss.graphics;
import ss.menu;
import ss.gamerecorder;

import ss.hud;
import ss.playersaucer;

import std.stdio;
import std.string;
import std.conv;

//==============================================================
//Returns the value of the given command line parameter (defined
//as the parm directly following the one that matches 'name').
//==============================================================
string getParm(string[] args, string name)
{
    foreach(a; 1 .. args.length - 1)
    {
        if(args[a] == name)
            return args[a + 1];
    }

    return null;
}

void ssPreTick()
{
    backLayer.add(new BasicSprite(texBackground, 0, 0));
    
    if(keyboard[SDLK_ESCAPE].isFresh)
    {
        if(gameState == GameState.playing)
            setGameState(GameState.menu);
    }
    
    runGameState();
    drawHud();
}


void ssEventHandler(SDL_Event event)
{
    if(event.type == SDL_QUIT)
        gameLoop.quitting = true;
}

void main(string[] args)
{
    gameDirName = "SaucerSmash";

    auto configHandler = new ConfigHandler;
    
    configHandler.add(&menuFullscreen, "fullscreen");
    configHandler.add(&menuPlayMusic, "playMusic");
    configHandler.add(&menuPlayerTeam, "playerColor");
    configHandler.add(&menuEnemyTeam, "enemyColor");
    configHandler.add(&upKey, "upKey");
    configHandler.add(&downKey, "downKey");
    configHandler.add(&leftKey, "leftKey");
    configHandler.add(&rightKey, "rightKey");
    configHandler.add(&fireKey, "fireKey");
    configHandler.add(&dashKey, "dashKey");
    configHandler.add(&aimDashKey, "aimDashKey");
    
    auto initSettings = new InitSettings;
    initSettings.initializeSDL();
    
    configHandler.load(preferencesPath() ~ "SaucerSmash.cfg");
    
    initSettings.windowTitle = "SaucerSmash";
    initSettings.screenWidth = 800;
    initSettings.screenHeight = 600;
    initSettings.fullscreen = menuFullscreen;
    initSettings.initializeEngine();
    
    loadResources();
    
    recorder = new GameRecorder;
    lastGame = new GameRecorder;
    initMenus();
    
    setGameState(GameState.menu);
    
    gameLoop.tickRate = 60.0;
    gameLoop.preTick = &ssPreTick;
    gameLoop.eventHandler = &ssEventHandler;    
        
    string startTimeParm = getParm(args, "--skipseconds");
    int startTime = 0;

    if(startTimeParm !is null)
    {
        try
        {
            startTime = cast(int) (startTimeParm.to!float * 60.0);
        }
        catch(std.conv.ConvException)
        {
            startTime = 0;
        }
    }
    
    foreach(arg; args)
    {
        if(arg.length >= 4 && arg[$ - 4 .. $].toLower == ".ssr")
        {
            try
            {
                recorder.load(arg);
            }
            catch(Exception ex)
            {
                writeln("Cannot play this replay, reason:");
                writeln(ex.msg);
                return;
            }
            
            recorder.setState(RecorderState.playing);
            dedicatedPlayback = true;
            startPlay(teams[recorder.playerTeam], teams[recorder.enemyTeam]);
            gameLoop.skipTicks(startTime);
            
            break;
        }
    }
    
    //Preserve the lastGame replay via the 'auto.ssr' autosave.
    try
    {
        lastGame.load(replayPath() ~ "auto.ssr");
    }
    catch(Exception ex)
    {
        //Don't need to do anything if we cannot load auto.ssr    
    }

    gameLoop.run();
    
    configHandler.save(preferencesPath() ~ "SaucerSmash.cfg");
}
