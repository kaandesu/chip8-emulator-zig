const std = @import("std");
const rl = @import("raylib");

const Chip8 = struct {
    widht: i32,
    height: i32,
    pixelScale: i32,
    fps: i32,
};

pub fn main() anyerror!void {
    const chip8 = Chip8{
        .widht = 64,
        .height = 32,
        .pixelScale = 8,
        .fps = 60,
    };

    rl.initWindow(chip8.widht * chip8.pixelScale, chip8.height * chip8.pixelScale, "Chip-8 emulator Zig");
    defer rl.closeWindow();

    rl.setTargetFPS(chip8.fps);

    setup();
    while (!rl.windowShouldClose()) {
        render();
    }
}

fn setup() void {}
fn render() void {
    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);
    rl.drawText("Chip-8 emulator Zig", 190, 200, 20, rl.Color.white);
    defer rl.endDrawing();
}
