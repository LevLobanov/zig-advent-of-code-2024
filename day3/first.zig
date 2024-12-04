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

    var tok = Tokenizer.init(alloc);
    defer tok.deinit();
    var total_sum: u64 = 0;

    for (file_buffer) |letter| {
        if (try tok.expect_next(letter)) {
            total_sum += try tok.get_parsed_value();
        }
    }

    print("Total sum: {d}", .{total_sum});
}


const Tokenizer = struct {
    state: Expected,
    num1: std.ArrayList(u8),
    num2: std.ArrayList(u8),

    const Expected = enum {
        m,
        u,
        l,
        open_brack,
        num1,
        num1_or_comma,
        num2,
        num2_or_close_brack,
    };

    pub fn init(alloc: std.mem.Allocator) Tokenizer {
        return Tokenizer{
            .state = Expected.m,
            .num1 = std.ArrayList(u8).init(alloc),
            .num2 = std.ArrayList(u8).init(alloc),
        };
    }

    pub fn deinit(self: *Tokenizer) void {
        self.num1.deinit();
        self.num2.deinit();
    }

    pub fn expect_next(self: *Tokenizer, letter: u8) !bool {
        switch (self.state) {
            Expected.m => {
                if (letter == 'm') {
                    self.state = Expected.u;
                    return false;
                } else {
                    self.state = Expected.m;
                }
            },
            Expected.u => {
                if (letter == 'u') {
                    self.state = Expected.l;
                } else {
                    self.state = Expected.m;
                }
            },
            Expected.l => {
                if (letter == 'l') {
                    self.state = Expected.open_brack;
                } else {
                    self.state = Expected.m;
                }
            },
            Expected.open_brack => {
                if (letter == '(') {
                    self.state = Expected.num1;
                } else {
                    self.state = Expected.m;
                }
            },
            Expected.num1 => {
                if (49 <= letter and letter <= 57) {
                    try self.num1.append(letter);
                    self.state = Expected.num1_or_comma;
                } else {
                    self.state = Expected.m;
                }
            },
            Expected.num1_or_comma => {
                if (48 <= letter and letter <= 57) {
                    try self.num1.append(letter);
                } else if (letter == ',') {
                    self.state = Expected.num2;
                } else {
                    self.num1.clearAndFree();
                    self.state = Expected.m;
                }
            },
            Expected.num2 => {
                if (49 <= letter and letter <= 57) {
                    try self.num2.append(letter);
                    self.state = Expected.num2_or_close_brack;
                } else {
                    self.num1.clearAndFree();
                    self.state = Expected.m;
                }
            },
            Expected.num2_or_close_brack => {
                if (48 <= letter and letter <= 57) {
                    try self.num2.append(letter);
                } else if (letter == ')') {
                    self.state = Expected.m;
                    return true;
                } else {
                    self.num1.clearAndFree();
                    self.num2.clearAndFree();
                    self.state = Expected.m;
                }
            },
        }
        return false;
    }

    pub fn get_parsed_value(self: *Tokenizer) !u32 {
        const num1_int = try std.fmt.parseInt(u32, self.num1.items, 10);
        const num2_int = try std.fmt.parseInt(u32, self.num2.items, 10);
        self.num1.clearAndFree();
        self.num2.clearAndFree();
        return num1_int * num2_int;
    }
};