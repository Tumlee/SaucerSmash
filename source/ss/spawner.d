module ss.spawner;

import ss.resources;
import ss.ssactor;
import ss.enemysaucer;
import ss.playersaucer;
import ss.shieldbreak;
import ss.graphics;
import ss.saucer;
import ss.gamestate;
import ss.gamerecorder;

import std.random;

class Spawner : SSActor
{
    int timer = 60;
    bool forPlayer;
    
    this(FixCoord ppos, bool fPlayer)
    {
        pos = ppos;
        radius = 12;
        forPlayer = fPlayer;
        
        team = forPlayer ? playerTeam : enemyTeam;
        
        if(!forPlayer)
        {   
            while(team is playerTeam)
                team = teams[recorder.uniform(0, cast(int)$)];
        }
    }

    override bool tick()
    {
        foreach(saucer; actors.actorsOf!(EnemySaucer))
        {
            auto diff = saucer.pos - pos;
        
            if(diff.mag < (forPlayer ? 256 : 32))
                saucer.vel += polarCoord(forPlayer ? ff!(7, 100) : ff!(1, 10), diff.ang);
        }

        if(timer-- == 0)
        {
            foreach(saucer; actors.actorsOf!(Saucer))
            {
                if(isTouching(saucer))
                    saucer.damage = 2;    //Telefrag.
            }

            actors.spawn(new ShieldBreak(pos, FixCoord(0, 0)));
            
            if(forPlayer)
                actors.spawn(new PlayerSaucer(team, pos));
                
            else
                actors.spawn(new EnemySaucer(team, pos));
                
            return false;
        }
        
        solidLayer.add(new FCSprite(team.texShield, pos));

        if(timer & 4)
            solidLayer.add(new FCSprite(texShieldBreak[timer > 30 ? 2 : 1], pos));
            
        return true;
    }
}
