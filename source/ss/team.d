module ss.team;

import magra.base;
import magra.extras.graphics;
import std.conv;

import ss.graphics;

class Team
{
    Pixel32 color;
    
    SDL_Texture*[bool] texSaucer;
    SDL_Texture*[4] texTrail;
    SDL_Texture* texBolt;
    SDL_Texture* texBoltTrail;
    SDL_Texture*[3] texBoltExp;
    SDL_Texture* texShield;
    SDL_Texture* texCursor;
    SDL_Texture*[bool] texLife;
    SDL_Texture*[bool] texStunCounter;
    SDL_Texture* texTarget;
    
    this(Pixel32 function(Pixel32) modColor)
    {
        color = modColor(Pixel32(0, 255, 0));
        
        texSaucer[true] = loadModdedTexture("saucer.png", modColor);
        texSaucer[false] = loadModdedTexture("sauceroff.png", modColor);
        texBolt = loadModdedTexture("bolt.png", modColor);
        texBoltTrail = loadModdedTexture("bolttrail.png", modColor);
        texShield = loadModdedTexture("shield.png", modColor);
        texCursor = loadModdedTexture("cursor.png", modColor);
        texLife[true] = loadModdedTexture("life.png", modColor);
        texLife[false] = loadModdedTexture("lifeoff.png", modColor);
        texStunCounter[true] = loadModdedTexture("stuncounter.png", modColor);
        texStunCounter[false] = loadModdedTexture("stuncounteroff.png", modColor);
        texTarget = loadModdedTexture("target.png", modColor);
        
        foreach(i; 0 .. texTrail.length)
            texTrail[i] = loadModdedTexture("trail" ~ i.to!string ~ ".png", modColor);
        
        foreach(i; 0 .. texBoltExp.length)
            texBoltExp[i] = loadModdedTexture("boltexp" ~ i.to!string ~ ".png", modColor);
    }
}
