module magra.input;

import magra.video;
import derelict.sdl2.sdl;
import std.conv;
import std.string;
import std.algorithm;
import std.exception;
import std.array;
import std.ascii;

//The global list of input devices. This unfortunately must
//remain global because it is used by KeyBind.getState()
InputList inputList;

//A dictionary that gives descriptive names
//to different key bindings.
string[int][string] bindNames;

//An enumerated list of all registered gamepads.
GameController[int] gamepads;

//============================================
//A type that represents the state of a key on
//a keyboard or button on a mouse.
//============================================
enum KeyState
{
    up,         //Not pressed down.
    down,       //Pressed down.
    released,   //Not pressed down, just released this tick.
    fresh       //Pressed down, just pressed this tick.
}

//=====================================================================
//These functions return whether or not the given KeyState represents
//one that is up, down, released, or fresh. Note that a key that was
//just freshly pressed still counts as "down", and one that was freshly
//released still counts as "up".
//=====================================================================
bool isDown(KeyState state)
{
    return state == KeyState.down || state == KeyState.fresh;
}

bool isFresh(KeyState state)
{
    return state == KeyState.fresh;
}

bool isUp(KeyState state)
{
    return state == KeyState.up || state == KeyState.released;
}

bool isReleased(KeyState state)
{
    return state == KeyState.released;
}

//===================================================================
//A parent class describing the different functions of an InputDevice
//===================================================================
class InputDevice
{
    //What to do when the device receives an SDL Event.
    abstract int handleEvent(SDL_Event event);
    
    //What to do when the device ticks. Usually, this is just updating
    //any buttons that were listed as "fresh" to a "down" state, etc.
    abstract void tick();
    
    //What to do when the device is told to be cleared. Usually,
    //this involves treating all buttons as if they were just released.
    abstract void clear();
    
    //What to return when queried for an enumerated button or key.
    abstract KeyState opIndex(int key);
}

//=======================================================
//Class that describes the current state of the keyboard.
//=======================================================
class Keyboard : InputDevice
{
    //Keys are created dynamically as they are pressed.
    KeyState[int] keys;
    
    //==================================================
    //Handles incoming SDL_KEYDOWN and SDL_KEYUP events.
    //==================================================
    override int handleEvent(SDL_Event event)
    {
        if(event.type == SDL_KEYDOWN && !event.key.repeat)
        {
            keys[event.key.keysym.sym] = KeyState.fresh;
            return event.key.keysym.sym;
        }
        
        if(event.type == SDL_KEYUP && !event.key.repeat)
            keys[event.key.keysym.sym] = KeyState.released;
            
        return -1;
    }
    
    //============================================
    //Updates the state of the keys on a keyboard.
    //============================================
    override void tick()
    {
        //FIXME: Maybe std.algorithm replace() function?
        foreach(ref state; keys)
        {
            if(state.isFresh)
                state = KeyState.down;

            if(state.isReleased)
                state = KeyState.up;
        }
    }
    
    //======================================================
    //Treats all pressed keys as if they were just released.
    //======================================================
    override void clear()
    {
        foreach(ref state; keys)
        {
            if(state.isDown)
                state = KeyState.released;
        }
    }
    
    //=====================================================
    //Returns the state of the given key. Keys that are not
    //recognized are treated as if they are always up.
    //=====================================================
    override KeyState opIndex(int key)
    {
        return keys.get(key, KeyState.up);
    }
}

//====================================================
//Class that describes the current state of the mouse.
//====================================================
class Mouse : InputDevice
{
    KeyState[int] buttons;
    
    //Information about current state of buttons.
    int x, y;
    int dx, dy;
    int wheelx, wheely;
    
    //Information that is accumulated through events,
    //and actually takes effect later. 
    int accRelx, accRely;
    int accWheelx, accWheely;
    
