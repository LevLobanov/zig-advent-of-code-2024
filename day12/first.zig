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

            if (plant == upper_plant) {
                if (plant == left_plant) {
                    // combine regions of both plants in one (upper one)
                    attach_to_region(
                        .{ i, j },
                        &regions_info,
                        &plants_regions_ids,
                        AttachmentType.combine
                    );
                } else {
                    // attach to region of upper plant
                    attach_to_region(
                        .{ i, j },
                        &regions_info,
                        &plants_regions_ids,
                        AttachmentType.upper
                    );
                }
            } else if (plant == left_plant) {
                // attach to region of left plant
                attach_to_region(
                    .{ i, j },
                    &regions_info,
                    &plants_regions_ids,
                    AttachmentType.left
                );
            } else {
                // new region
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
                    AttachmentType.none,
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

    dprint("\n\nFinal RegionsInfo: {any}\n\n", .{regions_info.items});

    for (regions_info.items, 0..) |region, n| {
        if (region.copy_of == IS_NOT_COPY) {
            dprint("Cost for region {}: p ({}) * a ({}) = {}\n", .{n, region.perimeter, region.area, region.perimeter * region.area});
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

const AttachmentType = enum(u2) { upper, left, combine, none };

pub fn attach_to_region(
    plant_cords: [2]usize,
    regions_info: *std.ArrayList(RegionInfo),
    plants_regions_ids: *[FIELD_HEIGHT][FIELD_WIDTH]usize,
    attachment_type: AttachmentType,
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
            // The first "not copy" left plant region
            const next_not_copy_region_id = find_next_not_copy(left_plant_region_id, regions_info).region_id;
            // add plant to that region
            regions_info.items[next_not_copy_region_id].area += 1;
            regions_info.items[next_not_copy_region_id].perimeter += 1;
            // set this plant's region id
            plant_new_region_id = next_not_copy_region_id;
        },
        AttachmentType.upper => {
            // The first "not copy" upper plant region
            const next_not_copy_region_id = find_next_not_copy(upper_plant_region_id, regions_info).region_id;
            // add plant to that region
            regions_info.items[next_not_copy_region_id].area += 1;
            regions_info.items[next_not_copy_region_id].perimeter += 1;
            // set this plant's region id
            plant_new_region_id = next_not_copy_region_id;
        },
        AttachmentType.combine => {
            // The first "not copy" upper plant region
            const next_not_copy_upper = find_next_not_copy(upper_plant_region_id, regions_info);
            // The first "not copy" left plant region
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
        AttachmentType.none => unreachable,
    }
    // add perimeter to neighbours
    add_perimeter_to_neighbours(
        plant_cords,
        regions_info,
        plants_regions_ids,
        attachment_type,
        plant_new_region_id,
    );
    // set this plant's region id
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
    attachment_type: AttachmentType,
    plant_new_region_id: usize,
) void {
    if (plant_cords[0] != 0 and attachment_type != AttachmentType.upper and attachment_type != AttachmentType.combine) {
        const next_not_copy_region_id = find_next_not_copy(plants_regions_ids[plant_cords[0] - 1][plant_cords[1]], regions_info).region_id;
        regions_info.items[next_not_copy_region_id].perimeter += 1;
    }
    if (plant_cords[1] != 0 and attachment_type != AttachmentType.left and attachment_type != AttachmentType.combine) {
        const next_not_copy_region_id = find_next_not_copy(plants_regions_ids[plant_cords[0]][plant_cords[1]-1], regions_info).region_id;
        regions_info.items[next_not_copy_region_id].perimeter += 1;
    }
    if (plant_cords[0] == FIELD_HEIGHT - 1) {
        regions_info.items[plant_new_region_id].perimeter += 1;
    }
    if (plant_cords[1] == FIELD_WIDTH - 1) {
        regions_info.items[plant_new_region_id].perimeter += 1;
    }
}