module magra.canvas;

import derelict.sdl2.sdl;
import std.algorithm;
import std.range;
import std.exception;

import magra.layer;

class Canvas
{
    //The list of layers that belong to this canvas.
    Layer[] layers;
    
    //The renderer that will be drawn to during a call to Canvas.draw()
    SDL_Renderer* target;
    
    //Whether or not the canvas is enabled. When a canvas is disabled,
    //requests to add Drawers to its Layers are ignored.
    bool enabled = true;
    
    //=====================================================
    //Creates a new layer and adds it to the list.
    //Layers with a higher ordering number are drawn first.
    //=====================================================
    Layer register(int ordering)
    {
        auto layer = new Layer;
    
        layer.ordering = ordering;
        layer.container = this;
        layers ~= layer;
        layers = layers.sort!((a, b) => a.ordering < b.ordering).array;
        
        return layer;
    }
    
    //=======================================================================
    //Call the draw() functions of all the Layers that belong to this Canvas,
    //and, in turn, all of the Drawers that belong to each Layer.
    //=======================================================================
    void draw()
    {
        enforce(target !is null, "Drew to a null renderer");
    
        if(enabled)
        {
            foreach(layer; layers)
                layer.draw();
        }
    }
    
    //=============================================
    //Removes all Drawers from the Canvas's Layers.
    //=============================================
    void clear()
    {
        foreach(layer; layers)
            layer.clear();
    }
}
