const std = @import("std");
const print = std.debug.print;
const kb = 1024;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();


    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{ .mode= .read_only },
    );
    defer file.close();

    const file_buffer = try file.readToEndAlloc(alloc, 64*kb);
    defer alloc.free(file_buffer);

    var counter: u32 = 0;

    var instr_iter = std.mem.split(u8, file_buffer, "\n\n");

    var instr_arr = std.ArrayList(Instruction).init(alloc);
    defer instr_arr.deinit();

    const instr_set = instr_iter.first();
    var instr_set_iter = std.mem.split(u8, instr_set, "\n");
    while (instr_set_iter.next()) |instr| {
        var one_instr_iter = std.mem.split(u8, instr, "|");
        try instr_arr.append(
            Instruction.init(
                try std.fmt.parseInt(u8, one_instr_iter.first(), 10),
                try std.fmt.parseInt(u8, one_instr_iter.next().?, 10)
            )
        );
    }

    const prints = instr_iter.next().?;
    var prints_iter = std.mem.split(u8, prints, "\n");
    var pages_arr = std.ArrayList(u8).init(alloc);
    defer pages_arr.deinit();
    while (prints_iter.next()) |print_update| {
        var ok = true;
        var pages_iter = std.mem.split(u8, print_update, ",");
        while (pages_iter.next()) |page| {
            try pages_arr.append(std.fmt.parseInt(u8, page, 10) catch {
                print("Incorrect value: \"{s}\"\n", .{page});
                return;
            });
        }

        for (0..pages_arr.items.len) |i| {
            for (i..pages_arr.items.len) |j| {
                for (instr_arr.items) |cur_instr| {
                    if (!cur_instr.check_if_ok(pages_arr.items[i], pages_arr.items[j])) {
                        ok = false;
                    }
                }
            }
        }

        if (ok) {
            counter += pages_arr.items[pages_arr.items.len / 2];
        }

        pages_arr.clearAndFree();
    }

    print("Total print updates correct middle elements sum: {d}", .{counter});
}

const Instruction = struct {
    left: u8,
    right: u8,

    pub fn init(left: u8, right: u8) Instruction {
        return Instruction{
            .left = left,
            .right = right,
        };
    }

    pub fn check_if_ok(self: *const Instruction, left: u8, right: u8) bool {
        if (right == self.left and left == self.right) {
            return false;
        }
        return true;
    }
};