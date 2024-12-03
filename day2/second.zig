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
        var nums_arr = std.ArrayList(u32).init(alloc);
        defer nums_arr.deinit();
        var arr_nums_iter = std.mem.splitSequence(u8, line, " ");
        while (arr_nums_iter.next()) |value| {
            try nums_arr.append(try std.fmt.parseInt(u32, value, 10));
        }
        arrays_loop: for (0..nums_arr.items.len) |index| {
            var cur_arr = try nums_arr.clone();
            defer cur_arr.deinit();
            _ = cur_arr.orderedRemove(index);
            // Normal checks, same for first task
            var nums_iter = ArrayListIterator.init(&cur_arr);
            var is_rising: bool = false;
            var last_num = nums_iter.next().?;
            var cur_num = nums_iter.next().?;
            if (cur_num < last_num and (last_num - cur_num) <= 3) {
                is_rising = false;
                last_num = cur_num;
            } else if (cur_num > last_num and (cur_num - last_num) <= 3) {
                is_rising = true;
                last_num = cur_num;
            } else {
                continue :arrays_loop;
            }
            while (nums_iter.next()) |num| {
                cur_num = num;
                if (cur_num < last_num and !is_rising and (last_num - cur_num) <= 3) {
                    last_num = cur_num;
                } else if (cur_num > last_num and is_rising and (cur_num - last_num) <= 3) {
                    last_num = cur_num;
                } else {
                    continue :arrays_loop;
                }
            }
            safe_reports_counter += 1;
            continue :lines_loop;
        }
    }

    print("Total safe reports: {d}", .{safe_reports_counter});
}


/// Custom Iterator for ArrayList
const ArrayListIterator = struct {
    list: *const std.ArrayList(u32),
    index: usize,

    pub fn init(list: *const std.ArrayList(u32)) ArrayListIterator {
        return ArrayListIterator {
            .list = list,
            .index = 0
        };
    }

    pub fn next(self: *ArrayListIterator) ?u32 {
        if (self.index >= self.list.items.len) {
            return null;
        }
        const val = self.list.items[self.index];
        self.index += 1;
        return val;
    }
};