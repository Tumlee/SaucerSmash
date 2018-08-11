module ss.bolt;

import ss.ssactor;
import ss.saucer;
import ss.resources;
import ss.graphics;

class Bolt : SSActor
{
    int explodeTimer = 0;
    Saucer creator;

    this(Saucer cr, FixCoord ppos, FixCoord vvel)
    {
        pos = ppos;
        vel = vvel;
        radius = 4;
        creator = cr;
    }
    
    @property Team team()
    {
        return creator.team;
    }

    override bool tick()
    {
        pos += vel;

        if(explodeTimer)
        {
            int frame = explodeTimer / 4;

            if(frame >= 3)
                return false;

            solidLayer.add(new FCSprite(team.texBoltExp[frame], pos));
            explodeTimer++;
            return true;
        }

        //If the bolt goes too far from the center, disappear.
        //The center of the map is 400, 300.
        if((pos - FixCoord(400, 300)).mag > 800)
            return false;

        foreach(target; actors.actorsOf!(Saucer))
        {
            if(target !is creator && isTouching(target))
            {
                if(target.team !is team)
                    target.reactBolt();
                    
                pos.redistance(target.pos, target.radius);
                
                vel = target.vel;
                explodeTimer = 1;
            }
        }

        solidLayer.add(new FCSprite(team.texBoltTrail, pos - polarCoord(iu!10, vel.ang)));
        solidLayer.add(new FCSprite(team.texBoltTrail, pos - polarCoord(iu!5, vel.ang)));
        solidLayer.add(new FCSprite(team.texBolt, pos));

        return true;
    }
}
