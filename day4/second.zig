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

    print("Total x-mas occurencies: {d}", .{result});
}


const Direction = enum(u2) {
    up,
    right,
    down,
    left,
};

const Cords = struct {
    x: isize,
    y: isize,

    pub fn from_u2(value: u2) Cords {
        switch (value) {
            0 => return Cords{ .x = -1, .y = -1},
            1 => return Cords{ .x = 1, .y = -1},
            2 => return Cords{ .x = 1, .y = 1},
            3 => return Cords{ .x = -1, .y = 1},
        }
    }
};


fn collect_xmas(drct: Direction, arr: DynamicArray, i: usize, j: usize) bool {
    const a: u2 = @truncate(@intFromEnum(drct));
    const cords = Cords.from_u2(a);
    const cords2 = Cords.from_u2(a +% 1);
    const cords3 = Cords.from_u2(a +% 2);
    const cords4 = Cords.from_u2(a +% 3);
    if (arr.get(@abs(i), @abs(j)).? == 'A' and
        arr.get(@abs(i2usize(i) + cords.x), @abs(i2usize(j) + cords.y)).? == 'M' and
        arr.get(@abs(i2usize(i) + cords2.x), @abs(i2usize(j) + cords2.y)).? == 'S' and
        arr.get(@abs(i2usize(i) + cords3.x), @abs(i2usize(j) + cords3.y)).? == 'S' and
        arr.get(@abs(i2usize(i) + cords4.x), @abs(i2usize(j) + cords4.y)).? == 'M') {
        return true;
    }
    return false;
}


fn count_xmas(arr: DynamicArray) usize {
    var counter: usize = 0;
    for (1..arr.length-1) |i| {
        for (1..arr.height-1) |j| {
            if (collect_xmas(Direction.up, arr, i, j)) { counter += 1; }
            if (collect_xmas(Direction.right, arr, i, j)) { counter += 1; }
            if (collect_xmas(Direction.down, arr, i, j)) { counter += 1; }
            if (collect_xmas(Direction.left, arr, i, j)) { counter += 1; }
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