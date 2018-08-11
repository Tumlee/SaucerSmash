module magra.extras.graphics;

import magra.base;
import std.string;

//=======================================================
//A type that represents a 32-bit color, with red, green,
//blue, and alpha channel.
//=======================================================
struct Pixel32
{
    //Color channels.
    ubyte r, g, b, a;
    
    //=====================================================
    //Construct a Pixel32 with raw channel values (0 - 255)
    //=====================================================
    this(ubyte rr, ubyte gg, ubyte bb, ubyte aa = 255)
    {
        r = rr;
        g = gg;
        b = bb;
        a = aa;
    }
    
    //=======================================================
    //Construct a Pixel32 with an SDL_PixelFormat and an int.
    //SDL may have to be initialized for this to work.
    //=======================================================
    this(SDL_PixelFormat* format, int pixel)
    {   
        SDL_GetRGBA(pixel, format, &r, &g, &b, &a);
    }
    
    //===============================================================
    //Return the result of blending pixel 'top' on top of this pixel.
    //The higher alpha value 'top' has, the more influence it has.
    //===============================================================
    Pixel32 blend(Pixel32 top)
    {
        Pixel32 result;
        
        auto pa = top.a;
        auto ia = (255 - top.a);
        
        result.r = cast(ubyte) (((r * ia) / 255) + (top.r * pa) / 255);
        result.g = cast(ubyte) (((g * ia) / 255) + (top.g * pa) / 255);
        result.b = cast(ubyte) (((b * ia) / 255) + (top.b * pa) / 255);
        result.a = cast(ubyte) (a + (((255 - a) * top.a) / 255));
        
        return result;
    }

    //================================================================
    //Convert this pixel to an int based on the given SDL_PixelFormat.
    //================================================================    
    int toInt(SDL_PixelFormat* format)
    {   
        return SDL_MapRGBA(format, r, g, b, a);
    }
    
    //=============================================
    //Convert this pixel to an SDL_Color structure.
    //=============================================
    SDL_Color toSDL()
    {
        return SDL_Color(r, g, b, a);
    }
}

//===================================================================================
//Uses SDL TTF to create a texture of the given text, with the chosen color and font.
//===================================================================================
SDL_Texture* textToTexture(string text, TTF_Font* font, Pixel32 color)
{
    auto textSurface = TTF_RenderText_Blended(font, text.toStringz, color.toSDL);
    auto texture = SDL_CreateTextureFromSurface(renderer, textSurface);
    
    SDL_FreeSurface(textSurface);
    
    return texture;
}

//================================================================
//A Drawer that represents a basic sprite (not scaled or rotated).
//This is good for simple games like 2D side scrollers which only
//really require flipping.
//================================================================
class BasicSprite : Drawer
{
    //The texture to be drawn.
    SDL_Texture* texture;
    
    //The x and y position, which will be the upper left corner.
    int x, y;
    
    //Flipping value --- see documentation for SDL_RenderFlip
    SDL_RendererFlip flip;
    
    //======================================
    //Constructor for the BasicSprite class.
    //======================================
    this(SDL_Texture* tex, int xx, int yy, SDL_RendererFlip fl = SDL_FLIP_NONE)
    {
        texture = tex;
        x = xx;
        y = yy;
        flip = fl;
    }

    //========================================
    //Draw function for the BasicSprite class.
    //========================================
    override void draw(SDL_Renderer* target)
    {
        //Build the SDL rectangle for positioning.
        SDL_Rect location;
        
        location.x = x;
        location.y = y;
        location.w = cast(int) texWidth(texture);
        location.h = cast(int) texHeight(texture);
        
        SDL_RenderCopyEx(target, texture, null, &location, 0.0, null, flip);
    }
}

//=====================================================================
//Drawer representing a sprite, which can be freely rotated and scaled.
//The x and y position used represents the center of the sprite, not a
//corner.
//=====================================================================
class Sprite : Drawer
{
    //The texture to be drawn.
    SDL_Texture* texture;
    
