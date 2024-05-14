pub const Token = union(enum) { lbracket, rbracket, lcurly, rcurly, keyword: Keyword, none };
pub const Keyword = enum { plane };
