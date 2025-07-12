const std = @import("std");
const print = std.debug.print;
const kb = 1024;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const memory_layout = try std.fs.cwd().readFileAlloc(alloc, "input.txt", 21 * kb);
    defer alloc.free(memory_layout);

    // If I follow instruciton - i'll need an array of size avg 4 * 20_000 = 80kb.
    // Which is totally fine, but I can do better:
    // 1) Make an index from end.
    // 2) When I find empty space - get contents from file from end by index.
    // 3) Continue, until start index and end index meet eachother.
    //
    // So, with this technique, I can calculate checksum on way.
    var checksum: u128 = 0;
    var next_is_file = true;
    var cur_contents_id: u128 = 0;
    var cur_file_id: usize = 0;
    const memory_layout_len = memory_layout.len - (1 - (memory_layout.len % 2));
    var cur_endfile_id = (memory_layout_len - 1) / 2;
    var cur_endfile_size_left = memory_layout[memory_layout_len - 1] - '0';
    checksum_calc_blk: for (memory_layout) |block_size| {
        const block_size_num = block_size - '0';
        if (next_is_file) {
            for (0..block_size_num) |_| {
                if (cur_file_id < cur_endfile_id or cur_endfile_size_left > 0) {
                    if (cur_file_id >= cur_endfile_id) {
                        cur_endfile_size_left -= 1;
                    }
                    checksum +|= cur_contents_id *| @as(u128, cur_file_id);
                    cur_contents_id += 1;
                } else {
                    break :checksum_calc_blk;
                }
            }
            cur_file_id += 1;
            next_is_file = false;
        } else {
            for (0..block_size_num) |_| {
                if (cur_file_id < cur_endfile_id or cur_endfile_size_left > 0) {
                    checksum +|= cur_contents_id *| @as(u128, 
                        get_next_file_content_from_end(
                            &cur_endfile_id, 
                            &cur_endfile_size_left, 
                            &memory_layout,
                        )
                    );
                    cur_contents_id += 1;
                } else {
                    break :checksum_calc_blk;
                }
            }
            next_is_file = true;
        }
    }

    print("\nTotal checksum: {d}", .{checksum});
}

pub fn get_next_file_content_from_end(
        cur_endfile_id: *usize, 
        cur_endfile_size_left: *u8, 
        memory_layout: *const []u8,
    ) usize {
    if (cur_endfile_size_left.* == 0) {
        cur_endfile_id.* -|= 1;
        cur_endfile_size_left.* = memory_layout.*[cur_endfile_id.* * 2] - '0' - 1;
    } else {
        cur_endfile_size_left.* -= 1;
    }
    return cur_endfile_id.*;
}