    //=====================================================
    //Handles all events that have to do with mouse buttons
    //and mouse motion.
    //=====================================================
    override int handleEvent(SDL_Event event)
    {
        if(event.type == SDL_MOUSEBUTTONDOWN)
        {
            buttons[event.button.button] = KeyState.fresh;
            return event.button.button;
        }
            
        if(event.type == SDL_MOUSEBUTTONUP)
            buttons[event.button.button] = KeyState.released;
            
        if(event.type == SDL_MOUSEMOTION)
        {
            x = event.motion.x;
            y = event.motion.y;
            
            accRelx = event.motion.xrel;
            accRely = event.motion.yrel;

            //Because the borderless windowed mode allows the mouse cursor to escape
            //into the black letterbox bars, we must forcibly warp the cursor back into the play area.
            //For some reason beyond my understanding, SDL2 uses the logical coordinate system when
            //reporting the mouse cursor position, but uses actual screen coordinates when warping
            //the mouse cursor, so we have to scale these coordinates manually.
            if(SDL_GetWindowGrab(window) == true)
            {
                //This is what SDL has scaled screen width to in fullscreen.
                int scaledScreenwidth = logicalScreenwidth * actualScreenheight / logicalScreenheight;
                int blackBarWidth = (actualScreenwidth - scaledScreenwidth) / 2;
                int scaledMouseY = (y * actualScreenheight) / logicalScreenheight;

                if(x < 0)
                {
                    int scaledMouseX = blackBarWidth;
                    SDL_WarpMouseInWindow(window, scaledMouseX, scaledMouseY);
                }
                else if(x >= logicalScreenwidth)
                {
                    int scaledMouseX = actualScreenwidth - blackBarWidth - 1;
                    SDL_WarpMouseInWindow(window, scaledMouseX, scaledMouseY);
                }
            }
        }
        
        if(event.type == SDL_MOUSEWHEEL)
        {
            accWheelx += event.wheel.x;
            accWheely += event.wheel.y;
        }
        
        return -1;
    }
    
    //===================================================
    //Updates the state of mouse buttons and the relative
    //mouse positions.
    //===================================================
    override void tick()
    {
        dx = accRelx;
        dy = accRely;
        
        wheelx = accWheelx;
        wheely = accWheely;
        
        accRelx = 0;
        accRely = 0;
        
        accWheelx = 0;
        accWheely = 0;
    
        foreach(ref state; buttons)
        {
            if(state.isFresh)
                state = KeyState.down;

            if(state.isReleased)
                state = KeyState.up;
        }
    }
    
    //===============================================================
    //Treats all pressed mouse buttons as if they were just released.
    //===============================================================
    override void clear()
    {
        foreach(ref state; buttons)
        {
            if(state.isDown)
                state = KeyState.released;
        }
    }

    //=========================================================
    //Returns the state of the given mouse button. Buttons that
    //are not recognized are treated as if they are always up.
    //=========================================================
    override KeyState opIndex(int but)
    {
        return buttons.get(but, KeyState.up);
    }
}

//============================================================
//Class that describes the current state of a game controller.
//Note that GameControllers are not input devices for now.
//This may change in the future.
//============================================================
class GameController
{
    KeyState[string] buttons;
    float[string] axes;
    int instanceID;

    this(int id)
    {
        instanceID = id;
    }

    //=======================================================
    //Handles all events that have to do with gamepad buttons
    //and axis changes.
    //=======================================================
    void handleEvent(SDL_Event event)
    {
        //event.cbutton.button is a ubyte, but SDL_GameControllerGetStringForButton() requires
        //an SDL_GameControllerButton
        SDL_GameControllerButton buttonID = cast(SDL_GameControllerButton) event.cbutton.button;

        //Same deal for event.caxis.axis.
        SDL_GameControllerAxis axisID = cast(SDL_GameControllerAxis) event.caxis.axis;
        
        if(event.type == SDL_CONTROLLERBUTTONDOWN)
        {
            if(instanceID == event.cbutton.which)
            {
                string buttonName = SDL_GameControllerGetStringForButton(buttonID).to!string;
                buttons[buttonName] = KeyState.fresh;
            }
        }

        if(event.type == SDL_CONTROLLERBUTTONUP)
        {
            if(instanceID == event.cbutton.which)
            {
                string buttonName = SDL_GameControllerGetStringForButton(buttonID).to!string;
                buttons[buttonName] = KeyState.released;
            }
        }

        if(event.type == SDL_CONTROLLERAXISMOTION)
        {
            if(instanceID == event.caxis.which)
            {
                string axisName = SDL_GameControllerGetStringForAxis(axisID).to!string;
                axes[axisName] = event.caxis.value / 32768.0;
            }
        }
    }

    //===================================================
    //Updates the state of mouse buttons and the relative
    //mouse positions.
    //===================================================
    void tick()
    {  
        foreach(ref state; buttons)
        {
            if(state.isFresh)
                state = KeyState.down;

            if(state.isReleased)
                state = KeyState.up;
        }
    }

    //===============================================================
    //Returns the value of the given axis. If the axis doesn't exist,
    //it is treated as zero.
    //===============================================================
    float getAxis(string axisName)
    {
        return axes.get(axisName, 0.0);
    }
    
    //============================================================
    //Returns the state of the given button. If the button doesn't
    //exist, it is treated as an always-released button.
    //============================================================
    KeyState getButton(string buttonName)
    {
        return buttons.get(buttonName, KeyState.up);
    }
}

