const std = @import("std");
const print = std.debug.print;
const panic = std.debug.panic;
const kb = 1204;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{ .mode = .read_only});
    defer file.close();

    const file_buffer = try file.readToEndAlloc(alloc, 64*kb);
    defer alloc.free(file_buffer);

    var lines_iter = std.mem.splitAny(u8, file_buffer, "\n");

    var antennas = std.AutoHashMap(u8, *std.ArrayList([2]usize)).init(alloc);
    defer {
        var val_iter = antennas.valueIterator();
        while (val_iter.next()) |val| {
            val.*.deinit();
            alloc.destroy(val.*);
        }
        antennas.deinit();
    }

    {
        var y: usize = 0;
        while (lines_iter.next()) |line| {
            for (line, 0..) |c, x| {
                switch (c) {
                    '.' => continue,
                    else => {
                        if (antennas.contains(c)) {
                            try antennas.get(c).?.*.append(.{x, y});
                        } else {
                            const one_freq_antennas = try alloc.create(std.ArrayList([2]usize));
                            one_freq_antennas.* = std.ArrayList([2]usize).init(alloc);
                            try one_freq_antennas.*.append(.{x, y});
                            try antennas.put(c, one_freq_antennas);
                        }
                    }
                }
            }
            y += 1;
        }
    }

    var antinodes_field: [50][50]bool = .{.{false} ** 50} ** 50;
    var antennas_iter = antennas.valueIterator();
    while (antennas_iter.next()) |one_freq_ant| {
        const ant_group_slice = one_freq_ant.*.*.items;
        for (ant_group_slice, 1..) |ant, i| {
            for (ant_group_slice[i..]) |other_ant| {
                const x_diff: i128 = @as(i128, ant[0]) - @as(i128, other_ant[0]);
                const y_diff: i128 = @as(i128, ant[1]) - @as(i128, other_ant[1]);

                antinodes_field[ant[0]][ant[1]] = true;
                antinodes_field[other_ant[0]][other_ant[1]] = true;

                var antinode_1: [2]i128 = .{ant[0] + x_diff, ant[1] + y_diff};
                while (antinode_1[0] >= 0 and antinode_1[0] < 50 and antinode_1[1] >= 0 and antinode_1[1] < 50) {
                    antinodes_field[@truncate(@abs(antinode_1[0]))][@truncate(@abs(antinode_1[1]))] = true;
                    antinode_1[0] += x_diff;
                    antinode_1[1] += y_diff;
                }

                var antinode_2: [2]i128 = .{other_ant[0] - x_diff, other_ant[1] - y_diff};
                while (antinode_2[0] >= 0 and antinode_2[0] < 50 and antinode_2[1] >= 0 and antinode_2[1] < 50) {
                    antinodes_field[@truncate(@abs(antinode_2[0]))][@truncate(@abs(antinode_2[1]))] = true;
                    antinode_2[0] -= x_diff;
                    antinode_2[1] -= y_diff;
                }
            }
        }
    }

    var antinodes_amount: usize = 0;
    for (antinodes_field) |af_line| {
        for (af_line) |af_point| {
            if (af_point) {
                antinodes_amount += 1;
            }
        }
    }
    print("Total antinodes within field (with effect of resonant harmonics): {d}", .{antinodes_amount});
}