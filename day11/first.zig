const std = @import("std");
const dprint = std.debug.print;
const kb = 1024;

const powers_of_10s: [37]u128 = comptime_10_powers_arr();

pub fn main(init: std.process.Init) anyerror!void {
    const gpa = init.gpa;
    const io = init.io;

    const contents = try std.Io.Dir.readFileAlloc(std.Io.Dir.cwd(), io, "input.txt", gpa, std.Io.Limit.unlimited);
    defer gpa.free(contents);
    var stones_iter = std.mem.tokenizeSequence(u8, contents, " ");
    var stones = try std.ArrayList(u128).initCapacity(gpa, 32*kb);
    defer stones.deinit(gpa);
    while (stones_iter.next()) |stone| {
        const stone_num = try std.fmt.parseInt(u128, stone, 10);
        try stones.append(gpa, stone_num);
    }

    for (1..76) |_| {
        try blink_iteration(gpa, &stones);
        // dprint("{} Stones: {any}\n", .{i, stones.items});
        dprint("{} ", .{stones.items.len});
    }

    dprint("Stones after 25 interations: {}", .{stones.items.len});
}

pub fn blink_iteration(gpa: std.mem.Allocator, stones: *std.ArrayList(u128)) anyerror!void {
    var new_stones = try std.ArrayList(u128).initCapacity(gpa, stones.items.len);
    defer new_stones.deinit(gpa);
    for (stones.items) |*stone| {
        if (stone.* == 0) {
            stone.* = 1;
        } else {
            const cur_stone_digits_amount = digits_amount(stone.*);
            if (cur_stone_digits_amount%2 == 0) {
                const half_power = powers_of_10s[(cur_stone_digits_amount >> 1) - 1];
                const second_stone = stone.* / half_power;
                try new_stones.append(gpa, second_stone);
                const new_first_stone = stone.* - second_stone * half_power;
                stone.* = new_first_stone;
            } else {
                stone.* *= 2024;
            }
        } 
    }
    try stones.appendSlice(gpa, new_stones.items);
}

pub fn digits_amount(num: u128) usize {
    inline for (powers_of_10s, 1..) |power, i| {
        if (num < power) {
            return i;
        }
    }
    return 37;
}

pub fn comptime_10_powers_arr() [37]u128 {
    var powers: [37]u128 = undefined;
    var accum: u128 = 10;
    var i: u8 = 0;
    inline while (i < 37) : (i += 1) {
        powers[i] = accum;
        accum *= 10;
    }
    return powers;
}