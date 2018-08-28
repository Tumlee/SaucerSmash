module ss.menu;

import magra.base;
import magra.extras.graphics;
import ss.resources;
import ss.graphics;
import ss.gamestate;
import ss.fixcoord;
import ss.gamerecorder;
import ss.directories;

import ss.playersaucer; //For keybinds.

import std.conv;
import std.math;
import std.algorithm;
import std.file;
import std.string;
import std.path;

int menuPlayerTeam = 0;
int menuEnemyTeam = 3;
bool menuFullscreen = false;
bool menuPlayMusic = true;

Menu mainMenu;
Menu settingsMenu;
Menu replayMenu;
Menu currentMenu;
MenuKeybind chosenBind = null;
bool savingReplay = false;

ReplayEntry[] replayList;
int chosenReplay;

string menuMessage;
int menuMessageTimer;

class Menu
{
    MenuItem[] items;
    string title;
    int titleY;
    int startY;
    
    this(string newTitle, int newTitleY, int newStartY)
    {
        title = newTitle;
        titleY = newTitleY;
        startY = newStartY;
    }
    
    void run()
    {
        hudLayer.add(new ShadowText(title, 400, titleY, bigFont, Pixel32(255, 255, 255)));
        
        foreach(int i, item; items)
            item.run(startY + (i * 32));
    }
}

class MenuItem
{
    @property abstract string text();
    
    @property string leftText()
    {
        return "";   
    }
    
    abstract void doAction();
    
    bool mouseIn(int y)
    {
        if(mouse.y < y || mouse.y >= y + 32)
            return false;
            
        if(abs(mouse.x - 400) > 150)
            return false;
            
        return true;
    }
    
    void run(int y)
    {
        auto textColor = Pixel32(128, 128, 128);
        
        if(menuActive)
        {
            textColor = mouseIn(y) ? Pixel32(255, 255, 255) : Pixel32(160, 160, 160);
            
            if(mouseIn(y) && mouse[SDL_BUTTON_LEFT].isFresh)
                doAction();
        }
            
        hudLayer.add(new ShadowText(text, 400, y, font, textColor));
        hudLayer.add(new ShadowText(leftText, 60, y, font, Pixel32(255,255,160), false));
            
        if(icon !is null)
            hudLayer.add(new FCSprite(icon, FixCoord(500, y + (TTF_FontHeight(font) / 2))));
    }
    
    @property SDL_Texture* icon()
    {
        return null;
    }
}

class MenuStart : MenuItem
{
    override string text()
    {
        return "Start!";
    }
    
    override void doAction()
    {
        recorder.setState(RecorderState.recording);
        recorder.playerTeam = menuPlayerTeam;
        recorder.enemyTeam = menuEnemyTeam;
    
        startPlay(teams[menuPlayerTeam], teams[menuEnemyTeam]);
    }
}

class MenuTeamPicker : MenuItem
{
    string name;
    int* teamVar;
    
    this(string newName, int* newVar)
    {
        name = newName;
        teamVar = newVar;
    }

    override string text()
    {
        return name;
    }
    
    override void doAction()
    {
        *teamVar = (*teamVar + 1) % cast(int) teams.length;
    }
    
    override SDL_Texture* icon()
    {
        return teams[*teamVar].texLife[true];
    }
}

class MenuReplays : MenuItem
{
    override string text()
    {
        return "Watch Replay";
    }
    
    override void doAction()
    {
        buildReplayList();
        currentMenu = replayMenu;
    }
}

class MenuQuit : MenuItem
{
    override string text()
    {
        return "Quit";
    }
    
    override void doAction()
    {
        gameLoop.quitting = true;
    }
}

class MenuKeybind : MenuItem
{
    string name;
    KeyBind* bind;
    
    this(string newName, KeyBind* newBind)
    {
        name = newName;
        bind = newBind;
    }
    
    override string text()
    {
        if(this is chosenBind)
            return ""; 
    
        return (*bind).name;
    }
    
