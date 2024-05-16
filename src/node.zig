const std = @import("std");

pub const node = struct {
    name: []const u8,
    object: node_object,
    colour: ?[]const u8,
    fns: std.StringHashMap(node_fn),
};
pub const node_object = enum {
    none,
    plane,

    pub fn str_to_obj(str: []const u8) ?node_object {
        if (std.mem.eql(u8, str, "plane")) {
            return node_object.plane;
        }
        if (std.mem.eql(u8, str, "none")) {
            return node_object.plane;
        }
        return null;
    }
};

pub const node_fn = struct {
    math: []const u8,
};