//=================================================
//Represents a pressable button on an input device.
//It consists of a device name and a button index.
//=================================================
struct KeyBind
{
    string deviceName;
    int index;
    
    //=====================================================
    //Initializes the KeyBind with a device name and index.
    //=====================================================
    this(string dev, int ind)
    {
        index = ind;
        deviceName = dev;
    }

    //=================================================================
    //KeyBinds in a string form have a format of "<deviceName>:<index>"
    //=================================================================
    this(string str)
    {
        auto split = str.strip.findSplit(":");
        
        //Check each value in the split to ensure
        //that none of them are empty.
        foreach(s; split)
        {
            if(s.empty)
                throw new ConvException("Invalid conversion from string to KeyBind");
        }
        
        deviceName = split[0];
        index = split[2].to!int;
    }
    
    //======================================
    //Conversion from a KeyBind to a string.
    //======================================
    string toString()
    {
        return deviceName ~ ":" ~ index.to!string;
    }
    
    //================================================
    //Returns the KeyState of the button pointed to by
    //the device name and button index.
    //================================================
    KeyState getState()
    {
        try
        {
            return inputList.devices[deviceName][index];
        }
        catch(core.exception.RangeError)
        {
            //Buttons that don't exist are treated as always up.
            return KeyState.up;
        }
    }
    
    //===========================================================
    //These functions return whether or not the pointed-to button
    //is up, down, fresh, or released.
    //===========================================================
    @property bool isDown()
    {        
        return getState.isDown;
    }
    
    @property bool isFresh()
    {
        return getState.isFresh;
    }
    
    @property bool isUp()
    {
        return getState.isUp;
    }
    
    @property bool isReleased()
    {
        return getState.isReleased;
    }
    
    //========================================================
    //Returns a "pretty" name for the KeyBind. If one doesn't
    //exist, it just converts the KeyBind to a string instead.
    //========================================================
    @property string name()
    {
        try
        {
            return bindNames[deviceName][index];
        }
        catch(core.exception.RangeError)
        {
            return toString;
        }
    }
}

//========================================================
//An InputList is a container for InputDevices, where they
//can be looked up by a string identifier.
//FIXME: Best made global?
//========================================================
class InputList
{
    //The list of InputDevices, lookup by string.
    InputDevice[string] devices;
    
    //A listener function that can be set to execute whenever
    //a button is pressed down.
    void function(KeyBind) listener = null;
    
    //======================================================
    //Passes the given event to each device to see if it can
    //handle the event, and activates the listener if so.
    //======================================================
    void handleEvent(SDL_Event event)
    {
        foreach(devName; devices.byKey)
        {
            int status = devices[devName].handleEvent(event);
            
            if(status != -1 && listener !is null)
                listener(KeyBind(devName, status));
        }
    }
    
    //=================================================================
    //Ticks each input device. See InputDevice.tick() for more details.
    //=================================================================
    void tick()
    {
        foreach(device; devices)
            device.tick();
    }
    
    //===================================================================
    //Clears each input device. See InputDevice.clear() for more details.
    //===================================================================
    void clear()
    {
        foreach(device; devices)
            device.clear();
    }
    
    //=====================================================================
    //Functions for setting and clearing the InputList's listener function.
    //=====================================================================
    void setListener(void function(KeyBind) newListener)
    {
        listener = newListener;
    }
    
    void unsetListener()
    {   
        listener = null;
    }
}

//=============================================================
//This class handles text input that comes in via SDL_TEXTINPUT
//events.
//FIXME: Best made global?
//=============================================================
class TextBuffer
{
    string buffer = "";
    ulong maxChars = 0;
    bool active = false;
    void function(string) action = null;
    
    //============================================
    //Prepares the TextBuffer for accepting input.
    //============================================
    void start(void function(string) newAction = null, ulong mChars = 0)
    {
        SDL_StartTextInput();   //Start text input on SDL's side.
        active = true;          //Mark the TextBuffer as active.
        buffer = "";            //Initialize the buffer to blank.
        maxChars = mChars;      //Set up character limit.
        action = newAction;     //Register the action function.
    }
    
    //===========================
    //Deactivates the TextBuffer.
    //===========================
    void end()
    {
        SDL_StopTextInput();    //Stop text input on SDL's side.
        active = false;         //Mark the TextBuffer as inactive.
    }
    
