module magra.layer;

import magra.canvas;
import magra.drawer;

//=============================================================
//A Layer is a container for Drawers. The point of a layer
//is to organize Drawers into distinct spaces so that they
//can be drawn and repositioned as a unit. This also guarantees
//that certain objects are drawn in the correct order.
//=============================================================
class Layer
{
    //The list of Drawers.
    Drawer[] drawers;
    
    //The Canvas that this Layer belongs to.
    Canvas container;
    
    //The Layer's ordering within the canvas.
    //Layers with a lower ordering are drawn first (on bottom).
    int ordering;

    //======================================
    //Draws all of the Drawers in the Layer.
    //======================================
    void draw()
    {    
        foreach(drawer; drawers)
            drawer.draw(container.target);
    }
    
    //========================================================
    //Adds a new Drawer to the Layer, if the Layer is enabled.
    //========================================================
    void add(lazy Drawer drawer)
    {
        if(container.enabled)
            drawers ~= drawer;
    }
    
    //==================================
    //Clears all Drawers from the Layer.
    //==================================
    void clear()
    {
        drawers.length = 0;
    }
}
