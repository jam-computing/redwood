const std = @import("std");
pub const imports = enum {
    tick,
    pub fn is_keyword(string: []const u8) ?imports {
        if (std.mem.eql(u8, string, "tick")) {
            return imports.tick;
        }
        return null;
    }
};