    //=========================================
    //Handle an incoming event to accept input.
    //=========================================
    void handleEvent(SDL_Event event)
    {
        if(active == false)
            return;
    
        if(event.type == SDL_TEXTINPUT)
        {
            //Accept the character into the buffer, as long as
            //it does not go past the character limit.
            if(buffer.length < maxChars || maxChars == 0)
                buffer ~= event.text.text[0];
        }
        
        //Certain keys must be handled as a special case.
        if(event.type == SDL_KEYDOWN)
        {
            auto keyCode = event.key.keysym.sym;
        
            //Handle backspace, erasing a character if there is one.
            if(keyCode == SDLK_BACKSPACE && buffer.length != 0)
                buffer = buffer[0 .. $ - 1];
            
            //Handle the enter key, submitting the buffer
            //and calling the action function.
            if(keyCode == SDLK_RETURN)
            {
                if(action !is null)
                    action(buffer);
                    
                end();  //Deactivate the TextBuffer.
            }
            
            //Escape key counts as blanking all input and then
            //submitting it.
            if(keyCode == SDLK_ESCAPE)
            {     
                if(action !is null)
                    action("");
                    
                end();  //Deactivate the TextBuffer.
            }
        }
    }
}

//=============================================
//Initializes various input-related constructs.
//=============================================
static this()
{
    //Create the inputList.
    inputList = new InputList;
    
    //Initialize the "pretty" names for KeyBinds, starting with ASCII keys.
    foreach(char c; '!' .. '~')
        bindNames["keyboard"][c] = std.ascii.toUpper(c).to!string;
        
    //F1 - F12 keys.
    foreach(f; 0 .. 12)
        bindNames["keyboard"][SDLK_F1 + f] = "F" ~ (f + 1).to!string;

    //Other keys on the keyboard.
    bindNames["keyboard"][SDLK_UP] = "Up Arrow";
    bindNames["keyboard"][SDLK_DOWN] = "Down Arrow";
    bindNames["keyboard"][SDLK_RIGHT] = "Right Arrow";
    bindNames["keyboard"][SDLK_LEFT] = "Left Arrow";
    bindNames["keyboard"][SDLK_SPACE] = "Space";
    bindNames["keyboard"][SDLK_RALT] = "Right ALT";
    bindNames["keyboard"][SDLK_LALT] = "Left ALT";
    bindNames["keyboard"][SDLK_RCTRL] = "Right CTRL";
    bindNames["keyboard"][SDLK_LCTRL] = "Left CTRL";
    bindNames["keyboard"][SDLK_RSHIFT] = "Right Shift";
    bindNames["keyboard"][SDLK_LSHIFT] = "Left Shift";
    bindNames["keyboard"][SDLK_TAB] = "Tab";
    bindNames["keyboard"][SDLK_BACKSPACE] = "Backspace";
    bindNames["keyboard"][SDLK_ESCAPE] = "Escape";
    bindNames["keyboard"][SDLK_END] = "End";
    bindNames["keyboard"][SDLK_INSERT] = "Insert";
    bindNames["keyboard"][SDLK_HOME] = "Home";
    bindNames["keyboard"][SDLK_DELETE] ="Delete";
    bindNames["keyboard"][SDLK_PAGEDOWN] = "Page Down";
    bindNames["keyboard"][SDLK_PAGEUP] = "Page Up";
    bindNames["keyboard"][SDLK_CAPSLOCK] = "Caps Lock";
    bindNames["keyboard"][SDLK_RETURN] = "Enter";

    //Buttons on the mouse as well.    
    bindNames["mouse"][SDL_BUTTON_LEFT] = "Left Mouse";
    bindNames["mouse"][SDL_BUTTON_RIGHT] = "Right Mouse";
    bindNames["mouse"][SDL_BUTTON_MIDDLE] = "Middle Mouse";
}

//=============================================================================
//Ensures that all connected controllers are registered in the gamepads[] list.
//This is called on engine initialization and when gamepads are added/removed.
//=============================================================================
void registerGamepads()
{
    //Remove any existing gamepads first.
    foreach(key; gamepads.byKey)
        gamepads.remove(key);

    foreach(i; 0 .. SDL_NumJoysticks())
    {
        if(SDL_IsGameController(i))
        {
            auto gamepad = SDL_GameControllerOpen(i);
        
            if(gamepad is null)
                continue;

            //FIXME: I'm unsure if i is necessarily the instanceID in this case...
            gamepads[i] = new GameController(i);
        }
    }
}

//=============================================================================
//Returns the gamepad with the matching instanceID.
//If the gamepad with the instanceID doesn't exist, it returns a dummy gamepad.
//=============================================================================
GameController getGamepad(int instanceID)
{
    static GameController dummyController = null;

    if(dummyController is null)
        dummyController = new GameController(-1);

    return gamepads.get(instanceID, dummyController);
}

//====================================================
//Returns the number of gamepads currently registered.
//====================================================
ulong numGamepads()
{
    return gamepads.length;
}
