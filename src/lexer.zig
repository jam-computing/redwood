pub const LexError = error{InvalidSyntax};

const std = @import("std");
const Token = @import("parser.zig").Token;

pub fn lex(string: []const u8, alloc: std.mem.Allocator) !void {
    var tokens = std.ArrayList(Token).init(alloc);
    defer tokens.deinit();

    // TODO: Change this loop so that i can read words
    var i: usize = 0;
    while (i < string.len) : (i += 1) {
        const t = switch (string[i]) {
            ' ' => Token.space,
            '(' => Token.lbracket,
            ')' => Token.rbracket,
            '{' => Token.lcurly,
            '}' => Token.rcurly,
            else => blk: {
                var iden = std.ArrayList(u8).init(alloc);
                defer iden.deinit();
                while ((string[i] != ' ') and (i < string.len - 1)) : (i += 1) {
                    try iden.append(string[i]);
                }
                break :blk Token{ .keyword = try iden.toOwnedSlice() };
            },
        };
        _ = try tokens.append(t);
    }

    const sli = tokens.toOwnedSlice() catch {
        return LexError.InvalidSyntax;
    };

    print_tokens(sli);

    return LexError.InvalidSyntax;
}

fn print_tokens(tokens: []Token) void {
    for (tokens) |token| {
        std.debug.print("{s}\n", .{switch (token) {
            .space => "Space",
            .lbracket => "Left Bracket",
            .rbracket => "Right Bracket",
            .lcurly => "Left Curly",
            .rcurly => "Right Curly",
            .keyword => |keyword| keyword,
            else => "",
        }});
    }
}
