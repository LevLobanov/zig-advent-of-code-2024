const std = @import("std");
const dprint = std.debug.print;
const kb = 1024;

const MAP_HEIGHT = 58;
const MAP_WIDTH = 58;

pub fn main(init: std.process.Init) anyerror!void {
    const gpa = init.gpa;
    const io = init.io;

    const contents = try std.Io.Dir.readFileAlloc(std.Io.Dir.cwd(), io, "input.txt", gpa, std.Io.Limit.unlimited);
    defer gpa.free(contents);
    var file_lines_iter = std.mem.tokenizeSequence(u8, contents, "\n");

    var map: [MAP_HEIGHT][MAP_WIDTH]u8 = undefined;
    var reachable_peaks_map: [MAP_HEIGHT][MAP_WIDTH]isize = @splat(@splat(-1));
    var total_paths: isize = 0;

    var i_line: usize = 0;
    while (file_lines_iter.next()) |line| : (i_line += 1) {
        if (line.len == MAP_HEIGHT) {
            @memcpy(&map[i_line], line);
        }
    }

    for (map, 0..) |line , i| {
        for (line, 0..) |height, j| {
            if (height == '0') {
                calculate_reachable_peaks(gpa, .{i, j}, &map, &reachable_peaks_map);
                total_paths += reachable_peaks_map[i][j];
            }
        }
    }

    dprint("Total trailheads scores sum: {}\n", .{total_paths});
}

pub fn calculate_reachable_peaks(alloc: std.mem.Allocator, start_pos: [2]usize, map: *const [MAP_HEIGHT][MAP_WIDTH]u8, reachable_peaks_map: *[MAP_HEIGHT][MAP_WIDTH]isize) void {
    const row = start_pos[0];
    const col = start_pos[1];
    const cur_height = map[row][col];
    if (reachable_peaks_map[row][col] != -1) { return; }
    var init_reacheable_peaks: isize = 0;
    if (map[row][col] == '9') {
        reachable_peaks_map[row][col] = 1;
        return;
    }

    // UP
    if (row > 0 and map[row-1][col] == cur_height + 1) {
        var cur_reachable_peaks = reachable_peaks_map[row - 1][col];
        if (cur_reachable_peaks == -1) {
            calculate_reachable_peaks(alloc, .{row - 1, col}, map, reachable_peaks_map);
            cur_reachable_peaks = reachable_peaks_map[row - 1][col];
        }
        init_reacheable_peaks += cur_reachable_peaks;
    }

    // DOWN
    if (row < MAP_HEIGHT - 1 and map[row+1][col] == cur_height + 1) {
        var cur_reachable_peaks = reachable_peaks_map[row + 1][col];
        if (cur_reachable_peaks == -1) {
            calculate_reachable_peaks(alloc, .{row + 1, col}, map, reachable_peaks_map);
            cur_reachable_peaks = reachable_peaks_map[row + 1][col];
        }
        init_reacheable_peaks += cur_reachable_peaks;
    }

    // LEFT
    if (col > 0 and map[row][col-1] == cur_height + 1) {
        var cur_reachable_peaks = reachable_peaks_map[row][col - 1];
        if (cur_reachable_peaks == -1) {
            calculate_reachable_peaks(alloc, .{row, col - 1}, map, reachable_peaks_map);
            cur_reachable_peaks = reachable_peaks_map[row][col - 1];
        }
        init_reacheable_peaks += cur_reachable_peaks;
    }

    // RIGHT
    if (col < MAP_WIDTH - 1 and map[row][col+1] == cur_height + 1) {
        var cur_reachable_peaks = reachable_peaks_map[row][col + 1];
        if (cur_reachable_peaks == -1) {
            calculate_reachable_peaks(alloc, .{row, col + 1}, map, reachable_peaks_map);
            cur_reachable_peaks = reachable_peaks_map[row][col + 1];
        }
        init_reacheable_peaks += cur_reachable_peaks;
    }

    reachable_peaks_map[row][col] = init_reacheable_peaks;
}