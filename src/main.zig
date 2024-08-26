const std = @import("std");
const rl = @import("raylib");

const Settings = struct {
    widht: i32,
    height: i32,
    pixelScale: i32,
    fps: i32,
    title: []const u8,
};

const Chip = struct {
    memory: [4096]u8,
    display: [64][32]u8,
    stack: [32]u16,
    pc: u16,
    sp: u16,
    I: u16,
    registers: [16]u8,
};

const settings = Settings{
    .widht = 64,
    .height = 32,
    .pixelScale = 8,
    .fps = 60,
    .title = "Chip-8 emulator Zig",
};

fn setup() void {
    rl.initWindow(settings.widht * settings.pixelScale, settings.height * settings.pixelScale, settings.title);
    rl.setTargetFPS(settings.fps);
}

fn render() void {
    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);
    rl.drawText("Chip-8 emulator Zig", 190, 200, 20, rl.Color.white);
    defer rl.endDrawing();
}

pub fn main() anyerror!void {
    setup();
    while (!rl.windowShouldClose()) {
        render();
    }
    defer quit();
}

fn quit() void {
    rl.closeWindow();
}

fn fetch(self: *Chip) [2]u8 {
    // TODO: error if self.sp + 1 > self.memory.len
    const b0 = self.memory[self.sp];
    const b1 = self.memory[self.sp + 1];

    return .{ b0, b1 };
}

const DecodeResult = struct {
    inst: u4,
    X: u8,
    Y: u8,
    N: u8,
    NN: u8,
    NNN: u16,
};

fn decode(self: *Chip) DecodeResult {
    const b = fetch(self);
    const b0 = b[0];
    const b1 = b[1];

    const inst: u4 = (b0 & 0xF0) >> 4;
    const X: u8 = b0 & 0x0F;
    const Y: u8 = (b1 & 0xF0) >> 4;
    const N: u8 = b1 & 0x0F;
    const NN: u8 = b1;
    const NNN: u16 = @as(u16, X << 8) | @as(u16, NN);

    return DecodeResult{
        .inst = inst,
        .X = X,
        .Y = Y,
        .N = N,
        .NN = NN,
        .NNN = NNN,
    };
}

fn execute(self: *Chip) void {
    const dec = decode(self);
    switch (dec.inst) {
        0x0 => switch (dec.Y) {
            0xE => switch (dec.N) {
                0x0 => {
                    self.display = [62][32]u8;
                },
            },
        },
        0x1 => {
            self.pc = dec.NNN;
        },
        0x6 => {
            self.registers[dec.X] = dec.NN;
        },
        0x7 => {
            self.registers[dec.X] += dec.NN;
        },
        0xA => {
            self.I = dec.NNN;
        },
        0xD => {
            drawSprite(self, self.registers[dec.X], self.registers[dec.Y], dec.N);
        },
    }
}

fn drawSprite(self: *Chip, v_x: u8, v_y: u8, n: u8) void {
    v_x = v_x % settings.widht;
    v_y = v_y % settings.height;
    self.registers[0xF] = 0;
    _ = n;
}
