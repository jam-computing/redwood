pub const Token = union(enum) { space, lbracket, rbracket, lcurly, rcurly, keyword: []const u8, none };
pub const Keyword = enum { plane };