    override string leftText()
    {
        return name;
    }
    
    override void doAction()
    {
        inputList.setListener(&rebindListener);
        chosenBind = this;
    }
}

class MenuBoolSetting : MenuItem
{
    string name;
    bool* setting;

    //Some settings require some extra code to be executed on toggle.
    //An example of this would be the Fullscreen setting.
    void function(bool) extraEffect;
    
    this(string newName, bool* newSetting, void function(bool) extra = null)
    {
        name = newName;
        setting = newSetting;
        extraEffect = extra;
    }
    
    override string text()
    {
        return *setting ? "On" : "Off";
    }
    
    override string leftText()
    {
        return name;
    }
    
    override void doAction()
    {   
        *setting = !*setting;

        if(extraEffect !is null)
            extraEffect(*setting);
    }
}

class MenuSettings : MenuItem
{
    override string text()
    {
        return "Settings";
    }
    
    override void doAction()
    {
        currentMenu = settingsMenu;
    }
}

class MenuBack : MenuItem
{
    override void run(int y)
    {
        y = 540;
    
        auto textColor = Pixel32(128, 128, 128);
        
        if(menuActive)
        {
            textColor = mouseIn(y) ? Pixel32(255, 255, 255) : Pixel32(160, 160, 160);
            
            if(mouseIn(y) && mouse[SDL_BUTTON_LEFT].isFresh)
                doAction();
        }
            
        hudLayer.add(new ShadowText(text, 400, y, bigFont, textColor));
    }

    override string text()
    {
        return "Back";
    }
    
    override void doAction()
    {   
        currentMenu = mainMenu;
    }
}

class MenuSaveReplay : MenuItem
{
    override string text()
    {
        return "Save Replay";
    }
    
    override void doAction()
    {
        if(lastGame.hasData)
        {
            savingReplay = true;
            textBuffer.start(&textEnter);       
        }
        else
        {
            setMenuMessage("There is no replay to save.");
        }
    }
}

class MenuReplayPicker : MenuItem
{
    override string text()
    {
        if(replayList.length == 0)
            return "NO REPLAY AVAILABLE";
    
        return replayList[chosenReplay].name;
    }
    
    override string leftText()
    {
        if(replayList.length == 0)
            return "Replay";
    
        return "Replay (" ~ (chosenReplay + 1).to!string ~ "/" ~ replayList.length.to!string ~ ")";
    }
    
    override void doAction()
    {
        if(++chosenReplay == replayList.length)
            chosenReplay = 0;
    }
}

class MenuWatch : MenuItem
{
    override string text()
    {
        return replayList.length != 0 ? "Watch" : "";
    }
    
    override void doAction()
    {
        if(replayList.length != 0)
        {
            string path = replayList[chosenReplay].path;
        
            currentMenu = mainMenu;
            
            try
            {
                recorder.load(path);
            }
            catch(Exception ex)
            {
                setMenuMessage("Replay Error: " ~ ex.msg);
                return;
            }
    
            if(recorder.hasData)
            {
                recorder.setState(RecorderState.playing);
                startPlay(teams[recorder.playerTeam], teams[recorder.enemyTeam]);
            }
            else
            {
                setMenuMessage("Replay is empty.");
            }
        }
    }
}


struct ReplayEntry
{
    string path;
    string name;
    
    this(string newPath, string newName)
    {
        path = newPath;
        name = newName;
    }
}

void buildReplayList()
{
    replayList.length = 0;
    chosenReplay = 0;
    
    try
    {
        foreach(string path; dirEntries(replayPath, "*.ssr", SpanMode.shallow))
        {
            auto name = path.baseName(".ssr");
            
            if(name == "auto")
                name = "Most Recent Game";
            
            replayList ~= ReplayEntry(path, name);
        }
    }
    catch(std.file.FileException)
    {
        //Just leave it empty if the directory cannot be found.
    }
}

