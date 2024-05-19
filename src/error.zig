const std = @import("std");
const node = @import("node.zig").node;
const Token = @import("token.zig").Token;

pub const ParseError = struct {
    kind: ?ParseErrorKind,
    nodes: ?[]node,
    token_num: usize,

    pub fn Err(kind: ParseErrorKind, num: usize) ParseError {
        return ParseError{
            .kind = kind,
            .nodes = null,
            .token_num = num,
        };
    }
};

pub fn report_compiletime_err(output: ParseError, file_lines: [][]const u8, token_lines: std.ArrayList([]const Token), filename: []const u8, alloc: std.mem.Allocator) void {
    if (output.kind) |kind| {
        const token_num = output.token_num;
        var token_counter: usize = token_num;
        var i: usize = 0;

        var tokens_flat = std.ArrayList(Token).init(alloc);
        defer tokens_flat.deinit();
        for (token_lines.items) |item| {
            tokens_flat.appendSlice(item) catch {
                continue;
            };
        }

        while (i < token_lines.items.len) : (i += 1) {
            const line = token_lines.items[i];

            if (line.len <= token_counter) {
                token_counter -= line.len;
                continue;
            }

            var underline = std.ArrayList(u8).init(alloc);
            defer underline.deinit();
            var word_num: usize = 0;
            var char_num: usize = 0;
            var k: usize = 0;
            while (k < file_lines[i].len) : (k += 1) {
                if (file_lines[i][k] == ' ') {
                    word_num += 1;
                }

                if (word_num == token_counter and file_lines[i][k] != ' ') {
                    if (char_num == 0) {
                        char_num = k;
                    }
                    underline.append('^') catch {
                        continue;
                    };
                } else {
                    underline.append('~') catch {
                        continue;
                    };
                }
            }
            // Cuase 1 bgger than what it should be obvs
            _ = underline.pop();

            // Filename:linenumber:char : error : ERROR_MSG
            //  -> Line here
            //       ~~~^~~~

            std.debug.print("{s}:{}:{} : \x1B[31merror\x1B[0m : {s}\n", .{ filename, i + 1, char_num, switch (kind) {
                ParseErrorKind.AllocatorError => "Memory space exceeded. What are you doing.",
                ParseErrorKind.InvalidNodeIdentifier => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The node: \"{s}\" does not exist.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidNodeIdentifier, could not print error message.";
                    };
                },
                ParseErrorKind.InvalidTokenOrder => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The token: \"{s}\" was not expected", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidTokenOrder, could not print error message.";
                    };
                },
                ParseErrorKind.InvalidColourIdentifier => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The specified colour: \"{s}\" is an invalid colour.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidTokenOrder, could not print error message.";
                    };
                },
                ParseErrorKind.ExistingIdentifer => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The identifier: \"{s}\" has already been used in the program.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidTokenOrder, could not print error message.";
                    };
                },
                ParseErrorKind.InvalidFunctionName => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The name: \"{s}\" is not a valid function name.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidTokenOrder, could not print error message.";
                    };
                },
                ParseErrorKind.InvalidParameterList => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The parameter list should have comma separated values: \"{s}\".", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidTokenOrder, could not print error message.";
                    };
                },
                ParseErrorKind.InvalidFunctionParameter => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The function parameter: \"{s}\" is not a valid parameter.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidTokenOrder, could not print error message.";
                    };
                },
                ParseErrorKind.InvalidKeywordError => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The keyword: \"{s}\" is not a valid keyword.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidTokenOrder, could not print error message.";
                    };
                },
                ParseErrorKind.FunctionCreationError => "There was an error allocating the function. This is either zigs or your problem. Good luck.",
                ParseErrorKind.InvalidImport => "The import keyword should always be followed by a valid identifier.",
                ParseErrorKind.InvalidImportLen => "The import alias should only be one character long.",
            } });

            std.debug.print("   -> {s}\x1B[32m      {s}\x1B[0m\n", .{ file_lines[i], underline.items });

            break;
        }
    }
}

pub const ParseErrorKind = error{
    InvalidNodeIdentifier,
    AllocatorError,
    InvalidTokenOrder,
    InvalidColourIdentifier,
    InvalidImport,
    ExistingIdentifer,
    InvalidImportLen,
    InvalidFunctionName,
    InvalidParameterList,
    FunctionCreationError,
    InvalidFunctionParameter,
    InvalidKeywordError,
};
