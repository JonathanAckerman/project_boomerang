WINDOW_WIDTH :: 1536;
WINDOW_HEIGHT :: 864;
WINDOW_CENTER :: Vector2.{WINDOW_WIDTH/2.0, WINDOW_HEIGHT/2.0};

main :: () {
    window_title := to_c_string("PROJECT BOOMERANG");
    InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, window_title);
    SetTargetFPS(60);
    // SetExitKey(0); // for now leave esc it makes it faster to debug
    SetTraceLogLevel(xx TraceLogLevel.LOG_NONE);
    SetMouseCursor(xx MouseCursor.CROSSHAIR);

    game.resetting = true;
    while game.resetting {
        game_reset();
        while !WindowShouldClose() && !game.resetting game_loop();
    }
    CloseWindow();
}

#load "Entity.jai";
#load "Game.jai";
#load "Input.jai";
#load "Utils.jai";
#load "Animation.jai";
#load "Graphics.jai";
#load "Fonts.jai";
#load "Serialize.jai";
#load "AI.jai";
#load "Collision.jai";
#load "Particles.jai";
#load "Time.jai";
#load "Dog.jai";

#import "Math";
#import "Basic";
#import "Random";
#import "Bucket_Array";
#import "File";
#import "File_Utilities";   // File_Visit_Info
#import "Hash_Table";       // Table
#import "String";           // slice(), path_strip_filename()
#import "Sort";
#import "System";           // get_path_of_running_executable()

#import "Entity_Storage";
#import "Raylib-Jai";
