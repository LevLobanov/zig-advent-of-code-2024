const std = @import("std");
const print = std.debug.print;
const kb = 1024;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{.safety = true}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    
    const memory_layout = try std.fs.cwd().readFileAlloc(alloc, "input.txt", 21 * kb);
    defer alloc.free(memory_layout);

    // Now I'll follow the instructions
    var next_is_file = true;
    var cur_file_id: usize = 0;
    var empty_spaces: [11 * kb][2]usize = undefined;
    var empty_spaces_arr_size: usize = 0;
    var files_spaces: [11 * kb][3]usize = undefined;
    var memory_index: usize = 0;
    for (memory_layout) |block_size| {
        const block_size_num = block_size - '0';
        if (next_is_file) {
            files_spaces[cur_file_id] = .{@as(usize, block_size_num), memory_index, cur_file_id};
            cur_file_id += 1;
        } else {
            empty_spaces[empty_spaces_arr_size] = .{@as(usize, block_size_num), memory_index};
            empty_spaces_arr_size += 1;
        }
        memory_index += block_size_num;
        next_is_file = !next_is_file;
    }

    var checksum: u128 = 0;
    file_pack_blk: for (0..cur_file_id) |rev_i| {
        const file_space = &files_spaces[cur_file_id - rev_i - 1];
        for (0..empty_spaces_arr_size) |j| {
            const empty_space = &empty_spaces[j];
            if (file_space[1] < empty_space[1]) {
                break;
            }
            if (file_space[0] <= empty_space[0]) {
                empty_space[0] -= file_space[0];
                file_space[1] = empty_space[1];
                checksum += ((file_space[0] * (empty_space[1] * 2 + file_space[0] - 1)) / 2) * file_space[2];
                empty_space[1] += file_space[0];
                continue :file_pack_blk;
            }
        }
        checksum += ((file_space[0] * (file_space[1] * 2 + file_space[0] - 1)) / 2) * file_space[2];
    }

    print("Total checksum after packing files: {d}", .{checksum});
}