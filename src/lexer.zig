pub const LexError = error{InvalidSyntax};

const std = @import("std");
const Token = @import("parser.zig").Token;

pub fn lex(string: []const u8, alloc: std.mem.Allocator) LexError!void {
    var tokens = std.ArrayList(Token).init(alloc);
    defer tokens.deinit();

    // TODO: Change this loop so that i can read words
    for (string) |char| {
        tokens.append(switch (char) {
            '(' => Token.lbracket,
            ')' => Token.rbracket,
            '{' => Token.lcurly,
            '}' => Token.rcurly,
            else => Token.none,
        }) catch {
            continue;
        };
    }

    const sli = tokens.toOwnedSlice() catch {
        return LexError.InvalidSyntax;
    };

    print_tokens(sli);

    return LexError.InvalidSyntax;
}

fn print_tokens(tokens: []Token) void {
    for (tokens) |token| {
        std.debug.print("{s}", .{switch (token) {
            .lbracket => "Left Bracket\n",
            .rbracket => "Right Bracket\n",
            .lcurly => "Left Curly\n",
            .rcurly => "Right Curly\n",
            else => "",
        }});
    }
}
