const std = @import("std");
const rl = @import("raylib");

const Settings = struct {
    widht: i32,
    height: i32,
    pixelScale: i32,
    fps: i32,
    title: [*:0]const u8,
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

var screenImage: *rl.Image = null;
var screenTexture: rl.Texture2D = null;
var chip = Chip{
    .memory = [_]u8{0} ** 4096,
    .display = [_][32]u8{[_]u8{0} ** 32} ** 64,
    .stack = [_]u16{0} ** 32,
    .pc = 0x200,
    .sp = 0,
    .I = 0,
    .registers = [_]u8{0} ** 16,
};
const memoryOffset = 0x200;

fn setup() void {
    loadRom(&chip, "./roms/Logo.ch8") catch |err| {
        std.debug.print("Failed to load rom: {}\n", .{err});
    };
    rl.initWindow(settings.widht * settings.pixelScale, settings.height * settings.pixelScale, settings.title);
    rl.setTargetFPS(settings.fps);
    screenImage = rl.genImageColor(settings.widht, settings.height, rl.Color.black);
    screenTexture = rl.loadTextureFromImage(screenImage);
}

fn render() void {
    rl.beginDrawing();
    rl.drawText("Chip-8 emulator Zig", 190, 200, 20, rl.Color.white);
    execute(&chip);
    rl.updateTexture(screenTexture, rl.loadImageColors(screenImage));
    rl.drawTextureEx(screenTexture, rl.Vector2{ 0, 0 }, 0, @as(f32, settings.pixelScale), rl.Color.white);
    rl.endDrawing();
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
    inst: u8,
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

    const inst: u8 = (b0 & 0xF0) >> 4;
    const X: u8 = b0 & 0x0F;
    const Y: u8 = (b1 & 0xF0) >> 4;
    const N: u8 = b1 & 0x0F;
    const NN: u8 = b1;
    const NNN: u16 = @as(u16, X) << 8 | @as(u16, NN);

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
                    self.display = [_][32]u8{[_]u8{0} ** 32} ** 64;
                },
                else => unreachable,
            },
            else => unreachable,
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
        else => unreachable,
    }
}

fn drawSprite(self: *Chip, v_x: u8, v_y: u8, n: u8) void {
    const x = v_x % settings.widht;
    const y = v_y % settings.height;
    self.registers[0xF] = 0;
    for (0..n) |row| {
        const spriteByte = self.memory[self.I + row];
        var col: u4 = 0;
        while (col < 8) : (col += 1) {
            const index = (0x80 >> col);
            if (x + col > 63) {
                break;
            }
            if (spriteByte & index) {
                if (x + col > settings.widht) {
                    break;
                }
                const posX = (x + col) & settings.widht;
                const posY = (y + row) & settings.height;
                if (self.display[posX][posY] == 1) {
                    self.registers[0xF] = 1;
                }
                self.display[posX][posY] ^= 1;
            }
        }
    }
    drawImage(self, screenImage);
}

fn drawImage(self: *Chip, image: *rl.Image) void {
    for (self.display, 0..) |_, x| {
        for (self.display[x], 0..) |value, y| {
            if (value > 0) {
                rl.imageDrawPixel(image, x, y, rl.Color.white);
            }
        }
    }
}

fn loadRom(self: *Chip, filename: []const u8) !void {
    const rom = try std.fs.cwd().readFileAlloc(std.heap.page_allocator, filename, 1024);
    defer std.heap.page_allocator.free(rom);
    for (rom, 0..) |byte, i| {
        self.memory[memoryOffset + i] = byte;
    }
}
