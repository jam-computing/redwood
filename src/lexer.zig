pub const LexError = error{InvalidSyntax};

const std = @import("std");
const Token = @import("parser.zig").Token;
const Keyword = @import("parser.zig").Keyword;

pub fn lex(string: []const u8, alloc: std.mem.Allocator) ![]const Token {
    var tokens = std.ArrayList(Token).init(alloc);

    // TODO: Change this loop so that i can read words
    var i: usize = 0;
    while (i < string.len) : (i += 1) {
        const t = switch (string[i]) {
            ' ' => continue,
            '1' => Token.one,
            '2' => Token.two,
            '3' => Token.three,
            '4' => Token.four,
            '5' => Token.five,
            '6' => Token.six,
            '7' => Token.seven,
            '8' => Token.eight,
            '9' => Token.nine,
            '=' => Token.equals,
            '\n' => Token.newline,
            ':' => Token.colon,
            ';' => Token.semicolon,
            '&' => Token.andpercand,
            '+' => Token.plus,
            '-' => Token.minus,
            '*' => Token.star,
            '/' => Token.fslash,
            '\\' => Token.bslash,
            '^' => Token.carot,
            '%' => Token.percent,
            '!' => Token.bang,
            '(' => Token.lbracket,
            ')' => Token.rbracket,
            '{' => Token.lcurly,
            '}' => Token.rcurly,
            '[' => Token.lsquare,
            ']' => Token.rsquare,
            '_' => Token.underscore,
            '@' => Token.at,
            else => blk: {
                if (!std.ascii.isAlphabetic(string[i])) {
                    break :blk Token.none;
                }
                var iden = std.ArrayList(u8).init(alloc);
                defer iden.deinit();
                while (i < string.len) : (i += 1) {
                    try iden.append(string[i]);
                    if (i != string.len - 1 and (string[i + 1] == ' ' or string[i + 1] == '\n' or !std.ascii.isAlphabetic(string[i + 1]))) {
                        break;
                    }
                }

                const kword = Keyword.str_to_obj(iden.items) orelse {
                    break :blk Token{ .identifier = try iden.toOwnedSlice() };
                };

                break :blk Token{ .keyword = kword };
            },
        };
        _ = try tokens.append(t);
    }

    // print_tokens(tokens.items);
    return tokens.items;
}

fn print_tokens(tokens: []Token) void {
    for (tokens) |token| {
        std.debug.print("{s}\n", .{switch (token) {
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
            .identifier => |keyword| keyword,
            else => "Unidentied Token",
        }});
    }
}
