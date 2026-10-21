const std = @import("std");
const dprint = std.debug.print;
const kb = 1024;

const FIELD_HEIGHT = 140;
const FIELD_WIDTH = 140;

const IS_NOT_COPY = std.math.maxInt(usize);

pub fn main(init: std.process.Init) anyerror!void {
    const io = init.io;
    const gpa = init.gpa;

    const contents = try std.Io.Dir.readFileAlloc(std.Io.Dir.cwd(), io, "input.txt", gpa, std.Io.Limit.unlimited);
    defer gpa.free(contents);
    var field_lines_iter = std.mem.splitScalar(u8, contents, '\n');
    var total_cost: usize = 0;
    var regions_info = std.ArrayList(RegionInfo).empty;
    defer regions_info.deinit(gpa);
    var plants_regions_ids: [FIELD_HEIGHT][FIELD_WIDTH]usize = undefined;
    var last_field_line: [FIELD_WIDTH]u8 = @splat('0');
    var last_plant: u8 = '0';

    var i: usize = 0;
    while (field_lines_iter.next()) |field_line| : (i += 1) {
        for (field_line, 0..) |plant, j| {
            const upper_plant = last_field_line[j];
            const left_plant = last_plant;

            const cross_plant_same = res: {
                if (i != 0 and j != 0 and plant == last_field_line[j-1]) {
                    break :res true;
                }
                break :res false;
            };

            const plant_and_neighbours = res: {
                var pan: [2][2]u8 = @splat(@splat('0'));
                pan[1][1] = plant;
                pan[0][1] = upper_plant;
                pan[1][0] = left_plant;
                if (i > 0 and j > 0) { pan[0][0] = last_field_line[j-1]; }
                break :res pan;
            };

            if (plant == upper_plant) {
                if (plant == left_plant) {
                    attach_to_region(
                        .{ i, j },
                        &regions_info,
                        &plants_regions_ids,
                        AttachmentType.combine,
                        cross_plant_same,
                        plant_and_neighbours,
                    );
                } else {
                    attach_to_region(
                        .{ i, j },
                        &regions_info,
                        &plants_regions_ids,
                        AttachmentType.upper,
                        cross_plant_same,
                        plant_and_neighbours,
                    );
                }
            } else if (plant == left_plant) {
                attach_to_region(
                    .{ i, j },
                    &regions_info,
                    &plants_regions_ids,
                    AttachmentType.left,
                    cross_plant_same,
                    plant_and_neighbours,
                );
            } else {
                const new_region: RegionInfo = .{
                    .perimeter = 2,
                    .area = 1,
                    .copy_of = IS_NOT_COPY,
                };
                const plant_new_region_id = regions_info.items.len;
                try regions_info.append(gpa, new_region);
                plants_regions_ids[i][j] = plant_new_region_id;
                add_perimeter_to_neighbours(
                    .{i, j},
                    &regions_info,
                    &plants_regions_ids,
                    plant_and_neighbours,
                    plant_new_region_id,
                );
            }
            
            if (j == FIELD_WIDTH - 1) {
                last_plant = '0';
            } else {
                last_plant = plant;
            }
        }
        @memcpy(&last_field_line, field_line);
    }

    for (regions_info.items) |region| {
        if (region.copy_of == IS_NOT_COPY) {
            total_cost += region.perimeter * region.area;
        }
    }

    dprint("Total cost: {}", .{total_cost});
}

const RegionInfo = struct {
    perimeter: usize,
    area: usize,
    copy_of: usize,
};

const AttachmentType = enum(u2) { upper, left, combine };

