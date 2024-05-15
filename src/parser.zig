pub const Token = union(enum) { one, two, three, four, five, six, seven, eight, nine, equals, space, newline, colon, semicolon, minus, plus, star, fslash, bslash, carot, percent, bang, andpercand, lbracket, rbracket, lcurly, rcurly, underscore, keyword: []const u8, none };
pub const Keyword = enum { plane };
