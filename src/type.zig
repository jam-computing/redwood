const std = @import("std");

const attr = @import("attribute.zig").attr;
const vector3 = @import("stdlib.zig").vector3;
const vector2 = @import("stdlib.zig").vector2;
const nodelib = @import("node.zig");

pub const _type = union(enum) {
    vector3: vector3,
    vector2: vector2,

    node: nodelib.node,
    u: usize,

    none,
    pub fn is_type(string: []const u8) ?_type {
        if (std.mem.eql(u8, string, "v3")) {
            return _type{ .vector3 = vector3.empty() };
        } else if (std.mem.eql(u8, string, "node")) {
            return _type{ .node = nodelib.node.empty() };
        } else if (std.mem.eql(u8, string, "none")) {
            return _type.none;
        } else if (std.mem.eql(u8, string, "v2")) {
            return _type{ .vector2 = vector2.empty() };
        } else if (std.mem.eql(u8, string, "uint")) {
            return _type{ .u = 0 };
        }
        return null;
    }

    pub fn infer(string: []const u8) ?_type {
        const val = std.fmt.parseInt(usize, string, 10) catch {
            return null;
        };
        return _type{ .u = val };
    }
};

pub const _fn = struct {
    name: []const u8,
    parameter: []const u8,
    return_type: _type,
    body: []const u8,
    attr: ?attr,
};
