const std = @import("std");
const print = std.debug.print;
const kb = 1024;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{ .mode = .read_only });
    defer file.close();

    const file_buffer = try file.readToEndAlloc(alloc, 64*kb);
    defer alloc.free(file_buffer);

    var lines_iter = std.mem.splitSequence(u8, file_buffer, "\n");

    const field_size: usize = 130;

    var guard_x: usize = undefined;
    var guard_y: usize = undefined;
    var guard_direction: u2 = 0;
    var visited_pos_amount: usize = 1;

    var visited_cords: [field_size][field_size]bool = .{.{false} ** field_size} ** field_size;
    var field: [field_size][field_size]u8 = .{ .{' '} ** field_size} ** field_size;

    var i: usize = 0;

    while (lines_iter.next()) |line| {
        for (line[0..line.len-1], 0..) |c, j| {
            const s: u8 = switch (c) {
                '.' => '.',
                '#' => '#',
                '^' => caret: {
                    guard_x = i;
                    guard_y = j;
                    break :caret '.';
                },
                else => ' ',
            };
            field[i][j] = s;
        }
        i += 1;
    }

    visited_cords[guard_x][guard_y] = true;

    while (true) {
        var wanted_x: usize = undefined;
        var wanted_y: usize = undefined;
        switch (guard_direction) {
            0 => {
                if (guard_x == 0) {
                    break;
                }
                wanted_x = guard_x - 1;
                wanted_y = guard_y;
            },
            1 => {
                if (guard_y == field_size-1) {
                    break;
                }
                wanted_x = guard_x;
                wanted_y = guard_y + 1;
            },
            2 => {
                if (guard_x == field_size-1) {
                    break;
                }
                wanted_x = guard_x + 1;
                wanted_y = guard_y;
            },
            3 => {
                if (guard_y == 0) {
                    break;
                }
                wanted_x = guard_x;
                wanted_y = guard_y - 1;
            },
        }

        switch (field[wanted_x][wanted_y]) {
            '.' => {
                guard_x = wanted_x;
                guard_y = wanted_y;
                if (!visited_cords[wanted_x][wanted_y]) {
                    visited_pos_amount += 1;
                    visited_cords[wanted_x][wanted_y] = true;
                }
            },
            '#' => {
                guard_direction +%= 1;
            },
            ' ' => {
                break;
            },
            else => {
                std.debug.panic("Unexpected symbol: {c}", .{field[wanted_x][wanted_y]});
            }
        }
    }

    print("Total unique visited positions: {d}\n", .{visited_pos_amount});

    for (visited_cords) |inner| {
        for (inner) |cur| {
            const to_print: u8 = if (cur) 'X' else '.';
            print("{c} ", .{to_print});
        }
        print("\n", .{});
    }

    print("\n", .{});

    for (field) |inner| {
        for (inner) |cur| {
            print("{c} ", .{cur});
        }
        print("\n", .{});
    }
}