main :: () {
    window_title := to_c_string("PROJECT BOOMERANG");
    InitWindow(800, 600, window_title);
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
