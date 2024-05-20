const std = @import("std");
const nodelib = @import("node.zig");

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
