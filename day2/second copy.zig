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
        var removed_level: bool = false;
        var nums_iter = std.mem.split(u8, line, " ");
        var is_rising: bool = false;
        var prev_num: u32 = 0;
        var last_num = try std.fmt.parseInt(u32, nums_iter.next().?, 10);
        var cur_num = try std.fmt.parseInt(u32, nums_iter.next().?, 10);
        // Check if all ok on start
        const res = check_first(last_num, cur_num);
        if (res.cbf) {
            prev_num = last_num; // 1st num in list
            last_num = cur_num; // 2nd num in list
            is_rising = res.sr;
        } else {
            print("Removed in first two!\n", .{});
            removed_level = true;
            prev_num = last_num; // 1st num in list
            last_num = cur_num; // 2nd num in list
            cur_num = try std.fmt.parseInt(u32, nums_iter.next().?, 10); // 3rd num in list
            // Check if can remove first number in list
            const res2 = check_first(last_num, cur_num);
            if (res2.cbf) {
                prev_num = last_num; // new 1st num in list (real 2nd)
                last_num = cur_num; // new 2nd num in list (real 3rd)
                is_rising = res2.sr;
            } else {
                // Check if can remove second numer in list
                const res3 = check_first(prev_num, cur_num);
                if (res3.cbf) {
                    last_num = cur_num; // new 2nd num in list (real 3rd)
                    is_rising = res3.sr;
                } else {
                    continue :lines_loop;
                }
            }
        }
        while (nums_iter.next()) |num| {
            // print("Print: cur_num: '{s}', of len: {d}\n", .{num, num.len});
            cur_num = try std.fmt.parseInt(u32, num, 10);
            if (check_next(is_rising, last_num, cur_num)) {
                prev_num = last_num;
                last_num = cur_num;
            } else if (!removed_level) {
                removed_level = true;
                // Check if can remove last_num
                if (check_next(is_rising, prev_num, cur_num)) {
                    last_num = cur_num;
                } else {
                    // Check if can remove cur_num
                    const next_iter_num = nums_iter.next();
                    if (next_iter_num) |value| {
                        const fut_num = try std.fmt.parseInt(u32, value, 10);
                        if (check_next(is_rising, last_num, fut_num)) {
                            prev_num = last_num;
                            last_num = fut_num;
                        } else {
                            continue :lines_loop;
                        }
                    } else {
                        // Means this num is last, and, surely, I can remove it
                        print("Safe line: '{s}'. Removed last!\n", .{line});
                        safe_reports_counter += 1;
                        continue :lines_loop;
                    }
                }
            }
        }
        if (removed_level) {
            print("Safe line: '{s}'. Removed?: {}\n", .{line, removed_level});
        }
        safe_reports_counter += 1;
    }

    print("Total safe reports: {d}", .{safe_reports_counter});
}


fn check_next(is_rising: bool, last_num: u32, cur_num: u32) bool {
    if (cur_num < last_num and !is_rising and (last_num - cur_num) <= 3) {
        return true;
    } else if (cur_num > last_num and is_rising and (cur_num - last_num) <= 3) {
        return true;
    } else {
        return false;
    }
}

const cf = struct{
    cbf: bool, // Can be first
    sr: bool, // Should rise
};

/// Returns answers to: .{can these numbers be first ones, are reports should rise}
fn check_first(last_num: u32, cur_num: u32) cf {
    if (cur_num < last_num and (last_num - cur_num) <= 3) {
        return cf{ .cbf = true, .sr = false};
    } else if (cur_num > last_num and (cur_num - last_num) <= 3) {
        return cf{ .cbf = true, .sr = true};
    } else {
        return cf{.cbf = false, .sr = false};
    }
}