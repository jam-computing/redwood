const std = @import("std");

pub const Token = union(enum) {
    one,
    two,
    three,
    four,
    five,
    six,
    seven,
    eight,
    nine,

    space,
    newline,
    colon,
    semicolon,
    comma,

    equals,
    minus,
    plus,
    star,
    fslash,

    bslash,
    carot,
    percent,
    bang,
    andpercand,

    lbracket,
    rbracket,

    lcurly,
    rcurly,

    lsquare,
    rsquare,

    underscore,
    at,

    none,

    keyword: Keyword,
    identifier: []const u8,
};

pub const Keyword = enum {
    import,
    define,
    as,

    pub fn str_to_obj(str: []const u8) ?Keyword {
        // There HAS to be a better way to do this
        if (std.mem.eql(u8, str, "import")) {
            return Keyword.import;
        }
        if (std.mem.eql(u8, str, "define")) {
            return Keyword.define;
        }
        if (std.mem.eql(u8, str, "as")) {
            return Keyword.as;
        }
        return null;
    }
};
