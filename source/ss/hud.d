module ss.hud;

import magra.base;
import magra.extras.graphics;
import ss.resources;
import ss.graphics;
import ss.gamestate;
import ss.fixcoord;
import ss.playersaucer;
import ss.gamerecorder;

import std.conv;

int hudScore = 0;
int hudTimer = 0;

struct HudAnnouncer
{
    int timer;
    int priority;
    string message;
        
    void run()
    {
        if(timer > 0)
            timer--;
        
        else
        {
            message = "";
            priority = 0;
        }
    
        if(message == "")
            return;
            
        auto messageColor = playerTeam.color;
            
        if(timer > 165)
        {
            float brightness = (timer - 165) / 15.0;
            
            messageColor.r += cast(ubyte) (brightness * (255 - messageColor.r));
            messageColor.g += cast(ubyte) (brightness * (255 - messageColor.g));
            messageColor.b += cast(ubyte) (brightness * (255 - messageColor.b)); 
        }
        
        if(timer < 30)
            messageColor.a = cast(ubyte)((255 * timer) / 30);
        
        hudLayer.add(new ShadowText(message, 400, 500, font, messageColor));
    }
    
    void reset()
    {
        timer = 0;
        message = "";
        priority = 0;
    }
    
    void set(string newMessage, int newPriority)
    {
        if(newPriority < priority)
            return;
    
        timer = 180;
        message = newMessage;
        priority = newPriority;
    }
}

HudAnnouncer announcer;

void resetHud()
{
    hudScore = 0;
    hudTimer = 0;
    announcer.reset();
}

void drawHud()
{
    if(gameState == GameState.menu)
        return;
    
    hudTimer++;

    announcer.run();
    
    if(hudScore < score)
        hudScore++;
    
    auto brightColor = playerTeam.color.blend(Pixel32(255, 255, 255, 192));
    
    hudLayer.add(new ShadowText("Score", 400, 3, font, brightColor));
    hudLayer.add(new ShadowText(hudScore.to!string, 400, 25, font, playerTeam.color));
    
    bool blink = (hudTimer / 15) % 2 == 0;
    
    if(gameState == GameState.playing)
    {
        hudLayer.add(new ShadowText("Lives", 750, 3, font, brightColor));
        
        if(actors.actorsOf!(PlayerSaucer).length == 0)
            blink = false;
    
        foreach(i; 0 .. 5)
        {
            auto hudLives = blink ? lives - 1 : lives;
            auto texLife = playerTeam.texLife[i < hudLives];
            hudLayer.add(new BasicSprite(texLife, 780 - (20 * i), 25));
        }
    }
    
    if(gameState == GameState.over)
    {
        string text = recorder.state != RecorderState.playing ? "Game Over" : "End of Replay";
    
        if(blink)
            hudLayer.add(new ShadowText(text, 400, 300, font, brightColor));
    }
    
    if(playerInControl)
    {
        FixCoord mousePos;
        mousePos.x = mouse.x;
        mousePos.y = mouse.y;
        hudLayer.add(new FCSprite(playerTeam.texCursor, mousePos));
    }
}

