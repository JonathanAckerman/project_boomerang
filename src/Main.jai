WINDOW_WIDTH :: 1536;
WINDOW_HEIGHT :: 864;
WINDOW_CENTER :: Vector2.{WINDOW_WIDTH/2.0, WINDOW_HEIGHT/2.0};

main :: () {
    window_title := to_c_string("PROJECT BOOMERANG");
    InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, window_title);
    SetTargetFPS(60);
    SetExitKey(0);
    SetMouseCursor(xx MouseCursor.CROSSHAIR);
    the_font = LoadFont(temp_c_string("assets/font/mecha.png"));

    game.resetting = true;
    while game.resetting {
        game_reset();
        while !WindowShouldClose() && !game.resetting game_loop();
    }
    CloseWindow();
}

the_font: Font;

#load "Entity.jai";
#load "Game.jai";
#load "Input.jai";
#load "Util.jai";

#import "Math";
#import "Basic";
#import "Random";
#import "Bucket_Array";

#import "Entity_Storage";
#import "Raylib-Jai";
