const std = @import("std");
const nodelib = @import("node.zig");
const _type = @import("type.zig");

pub const imports = union(enum) {
    tick,
    pub fn is_keyword(string: []const u8) ?imports {
        if (std.mem.eql(u8, string, "tick")) {
            return imports.tick;
        }
        return null;
    }
};

pub const value = struct {
    type: _type,
    name: []const u8,
};

pub const vector3 = struct {
    x: isize,
    y: isize,
    z: isize,
    pub fn empty() vector3 {
        return vector3{
            .x = 0,
            .y = 0,
            .z = 0,
        };
    }
};

pub const vector2 = struct {
    x: isize,
    y: isize,
    pub fn empty() vector2 {
        return vector2{
            .x = 0,
            .y = 0,
        };
    }
};
