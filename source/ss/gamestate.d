module ss.gamestate;

import magra.base;

import ss.team;
import ss.playersaucer;
import ss.enemysaucer;
import ss.spawner;
import ss.fixcoord;
import std.random;
import ss.resources;
import ss.hud;
import ss.menu;
import ss.gamerecorder;
import ss.directories;

enum GameState
{
    playing,
    menu,
    over
}

int enemiesSpawned;
int lives;
int respawnTimer;
int score;
Team playerTeam;
Team enemyTeam;

GameState gameState;
GameRecorder recorder;
GameRecorder lastGame;

//Whether or not SaucerSmash was invoked specifically
//to play back a replay.
bool dedicatedPlayback = false;

void startPlay(Team pTeam, Team eTeam)
{
    score = 0;
    enemiesSpawned = 0;
    lives = 5;
    playerTeam = pTeam;
    enemyTeam = eTeam;
    
    if(menuPlayMusic)
        playMusic(music[uniform(0, $)]);
    
    respawnTimer = 1;
    
    resetHud();
    setGameState(GameState.playing);
}

@property int maxEnemies()
{
    Fix16 fixEnemies;
    fixEnemies = enemiesSpawned;

    return (fixEnemies.sqrt / 2) + 1;
}

@property bool playerInControl()
{
    return gameState == GameState.playing && recorder.state != RecorderState.playing;
}

void setGameState(GameState newState)
{
    //Make sure to save the replay of the game that just ended.
    if(gameState == GameState.playing && recorder.state == RecorderState.recording)
    {
        lastGame = recorder.dup;
        lastGame.save(replayPath ~ "auto.ssr");
    }
        
    if(newState != GameState.playing && dedicatedPlayback)
        gameLoop.quitting = true;

    gameState = newState;
   
    //Only show the default cursor outside of gameplay.
    //The same goes for grabbing the mouse cursor.    
    SDL_ShowCursor(!playerInControl);
    SDL_SetWindowGrab(window, cast(SDL_bool) playerInControl);
    
    if(gameState != gameState.playing)
        stopMusic();
        
    //There should be no actors in the menu.
    if(gameState == GameState.menu)
        actors.clear();
}

void runGameState()
{   
    switch(gameState)
    {
        case GameState.playing:
            runPlay();
            break;
            
        case GameState.over:
            runGameOver();
            break;
            
        case GameState.menu:
            runMenu();
            break;
            
        default:
            break;
    }
}

void runPlay()
{
    bool foundPlayerSpawner = false;
    int numEnemySpawners = 0;
    
    if(respawnTimer)
    {
        if(--respawnTimer == 0)
        {
            if(lives != 0)
                actors.spawn(new Spawner(FixCoord(400, 300), true));

            else
                setGameState(GameState.over);
        }
    }
    
    foreach(spawner; actors.actorsOf!(Spawner))
    {
        if(!spawner.forPlayer)
            numEnemySpawners++;
    }    
    
    int numEnemies = cast(int) actors.actorsOf!(EnemySaucer).length;
    
    if(numEnemies + numEnemySpawners < maxEnemies)
    {
        enemiesSpawned++;
        
        auto xSpawn = recorder.uniform(15, 785);
        auto ySpawn = recorder.uniform(15, 585);
        
        actors.spawn(new Spawner(FixCoord(xSpawn, ySpawn), false));
    }
}

void runGameOver()
{
    if(mouse[SDL_BUTTON_LEFT].isFresh)
        setGameState(GameState.menu);
}

void addScore(int amount)
{
    score += amount;
}
