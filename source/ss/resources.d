module ss.resources;

import magra.base;
import magra.extras.graphics;
import ss.directories;
public import ss.team;
import std.conv;

Layer backLayer;
Layer trailLayer;
Layer solidLayer;
Layer effectLayer;
Layer hudLayer;

SDL_Texture* texBackground;
SDL_Texture* texFadeTarget;
SDL_Texture*[4] texShieldBreak;

Mix_Chunk* sfxExplosion;
Mix_Chunk* sfxBolt;
Mix_Chunk* sfxOverdrive;
Mix_Chunk* sfxClunk;
Mix_Chunk* sfxWarning;

Mix_Music*[2] music;

TTF_Font* font;
TTF_Font* bigFont;

Team[] teams;

void loadResources()
{
    setResourceDirectory(resourcesPath);

    backLayer = canvas.register(0);
    trailLayer = canvas.register(1);
    solidLayer = canvas.register(2);
    effectLayer = canvas.register(3);
    hudLayer = canvas.register(4);
    
    texBackground = loadTexture("space.png");
    texFadeTarget = loadTexture("fadetarget.png");
    
    foreach(i; 0 .. texShieldBreak.length)
        texShieldBreak[i] = loadTexture("shieldbreak" ~ i.to!string ~ ".png");
    
    teams ~= new Team(&colorModGreen);
    teams ~= new Team(&colorModYellow);
    teams ~= new Team(&colorModOrange);
    teams ~= new Team(&colorModRed);
    teams ~= new Team(&colorModPurple);
    teams ~= new Team(&colorModBlue);
    
    sfxExplosion = loadSound("explosion.ogg");
    sfxBolt = loadSound("bolt.ogg");
    sfxOverdrive = loadSound("overdrive.ogg");
    sfxClunk = loadSound("clunk.ogg");
    sfxWarning = loadSound("warning.ogg");
    
    font = loadFont("font.ttf", 24);
    bigFont = loadFont("font.ttf", 36);
    
    foreach(i; 0 .. music.length)
        music[i] = loadMusic("music" ~ i.to!string ~ ".ogg");
}

Pixel32 colorModGreen(Pixel32 px)
{   
    return Pixel32(px.r, px.g, px.r, px.a);
}

Pixel32 colorModRed(Pixel32 px)
{
    return Pixel32(px.g, px.r, px.r, px.a);
}

Pixel32 colorModBlue(Pixel32 px)
{
    Pixel32 result;
    result.r = (px.b / 2) + (px.r / 2);
    result.g = (px.g / 2) + (px.r / 2);
    result.b = px.g;
    result.a = px.a;
    return result;
}

Pixel32 colorModYellow(Pixel32 px)
{
    return Pixel32(px.g, px.g, px.r, px.a);
}

Pixel32 colorModPurple(Pixel32 px)
{
    return Pixel32((px.g / 2) + (px.r / 2), px.r, px.g, px.a);
}

Pixel32 colorModOrange(Pixel32 px)
{
    return Pixel32(px.g, (px.g / 2) + (px.r / 2), (px.r / 2) + (px.b / 2), px.a);
}
