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
    var stones = std.AutoHashMap(u128, usize).init(gpa);
    while (stones_iter.next()) |stone| {
        const stone_num = try std.fmt.parseInt(u128, stone, 10);
        try stones.put(stone_num, 1);
    }

    for (0..75) |_| {
        try blink_iteration(gpa, &stones);
    }
    
    var total_stones: u128 = 0;
    var stones_amounts_iter = stones.valueIterator();
    while (stones_amounts_iter.next()) |stone_amount| {
        total_stones += stone_amount.*;
    }

    stones.deinit();

    dprint("Stones after 75 interations: {}", .{total_stones});
}

pub fn blink_iteration(gpa: std.mem.Allocator, stones: *std.AutoHashMap(u128, usize)) anyerror!void {
    var new_stones = std.AutoHashMap(u128, usize).init(gpa);
    var stones_iter = stones.iterator();
    while (stones_iter.next()) |*stone| {
        const stone_num = stone.*.key_ptr.*;
        const stones_amount = stone.*.value_ptr.*;
        if (stone_num == 0) {
            try add_stones(&new_stones, 1, stones_amount);
        } else {
            const cur_stone_digits_amount = digits_amount(stone_num);
            if (cur_stone_digits_amount%2 == 0) {
                const half_power = powers_of_10s[(cur_stone_digits_amount >> 1) - 1];
                const second_stone = stone_num / half_power;
                const new_first_stone = stone_num - second_stone * half_power;
                try add_stones(&new_stones, second_stone, stones_amount);
                try add_stones(&new_stones, new_first_stone, stones_amount);
            } else {
                try add_stones(&new_stones, stone_num * 2024, stones_amount);
            }
        } 
    }
    stones.*.deinit();
    stones.* = new_stones;
}

pub fn add_stones(stones: *std.AutoHashMap(u128, usize), stone_num: u128, stones_amount: usize) anyerror!void {
    const stones_entry = try stones.getOrPutValue(stone_num, 0);
    stones_entry.value_ptr.* += stones_amount;
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