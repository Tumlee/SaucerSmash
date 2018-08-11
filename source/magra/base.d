//This is the base file to be imported, which automatically includes all
//of the essential parts of the Magra game engine.
module magra.base;

public import derelict.sdl2.sdl;
public import derelict.sdl2.mixer;
public import derelict.sdl2.image;
public import derelict.sdl2.ttf;

public import magra.actor;
public import magra.actorlist;
public import magra.gameloop;

public import magra.canvas;
public import magra.layer;
public import magra.drawer;

public import magra.sound;
public import magra.input;

public import magra.confighandler;
public import magra.init;
public import magra.resource;
public import magra.globals;
public import magra.directories;
