pub const LexError = error{InvalidSyntax};

const std = @import("std");
const Token = @import("token.zig").Token;
const Keyword = @import("token.zig").Keyword;

pub fn lex(string: []const u8, alloc: std.mem.Allocator) ![]const Token {
    var tokens = std.ArrayList(Token).init(alloc);

    // TODO: Change this loop so that i can read words
    var i: usize = 0;
    while (i < string.len) : (i += 1) {
        const t = switch (string[i]) {
            ' ' => continue,
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
            ',' => Token.comma,
            '%' => Token.percent,
            '!' => Token.bang,
            '(' => Token.lbracket,
            ')' => Token.rbracket,
            '{' => Token.lcurly,
            '}' => Token.rcurly,
            '[' => Token.lsquare,
            ']' => Token.rsquare,
            '_' => Token{ .identifier = "_" },
            '@' => Token.at,
            // Math expr should always be after equals
            '=' => eql: {
                i += 1;
                var expr = std.ArrayList(u8).init(alloc);
                defer expr.deinit();
                while (string[i] != '\n') : (i += 1) {
                    expr.append(string[i]) catch {
                        continue;
                    };
                    if (string[i + 1] == '!' or string[i + 1] == '\n') {
                        break;
                    }
                }
                const math = expr.toOwnedSlice() catch {
                    break :eql Token.equals;
                };
                _ = try tokens.append(Token.equals);
                const trimmed = std.mem.trim(u8, math, &[_]u8{ ' ', '\t' });
                break :eql Token{ .expr = trimmed };
            },
            else => blk: {
                if (!std.ascii.isAlphanumeric(string[i])) {
                    break :blk Token.none;
                }
                var iden = std.ArrayList(u8).init(alloc);
                defer iden.deinit();
                while (i < string.len) : (i += 1) {
                    try iden.append(string[i]);
                    if (i != string.len - 1 and (string[i + 1] == ' ' or string[i + 1] == '!' or string[i + 1] == '\n' or (!std.ascii.isAlphanumeric(string[i + 1]) and string[i + 1] != '_'))) {
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
        }});
    }
}
