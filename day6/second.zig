const std = @import("std");
const print = std.debug.print;
const kb = 1024;

const print_field_debug = false;
const print_steps_debug = false;

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

    var lines_iter = std.mem.splitAny(u8, file_buffer, "\n");

    const field_size: usize = 130;

    var guard_x: usize = undefined;
    var guard_y: usize = undefined;
    var guard_direction: u2 = 0;
    var visited_pos_amount: usize = 1;

    var visited_cords: [field_size][field_size]bool = .{.{false} ** field_size} ** field_size;
    var field: [field_size][field_size]u8 = .{ .{' '} ** field_size} ** field_size;
    var field_copy: [field_size][field_size]u8 = undefined;
    var visited_counts: [field_size][field_size][4]u3 = .{ .{.{0} ** 4} ** field_size} ** field_size;

    var l_index: usize = 0;

    while (lines_iter.next()) |line| {
        for (line[0..line.len], 0..) |c, j| {
            const s: u8 = switch (c) {
                '.' => '.',
                '#' => '#',
                '^' => caret: {
                    guard_x = l_index;
                    guard_y = j;
                    break :caret '.';
                },
                else => { std.debug.panic("Unexpected symbol: \"{c}\" in position: ({d}, {d})", .{c, line, j}); },
            };
            field[l_index][j] = s;
        }
        l_index += 1;
    }

    visited_cords[guard_x][guard_y] = true;

    const guard_start_x = guard_x;
    const guard_start_y = guard_y;

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

    visited_cords[guard_start_x][guard_start_y] = false;

    print("Total unique visited positions: {d}\n", .{visited_pos_amount});

    var counter: usize = 0;
    var cached_counter: usize = 0;
    var checked_variants: usize = 0;

    for (visited_cords, 0..) |inner, i| {
        for (inner, 0..) |cur, j| {
            if (cur) {
                if (print_steps_debug) {
                    checked_variants += 1;
                    print("Checking: {d} of {d}.\n", .{checked_variants, visited_pos_amount});
                }
                field_copy = field;
                field_copy[i][j] = '@';

                guard_x = guard_start_x;
                guard_y = guard_start_y;
                guard_direction = 0;
                visited_counts = .{ .{.{0} ** 4} ** field_size} ** field_size;
                // visited_counts[guard_start_x][guard_start_y][0] = 1;

                variant: while (true) {
                    var wanted_x: usize = undefined;
                    var wanted_y: usize = undefined;

                    switch (guard_direction) {
                        0 => {
                            if (guard_x == 0) {
                                break :variant;
                            }
                            wanted_x = guard_x - 1;
                            wanted_y = guard_y;
                        },
                        1 => {
                            if (guard_y == field_size-1) {
                                break :variant;
                            }
                            wanted_x = guard_x;
                            wanted_y = guard_y + 1;
                        },
                        2 => {
                            if (guard_x == field_size-1) {
                                break :variant;
                            }
                            wanted_x = guard_x + 1;
                            wanted_y = guard_y;
                        },
                        3 => {
                            if (guard_y == 0) {
                                break :variant;
                            }
                            wanted_x = guard_x;
                            wanted_y = guard_y - 1;
                        },
                    }

                    switch (field_copy[wanted_x][wanted_y]) {
                        '.' => {
                            guard_x = wanted_x;
                            guard_y = wanted_y;
                            visited_counts[wanted_x][wanted_y][guard_direction] += 1;
                            if (visited_counts[wanted_x][wanted_y][guard_direction] == 2) {
                                counter += 1;
                                break :variant;
                            }
                        },
                        '#', '@' => {
                            guard_direction +%= 1;
                        },
                        ' ' => {
                            std.debug.panic("Unexpected symbol: \"{c}\" in position: ({d}, {d})", .{field[wanted_x][wanted_y], wanted_x, wanted_y});
                        },
                        else => {
                            std.debug.panic("Unexpected symbol: {c}", .{field[wanted_x][wanted_y]});
                        }
                    }
                }

                if (print_steps_debug) {
                    if (cached_counter != counter) {
                        cached_counter = counter;
                        print("Result: Yes\n", .{});
                    } else {
                        print("Result: No\n", .{});
                    }
                }

                if (print_field_debug) {
                    for (field_copy) |inner_row| {
                        for (inner_row) |cur_sym| {
                            print("{c} ", .{cur_sym});
                        }
                        print("\n", .{});
                    }
                }
            }
        }
    }

    print("Total variants of placing obstacle and looping guard path: {d}", .{counter});
}