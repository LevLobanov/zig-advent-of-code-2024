const std = @import("std");
const builtin = @import("builtin");
const print = std.debug.print;
const kb = 1024;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var path_buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const path = try std.fs.realpath("input.txt", &path_buffer);

    const file = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });
    defer file.close();

    const buffer_size = 16*kb;
    const file_buffer = try file.readToEndAlloc(alloc, buffer_size);
    defer alloc.free(file_buffer);

    var lines_iter = std.mem.split(u8, file_buffer, "\n");

    var left_arr = std.ArrayList(u32).init(alloc);
    defer left_arr.deinit();

    var right_arr = std.ArrayList(u32).init(alloc);
    defer right_arr.deinit();

    while (lines_iter.next()) |line| {
        var nums_iter = std.mem.split(u8, line, "   ");
        const left_num = try std.fmt.parseInt(u32, nums_iter.next().?, 10);
        const right_num = try std.fmt.parseInt(u32, nums_iter.next().?, 10);

        try left_arr.append(left_num);
        try right_arr.append(right_num);
    }

    std.mem.sort(u32, left_arr.items, {}, std.sort.asc(u32));
    std.mem.sort(u32, right_arr.items, {}, std.sort.asc(u32));

    var counter: u128 = 0;
    for (left_arr.items) |left_num| {
        for (right_arr.items) |right_num| {
            if (left_num == right_num) {
                counter += @as(u128, left_num);
            }
        }
    }

    print("Total lists similarity score: {d}", .{counter});
}


fn printArrayList(arr: std.ArrayList(u32)) anyerror!void {
    print("[", .{});
    for (arr.items) |item| {
        print("{d}, ", .{item});
    }
    print("]\n", .{});
}


fn abs(value: i64) i64 {
    return if (value < 0) -value else value;
}