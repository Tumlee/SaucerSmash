module ss.graphics;

import magra.base;
import magra.extras.graphics;
import std.exception;
import std.string;
import ss.fixcoord;

SDL_Texture* loadModdedTexture(const char[] filename, Pixel32 function(Pixel32) modColor)
{
    auto surface = loadSurface(filename);
        
    modSurface(surface, modColor);
    
    auto texture = SDL_CreateTextureFromSurface(renderer, surface);
    
    SDL_FreeSurface(surface);
    
    return texture;
}

class FCSprite : Drawer
{
    SDL_Texture* texture;
    int x, y;
    float rotation;
    
    this(SDL_Texture* tex, FixCoord origin, float rot = 0.0)
    {
        texture = tex;
        x = origin.x - (texWidth(texture) / 2);
        y = origin.y - (texHeight(texture) / 2);
        rotation = rot;
    }
    
    override void draw(SDL_Renderer* target)
    {
        SDL_Rect location;
        
        location.x = x;
        location.y = y;
        location.w = texWidth(texture);
        location.h = texHeight(texture);
        
        SDL_RenderCopyEx(target, texture, null, &location, rotation, null, SDL_FLIP_NONE);
    }
}

class ShadowText : Drawer
{
    int x, y;
    string text;
    Pixel32 color;
    TTF_Font* font;
    bool centered;
    
    this(string tx, int xx, int yy, TTF_Font* fnt, Pixel32 col, bool cen = true)
    {
        text = tx;
        x = xx;
        y = yy;
        font = fnt;
        color = col;
        centered = cen;
    }
    
    override void draw(SDL_Renderer* target)
    {
        if(text.length == 0)
            return;
    
        //Draw the shadowed text to a surface.    
        auto tSurface = TTF_RenderText_Blended(font, text.toStringz, color.toSDL);
        auto sSurface = TTF_RenderText_Blended(font, text.toStringz, Pixel32(0,0,0).toSDL);
        
        auto surface = SDL_CreateRGBSurface(0, tSurface.w + 2, tSurface.h + 2,
                            32, 0xff << 24, 0xff << 16, 0xff << 8, 0xff);
        
        auto sRect = SDL_Rect(2, 2, 0, 0);
        auto tRect = SDL_Rect(0, 0, 0, 0);
        
        SDL_BlitSurface(sSurface, null, surface, &sRect);
        SDL_BlitSurface(tSurface, null, surface, &tRect);
        
        SDL_LockSurface(surface);
        
        auto dat = cast(int*) surface.pixels;
    
        foreach(i; 0 .. surface.w * surface.h)
        {
            auto pixel = Pixel32(surface.format, dat[i]);
            pixel.a = (pixel.a * color.a) / 255;
            dat[i] = pixel.toInt(surface.format);
        }
        
        SDL_UnlockSurface(surface);
        
        auto texture = SDL_CreateTextureFromSurface(renderer, surface);
        
        int xOff = centered ? texWidth(texture) / 2 : 0;
        
        auto location = SDL_Rect(   x - xOff,
                                    y,
                                    texWidth(texture),
                                    texHeight(texture));
        
        SDL_RenderCopyEx(target, texture, null, &location, 0.0, null, SDL_FLIP_NONE);
        
        SDL_FreeSurface(sSurface);
        SDL_FreeSurface(tSurface);
        SDL_FreeSurface(surface);
        SDL_DestroyTexture(texture);
    }
}
