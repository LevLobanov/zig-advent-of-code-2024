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

    const darr = try DynamicArray.init(file_buffer, alloc);
    defer darr.deinit();
    const result = count_xmas(darr);

    print("Total xmas occurencies: {d}", .{result});
}


const Direction = enum(u3) {
    up,
    up_right,
    right,
    down_right,
    down,
    down_left,
    left,
    up_left,
};

const Cords = struct {
    x: isize,
    y: isize,

    pub fn from_u3(value: u3) Cords {
        switch (value) {
            0 => return Cords{ .y = -1, .x = 0},
            1 => return Cords{ .y = -1, .x = 1},
            2 => return Cords{ .y = 0, .x = 1},
            3 => return Cords{ .y = 1, .x = 1},
            4 => return Cords{ .y = 1, .x = 0},
            5 => return Cords{ .y = 1, .x = -1},
            6 => return Cords{ .y = 0, .x = -1},
            7 => return Cords{ .y = -1, .x = -1},
        }
    }
};


fn collect_xmas(drct: Direction, arr: DynamicArray, i: usize, j: usize) bool {

    const a: u3 = @truncate(@intFromEnum(drct));
    const cords = Cords.from_u3(a);
    if (arr.get(@abs(i), @abs(j)).? == 'X' and
        arr.get(@abs(i2usize(i) + cords.x * 1), @abs(i2usize(j) + cords.y * 1)).? == 'M' and
        arr.get(@abs(i2usize(i) + cords.x * 2), @abs(i2usize(j) + cords.y * 2)).? == 'A' and
        arr.get(@abs(i2usize(i) + cords.x * 3), @abs(i2usize(j) + cords.y * 3)).? == 'S') {
        return true;
    }
    return false;
}


fn count_xmas(arr: DynamicArray) usize {
    var counter: usize = 0;
    for (0..arr.length) |i| {
        for (0..arr.height) |j| {
            if (i >= 3) {
                if (collect_xmas(Direction.left, arr, i, j)) { counter += 1; }

                if (j >= 3) {
                    if (collect_xmas(Direction.up_left, arr, i, j)) { counter += 1; }
                }
            }
            if (j >= 3) {
                if (collect_xmas(Direction.up, arr, i, j)) { counter += 1; }

                if (i < arr.length - 3) {
                    if (collect_xmas(Direction.up_right, arr, i, j)) { counter += 1; }
                }
            }
            if (i < arr.length - 3) {
                if (collect_xmas(Direction.right, arr, i, j)) { counter += 1; }

                if (j < arr.length - 3) {
                    if (collect_xmas(Direction.down_right, arr, i, j)) { counter += 1; }
                }
            }
            if (j < arr.length - 3) {
                if (collect_xmas(Direction.down, arr, i, j)) { counter += 1; }

                if (i >= 3) {
                    if (collect_xmas(Direction.down_left, arr, i, j)) { counter += 1; }
                }
            }
        }
    }
    return counter;
}


const DynamicArray = struct {
    contents: []u8,
    length: usize,
    height: usize,
    alloc: std.mem.Allocator,

    pub fn init(data: []u8, alloc: std.mem.Allocator) !DynamicArray {
        var lines_iter = std.mem.split(u8, data, "\n");
        const length = lines_iter.first().len;
        lines_iter.reset();
        const height = lines_iter.rest().len / length;
        var contents = try alloc.alloc(u8, length * height);
        var i: usize = 0;
        while (lines_iter.next()) |line| {
            for (0..length) |j| {
                contents[i + j * length] = line[j];
            }
            i += 1;
        }
        return DynamicArray{
            .contents = contents,
            .length = length,
            .height = height,
            .alloc = alloc,
        };
    }

    pub fn deinit(self: *const DynamicArray) void {
        self.alloc.free(self.contents);
    }

    pub fn get(self:  *const DynamicArray, i: usize, j: usize) ?u8 {
        if (i >= 0 and i < self.length and j >= 0 and j < self.height) {
            return self.contents[i + j * self.length];
        }
        return null;
    }
};

fn i2usize(value: usize) isize {
    const result: isize = @intCast(value);
    return result;
}