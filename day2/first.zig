const std = @import("std");
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

    const buffer_size = 64*kb;
    const file_buffer = try file.readToEndAlloc(alloc, buffer_size);
    defer alloc.free(file_buffer);

    var lines_iter = std.mem.split(u8, file_buffer, "\n");
    var safe_reports_counter: u32 = 0;

    lines_loop: while (lines_iter.next()) |line| {
        var nums_iter = std.mem.split(u8, line, " ");
        var is_rising: bool = false;
        var last_num = try std.fmt.parseInt(u32, nums_iter.next().?, 10);
        var cur_num = try std.fmt.parseInt(u32, nums_iter.next().?, 10);
        if (cur_num < last_num and (last_num - cur_num) <= 3) {
            is_rising = false;
            last_num = cur_num;
        } else if (cur_num > last_num and (cur_num - last_num) <= 3) {
            is_rising = true;
            last_num = cur_num;
        } else {
            continue :lines_loop;
        }
        while (nums_iter.next()) |num| {
            cur_num = try std.fmt.parseInt(u32, num, 10);
            if (cur_num < last_num and !is_rising and (last_num - cur_num) <= 3) {
                last_num = cur_num;
            } else if (cur_num > last_num and is_rising and (cur_num - last_num) <= 3) {
                last_num = cur_num;
            } else {
                continue :lines_loop;
            }
        }
        safe_reports_counter += 1;
    }

    print("Total safe reports: {d}", .{safe_reports_counter});
}