pub const LexError = error{InvalidSyntax};

const std = @import("std");
const token = @import("parser.zig").Token;

pub fn lex(string: []const u8, alloc: std.mem.Allocator) LexError!void {
    var tokens = std.ArrayList(token).init(alloc);
    defer tokens.deinit();

    std.debug.print("Parsing: {s}", .{string});

    return LexError.InvalidSyntax;
}
