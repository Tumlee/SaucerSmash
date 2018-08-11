module ss.trail;

import ss.ssactor;
import ss.graphics;
import ss.resources;

class Trail : SSActor
{
    int timer;
    bool fromExplosion;
    
    this(Team tm, FixCoord ppos, FixCoord vvel, int t = 20, bool fromExp = false)
    {
        team = tm;
        pos = ppos;
        vel = vvel;
        timer = t;
        fromExplosion = fromExp;
    }
    
    override bool tick()
    {
        pos += vel;
        timer--;

        int frame = ((25 - timer) * 4) / 25;

        if(frame >= cast(int) team.texTrail.length)
            return false;

        if(frame < 0)
            frame = 0;
            
        auto chosenLayer = fromExplosion ? effectLayer : trailLayer;
        
        chosenLayer.add(new FCSprite(team.texTrail[frame], pos));

        return true;
    }
}
