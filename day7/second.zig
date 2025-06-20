const std = @import("std");
const print = std.debug.print;
const panic = std.debug.panic;
const kb = 1024;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const file = try std.fs.cwd().openFile(
        "input.txt", 
        .{ .mode = .read_only });
    defer file.close();

    const file_buffer = try file.readToEndAlloc(alloc, 64*kb);
    defer alloc.free(file_buffer);

    var lines_iter = std.mem.splitAny(u8, file_buffer, "\n");

    var total_calibration_result: u128 = 0;
    var compound_numbers: [100]u128 = .{0} ** 100;
    var numbers_amount: usize = 0;

    while (lines_iter.next()) |line| {
        var line_parts_iter = std.mem.splitSequence(u8, line, ": ");
        
        const test_value = try std.fmt.parseInt(u128, line_parts_iter.first(), 10);

        var compound_numbers_iter = std.mem.splitAny(u8,line_parts_iter.next().? , " ");
        
        while (compound_numbers_iter.next()) |cn| {
            compound_numbers[numbers_amount] = try std.fmt.parseInt(u128, cn, 10);
            numbers_amount += 1;
        }

        if (try check_operators_recursive(compound_numbers[0], 1, &compound_numbers, numbers_amount, test_value)) {
            total_calibration_result += test_value;
        }

        numbers_amount = 0;
    }

    print("Total calibration result: {d}", .{total_calibration_result});
}

fn check_operators_recursive(current_calibration: u128, deep_level: usize, compound_numbers: *[100]u128, numbers_amount: usize, wanted_calibration: u128) anyerror!bool {
    if (deep_level <= numbers_amount - 1) {
        const plus_val = current_calibration +| compound_numbers[deep_level];
        const mult_var = current_calibration *| compound_numbers[deep_level];
        var concatenated_buffer: [80]u8 = undefined;
        const concat_val = try std.fmt.parseInt(u128, try std.fmt.bufPrint(&concatenated_buffer, "{d}{d}", .{current_calibration, compound_numbers[deep_level]}), 10);
        if (plus_val == wanted_calibration) {
            return true;
        }
        if (mult_var == wanted_calibration) {
            return true;
        }
        if (concat_val == wanted_calibration) {
            return true;
        }
        if (deep_level < numbers_amount - 1) {
            return plus_val < wanted_calibration and
             try check_operators_recursive(plus_val, deep_level+1, compound_numbers, numbers_amount, wanted_calibration) or
             mult_var < wanted_calibration and 
             try check_operators_recursive(mult_var, deep_level + 1, compound_numbers, numbers_amount, wanted_calibration) or
             concat_val < wanted_calibration and
             try check_operators_recursive(concat_val, deep_level+1, compound_numbers, numbers_amount, wanted_calibration);
        }
    }
    return false;
}