const rtype = @import("stdlib.zig").rtype;
pub const config = struct {
    locations: []rtype.vector3,
    count: usize,
};

pub const output = struct {
    frames: [][]rtype.vector3,
};
