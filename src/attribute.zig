const std = @import("std");

pub const attr = union(enum) {
    frame_count: usize,
    init,
    update,
    colour,

    pub fn is_type(string: []const u8) ?attr {
        if (std.mem.eql(u8, string, "frame_count")) {
            return attr{ .frame_count = 0 };
        } else if (std.mem.eql(u8, string, "ini")) {
            return attr.init;
        } else if (std.mem.eql(u8, string, "update")) {
            return attr.update;
        } else if (std.mem.eql(u8, string, "col")) {
            return attr.colour;
        }
        return null;
    }
};