void textEnter(string input)
{
    savingReplay = false;
    
    if(input == "")
        return;
        
    if(input.canFind('/') || input.canFind('\\'))
    {
        setMenuMessage("Illegal character in replay name.");
        return;
    }
    
    if(input.toLower == "auto")
    {
        setMenuMessage("Cannot use that name, \'auto\' is a reserved replay name.");
        return;
    }

    if(lastGame.save(replayPath ~ input ~ ".ssr") == true)
        setMenuMessage("Replay saved successfully.");
        
    else
        setMenuMessage("Failed to save replay.");
}

void setMenuMessage(string newMessage)
{
    menuMessage = newMessage;
    menuMessageTimer = 120;
}

void tickMenuMessage()
{
    if(menuMessageTimer)
    {
        if(--menuMessageTimer == 0) 
            menuMessage = "";
    }
}

void toggleFullscreen(bool isFullscreen)
{
    SDL_SetWindowFullscreen(window, isFullscreen ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);
}

void initMenus()
{
    mainMenu = new Menu("SaucerSmash", 150, 200);
    mainMenu.items ~= new MenuStart;
    mainMenu.items ~= new MenuTeamPicker("Player Team", &menuPlayerTeam);
    mainMenu.items ~= new MenuTeamPicker("Enemy Team", &menuEnemyTeam);
    mainMenu.items ~= new MenuReplays;
    mainMenu.items ~= new MenuSaveReplay;
    mainMenu.items ~= new MenuSettings;
    mainMenu.items ~= new MenuQuit;
    
    settingsMenu = new Menu("Game Settings", 100, 160);
    settingsMenu.items ~= new MenuKeybind("Move up", &upKey);
    settingsMenu.items ~= new MenuKeybind("Move down", &downKey);
    settingsMenu.items ~= new MenuKeybind("Move left", &leftKey);
    settingsMenu.items ~= new MenuKeybind("Move right", &rightKey);
    settingsMenu.items ~= new MenuKeybind("Overdrive", &dashKey);
    settingsMenu.items ~= new MenuKeybind("Targeted overdrive", &aimDashKey);
    settingsMenu.items ~= new MenuKeybind("Fire", &fireKey);
    settingsMenu.items ~= new MenuBoolSetting("Fullscreen mode", &menuFullscreen, &toggleFullscreen);
    settingsMenu.items ~= new MenuBoolSetting("Play ingame music", &menuPlayMusic);
    settingsMenu.items ~= new MenuBack;
    
    replayMenu = new Menu("Choose a Replay", 100, 160);
    replayMenu.items ~= new MenuReplayPicker;
    replayMenu.items ~= new MenuWatch;
    replayMenu.items ~= new MenuBack;
    
    currentMenu = mainMenu;
}

void runMenu()
{
    static int menuTick = 0;
    menuTick++;
    
    tickMenuMessage();

    if(currentMenu !is null)
        currentMenu.run();
       
    if(chosenBind !is null)
    {
        string bindMessage = "Choose a button to bind to action \'" ~ chosenBind.name ~ "\'...";
        hudLayer.add(new ShadowText(bindMessage, 400, 50, font, Pixel32(255, 255, 160)));
    }
    
    if(savingReplay)
    {
        hudLayer.add(new ShadowText("Choose a name for your replay", 400, 20, font, Pixel32(255, 255, 160)));
        
        char endChar = ' ';
        
        if((menuTick / 8) & 1)
            endChar = '_';
        
        hudLayer.add(new ShadowText(textBuffer.buffer ~ endChar, 400, 50, font, Pixel32(255,255,255), true));
    }
    
    hudLayer.add(new ShadowText(menuMessage, 400, 550, font, Pixel32(255,255,255), true));
}

void rebindListener(KeyBind newBind)
{
    *(chosenBind.bind) = newBind;
    chosenBind = null;
    inputList.unsetListener();
}

bool menuActive()
{
    return chosenBind is null && !savingReplay;
}
