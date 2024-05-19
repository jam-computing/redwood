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
    expr: []const u8,

    pub fn token_to_str(token: Token) []const u8 {
        return switch (token) {
            .space => "Space",
            .one => "One",
            .two => "Two",
            .three => "Three",
            .four => "Four",
            .five => "Five",
            .six => "Six",
            .seven => "Seven",
            .eight => "Eight",
            .nine => "Nine",
            .equals => "Equals",
            .newline => "NewLine",
            .colon => "Colon",
            .semicolon => "Semicolon",
            .plus => "Plus",
            .minus => "Minus",
            .star => "Star",
            .fslash => "Forward Slash",
            .bslash => "Backslash",
            .andpercand => "Andpercand",
            .carot => "Carot",
            .comma => "Comma",
            .percent => "Percentage",
            .bang => "Bang",
            .lbracket => "Left Bracket",
            .rbracket => "Right Bracket",
            .lcurly => "Left Curly",
            .rcurly => "Right Curly",
            .lsquare => "Left Square",
            .rsquare => "Right Square",
            .underscore => "Underscore",
            .at => "At",
            .expr => |ex| ex,
            .keyword => |keyword| switch (keyword) {
                .import => "Import",
                .as => "As",
                .define => "Define",
            },
            .identifier => |identifier| identifier,
            else => "Unidentied Token",
        };
    }
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
