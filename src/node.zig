const std = @import("std");
const stdlib = @import("stdlib.zig");
const attr = @import("attribute.zig").attr;
const _fn = @import("type.zig");

pub const node = struct {
    object: node_object,
    colour: ?[]const u8,
    fns: ?std.StringHashMap(_fn),

    pub fn empty() node {
        return node{
            .object = node_object.none,
            .fns = null,
            .colour = null,
        };
    }
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