    //The x and y position, which is the center of the sprite.
    int x, y;
    
    //Scaling value, 1.0 being normal size.
    float scale;
    
    //Rotation value, in degrees.
    //FIXME: I think this ought to be radians.
    float rotation;
    
    //=================================
    //Constructor for the Sprite class.
    //=================================
    this(SDL_Texture* tex, int xx, int yy, float scl = 1.0, float rot = 0.0)
    {
        texture = tex;
        scale = scl;
        x = cast(int)(xx - (texWidth(texture) * scale * .5));
        y = cast(int)(yy - (texHeight(texture) * scale * .5));
        rotation = rot;
    }
    
    //===================================
    //Draw function for the Sprite class.
    //===================================
    override void draw(SDL_Renderer* target)
    {
        //Build the SDL rectangle for positioning.
        SDL_Rect location;
        
        location.x = x;
        location.y = y;
        location.w = cast(int) (texWidth(texture) * scale);
        location.h = cast(int) (texHeight(texture) * scale);
        
        SDL_RenderCopyEx(target, texture, null, &location, rotation, null, SDL_FLIP_NONE);
    }
}

//=============================================================
//Drawer designed for display text on the screen using SDL TTF.
//=============================================================
class TextMessage : Drawer
{
    //X and Y position, representing the top right corner.
    int x, y;
    
    //The text to be displayed.
    string text;
    
    //The color of the text.
    Pixel32 color;
    
    //The chosen font.
    TTF_Font* font;
    
    //======================================
    //Constructor for the TextMessage class.
    //======================================
    this(string tx, int xx, int yy, TTF_Font* fnt, Pixel32 col)
    {
        text = tx;
        x = xx;
        y = yy;
        font = fnt;
        color = col;
    }
    
    //====================================================
    //Drawer function for the TextMessage class.
    //NOTE: This function is extremely inefficient and may
    //potentially cause slowdowns if used too often.
    //====================================================
    override void draw(SDL_Renderer* target)
    {
        //Don't draw anything if there is no text.
        if(text.length == 0)
            return;
        
        //Create a texture from the text.
        auto texture = textToTexture(text, font, color);
        
        //Build the positioning rectangle.
        SDL_Rect location;
        location.x = x;
        location.y = y;
        location.w = cast(int) texWidth(texture);
        location.h = cast(int) texHeight(texture);
        
        //Draw the text on the screen.
        SDL_RenderCopyEx(target, texture, null, &location, 0.0, null, SDL_FLIP_NONE);
        
        //Clean up by destroying the texture.
        SDL_DestroyTexture(texture);
    }
}

//===========================================================================
//Modifies the given SDL Surface using the given modColor function, which
//transforms the colors a pixel at a time. This is most useful for recoloring
//sprites on the fly rather than having to make them by hand.
//===========================================================================
void modSurface(SDL_Surface* surface, Pixel32 function(Pixel32) modColor)
{
    SDL_LockSurface(surface);
    
    //These functions only operate on 32 bit pixels, although
    //it could theoretically be modified to support lower bpp.
    if(surface.format.BytesPerPixel == 4)
    {
        //Get a pointer to the surface's pixel data.
        auto dat = cast(int*) surface.pixels;
    
        foreach(i; 0 .. surface.w * surface.h)
        {
            //Grab the pixel as a Pixel32
            auto pixel = Pixel32(surface.format, dat[i]);
            
            //Modify the color and save it back to the surface.
            dat[i] = modColor(pixel).toInt(surface.format);
        }
    }
    
    SDL_UnlockSurface(surface);
}

//=======================================================================
//Helper functions for easily grabbing the width and height of a texture.
//=======================================================================
int texWidth(SDL_Texture* texture)
{
    int w;
    SDL_QueryTexture(texture, null, null, &w, null);
    
    return w;
}

int texHeight(SDL_Texture* texture)
{
    int h;
    SDL_QueryTexture(texture, null, null, null, &h);
    
    return h;
}

