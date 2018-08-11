module ss.shieldbreak;

import ss.ssactor;
import ss.resources;
import ss.graphics;

class ShieldBreak : SSActor
{
    int timer = 0;

    this(FixCoord ppos, FixCoord vvel)
    {
        pos = ppos;
        vel = vvel;
    }

    override bool tick()
    {
        int frame = timer / 2;

        if(frame >= texShieldBreak.length)
            return false;

        pos += vel;
        effectLayer.add(new FCSprite(texShieldBreak[frame], pos));

        timer++;
        return true;
    }
}