pub fn attach_to_region(
    plant_cords: [2]usize,
    regions_info: *std.ArrayList(RegionInfo),
    plants_regions_ids: *[FIELD_HEIGHT][FIELD_WIDTH]usize,
    attachment_type: AttachmentType,
    cross_plant_same: bool,
    plant_and_neighbours: [2][2]u8,
) void {
    const left_plant_region_id = res: {
        if (plant_cords[1] != 0) {
            break :res plants_regions_ids[plant_cords[0]][plant_cords[1]-1];
        } else {
            break :res undefined;
        }
    };
    const upper_plant_region_id = res: {
        if (plant_cords[0] != 0) {
            break :res plants_regions_ids[plant_cords[0] - 1][plant_cords[1]];
        } else {
            break :res undefined;
        }
    };
    var plant_new_region_id: usize = undefined;
    switch (attachment_type) {
        AttachmentType.left => {
            const next_not_copy_region_id = find_next_not_copy(left_plant_region_id, regions_info).region_id;
            regions_info.items[next_not_copy_region_id].area += 1;
            if (cross_plant_same) {
                regions_info.items[next_not_copy_region_id].perimeter += 1;
            }
            plant_new_region_id = next_not_copy_region_id;
        },
        AttachmentType.upper => {
            const next_not_copy_region_id = find_next_not_copy(upper_plant_region_id, regions_info).region_id;
            regions_info.items[next_not_copy_region_id].area += 1;
            if (cross_plant_same) {
                regions_info.items[next_not_copy_region_id].perimeter += 1;
            }
            plant_new_region_id = next_not_copy_region_id;
        },
        AttachmentType.combine => {
            const next_not_copy_upper = find_next_not_copy(upper_plant_region_id, regions_info);
            const next_not_copy_left = find_next_not_copy(left_plant_region_id, regions_info);

            if (next_not_copy_upper.region_id != next_not_copy_left.region_id) {
                regions_info.items[next_not_copy_upper.region_id].area += 1 + next_not_copy_left.region_info.area;
                regions_info.items[next_not_copy_upper.region_id].perimeter += next_not_copy_left.region_info.perimeter;

                regions_info.items[next_not_copy_left.region_id].copy_of = next_not_copy_upper.region_id;
            } else {
                regions_info.items[next_not_copy_upper.region_id].area += 1;
            }
            plant_new_region_id = next_not_copy_upper.region_id;
        },
    }
    add_perimeter_to_neighbours(
        plant_cords,
        regions_info,
        plants_regions_ids,
        plant_and_neighbours,
        plant_new_region_id,
    );
    plants_regions_ids[plant_cords[0]][plant_cords[1]] = plant_new_region_id;
}

pub fn find_next_not_copy(region_id: usize, regions_info: *std.ArrayList(RegionInfo)) struct {region_info: RegionInfo, region_id: usize} {
    var cur_region = regions_info.items[region_id];
    var cur_region_id = region_id;
    while (cur_region.copy_of != IS_NOT_COPY) {
        cur_region_id = cur_region.copy_of;
        cur_region = regions_info.items[cur_region.copy_of];
    }
    return .{ .region_info = cur_region, .region_id = cur_region_id};
}

pub fn add_perimeter_to_neighbours(
    plant_cords: [2]usize,
    regions_info: *std.ArrayList(RegionInfo),
    plants_regions_ids: *[FIELD_HEIGHT][FIELD_WIDTH]usize,
    plant_and_neighbours: [2][2]u8,
    plant_new_region_id: usize,
) void {
    const plant = plant_and_neighbours[1][1];
    const left_plant = plant_and_neighbours[1][0];
    const upper_plant = plant_and_neighbours[0][1];
    const cross_plant = plant_and_neighbours[0][0];
    if (upper_plant != cross_plant and upper_plant != plant) {
        // +1 for upper plant
        var upper_plant_region_id = plants_regions_ids[plant_cords[0]-1][plant_cords[1]];
        upper_plant_region_id = find_next_not_copy(upper_plant_region_id, regions_info).region_id;
        regions_info.items[upper_plant_region_id].perimeter += 1;
    }
    if (left_plant != cross_plant and left_plant != plant) {
        // +1 for left plant
        var left_plant_region_id = plants_regions_ids[plant_cords[0]][plant_cords[1]-1];
        left_plant_region_id = find_next_not_copy(left_plant_region_id, regions_info).region_id;
        regions_info.items[left_plant_region_id].perimeter += 1;
    }
    if (upper_plant == cross_plant and left_plant == cross_plant and upper_plant != plant and left_plant != plant and cross_plant != '0') {
        // +2 for cross plant
        var cross_plant_region_id = plants_regions_ids[plant_cords[0]-1][plant_cords[1]-1];
        cross_plant_region_id = find_next_not_copy(cross_plant_region_id, regions_info).region_id;
        regions_info.items[cross_plant_region_id].perimeter += 2;
    }
    if (plant_cords[0] == FIELD_HEIGHT - 1 and left_plant != plant) {
        // +1 for this plant
        regions_info.items[plant_new_region_id].perimeter += 1;
    }
    if (plant_cords[1] == FIELD_WIDTH - 1 and upper_plant != plant) {
        // +1 for this plant
        regions_info.items[plant_new_region_id].perimeter += 1;
    }
}