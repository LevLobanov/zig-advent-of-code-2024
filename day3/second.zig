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
    do: bool = true,

    const Expected = enum {
        m_or_d,
        u,
        l,
        open_brack,
        num1,
        num1_or_comma,
        num2,
        num2_or_close_brack,
        o,
        n_or_open_brack,
        tick,
        t,
        open_brack_aft_t,
        close_brack_aft_do,
        close_brack_after_dont,
    };

    pub fn init(alloc: std.mem.Allocator) Tokenizer {
        return Tokenizer{
            .state = Expected.m_or_d,
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
            Expected.m_or_d => {
                if (letter == 'm') {
                    self.state = Expected.u;
                } else if (letter == 'd') {
                    self.state = Expected.o;
                } else {
                    self.state = Expected.m_or_d;
                }
            },
            Expected.u => {
                if (letter == 'u') {
                    self.state = Expected.l;
                } else {
                    self.state = Expected.m_or_d;
                }
            },
            Expected.l => {
                if (letter == 'l') {
                    self.state = Expected.open_brack;
                } else {
                    self.state = Expected.m_or_d;
                }
            },
            Expected.open_brack => {
                if (letter == '(') {
                    self.state = Expected.num1;
                } else {
                    self.state = Expected.m_or_d;
                }
            },
            Expected.num1 => {
                if (49 <= letter and letter <= 57) {
                    try self.num1.append(letter);
                    self.state = Expected.num1_or_comma;
                } else {
                    self.state = Expected.m_or_d;
                }
            },
            Expected.num1_or_comma => {
                if (48 <= letter and letter <= 57) {
                    try self.num1.append(letter);
                } else if (letter == ',') {
                    self.state = Expected.num2;
                } else {
                    self.num1.clearAndFree();
                    self.state = Expected.m_or_d;
                }
            },
            Expected.num2 => {
                if (49 <= letter and letter <= 57) {
                    try self.num2.append(letter);
                    self.state = Expected.num2_or_close_brack;
                } else {
                    self.num1.clearAndFree();
                    self.state = Expected.m_or_d;
                }
            },
            Expected.num2_or_close_brack => {
                if (48 <= letter and letter <= 57) {
                    try self.num2.append(letter);
                } else if (letter == ')') {
                    self.state = Expected.m_or_d;
                    return true;
                } else {
                    self.num1.clearAndFree();
                    self.num2.clearAndFree();
                    self.state = Expected.m_or_d;
                }
            },
            Expected.o => {
                if (letter == 'o') {
                    self.state = Expected.n_or_open_brack;
                } else {
                    self.state = Expected.m_or_d;
                }
            },
            Expected.n_or_open_brack => {
                if (letter == 'n') {
                    self.state = Expected.tick;
                } else if (letter == '(') {
                    self.state = Expected.close_brack_aft_do;
                } else {
                    self.state = Expected.m_or_d;
                }
            },
            Expected.tick => {
                if (letter == '\'') {
                    self.state = Expected.t;
                } else {
                    self.state = Expected.m_or_d;
                }
            },
            Expected.t => {
                if (letter == 't') {
                    self.state = Expected.open_brack_aft_t;
                } else {
                    self.state = Expected.m_or_d;
                }
            },
            Expected.open_brack_aft_t => {
                if (letter == '(') {
                    self.state = Expected.close_brack_after_dont;
                } else {
                    self.state = Expected.m_or_d;
                }
            },
            Expected.close_brack_aft_do => {
                if (letter == ')') {
                    self.do = true;
                }
                self.state = Expected.m_or_d;
            },
            Expected.close_brack_after_dont => {
                if (letter == ')') {
                    self.do = false;
                }
                self.state = Expected.m_or_d;
            },
        }
        return false;
    }

    pub fn get_parsed_value(self: *Tokenizer) !u32 {
        const num1_int = try std.fmt.parseInt(u32, self.num1.items, 10);
        const num2_int = try std.fmt.parseInt(u32, self.num2.items, 10);
        self.num1.clearAndFree();
        self.num2.clearAndFree();
        if (self.do) {
            return num1_int * num2_int;
        }
        return 0;
    }
};