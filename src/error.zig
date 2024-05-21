const std = @import("std");
const node = @import("node.zig").node;
const stdlib = @import("stdlib.zig");
const Token = @import("token.zig").Token;

pub const ParseResult = struct {
    kind: ?ParseError,
    values: ?[]stdlib.value,
    token_num: usize,
    frame_count: usize,

    pub fn Err(kind: ParseError, num: usize) ParseResult {
        return ParseResult{
            .kind = kind,
            .values = null,
            .token_num = num,
            .frame_count = 0,
        };
    }
};

pub fn report_compiletime_err(output: ParseResult, file_lines: [][]const u8, token_lines: std.ArrayList([]const Token), filename: []const u8, alloc: std.mem.Allocator) void {
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

            std.debug.print("|{s}:{}:{}| : \x1B[31merror\x1B[0m : {s}\n", .{ filename, i + 1, char_num, switch (kind) {
                ParseError.AllocatorError => "Memory space exceeded. What are you doing.",
                ParseError.InvalidNodeIdentifier => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The node: \"{s}\" does not exist.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidNodeIdentifier, could not print error message.";
                    };
                },
                ParseError.InvalidTokenOrder => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The token: \"{s}\" was not expected", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidTokenOrder, could not print error message.";
                    };
                },
                ParseError.InvalidColourIdentifier => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The specified colour: \"{s}\" is an invalid colour.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidColourIdentifier, could not print error message.";
                    };
                },
                ParseError.ExistingIdentifer => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The identifier: \"{s}\" has already been used in the program.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "ExistingIdentifier, could not print error message.";
                    };
                },
                ParseError.InvalidFunctionName => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The name: \"{s}\" is not a valid function name.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidFunctionName, could not print error message.";
                    };
                },
                ParseError.InvalidParameterList => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The parameter list should have comma separated values: \"{s}\".", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidParameterList, could not print error message.";
                    };
                },
                ParseError.InvalidFunctionParameter => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The function parameter: \"{s}\" is not a valid parameter.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidFucntionParameter, could not print error message.";
                    };
                },
                ParseError.InvalidKeywordError => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The keyword: \"{s}\" is not a valid keyword.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidKeywordError, could not print error message.";
                    };
                },
                ParseError.InvalidType => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The type: \"{s}\" does not exist.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidType, could not print error message.";
                    };
                },
                ParseError.InvalidIdentifier => blk: {
                    break :blk std.fmt.allocPrint(alloc, "The identifier: \"{s}\" is not valid.", .{Token.token_to_str(tokens_flat.items[output.token_num])}) catch {
                        break :blk "InvalidIdentifier, could not print error message.";
                    };
                },
                ParseError.FunctionCreationError => "There was an error allocating the function. This is either zigs or your problem. Good luck.",
                ParseError.InvalidImport => "The import keyword should always be followed by a valid identifier.",
                ParseError.InvalidImportLen => "The import alias should only be one character long.",
                ParseError.ExpectedColon => "Colon Expected Before Node Type.",
                ParseError.ExpectedIdentifier => "A valid type identifier is expected after a colon.",
                ParseError.NoBracket => "Brackets are needed after a function identifier declaration.",
                ParseError.MissingCurlyBracket => "Curly brackets are expected around subtype declarations.",
                ParseError.ExpectedEquals => "Expected '=' after variable declaration.",
                ParseError.ExpectedNumber => "Expected value to be a number.",
                ParseError.ExpectedAttrIdentifier => "Expected identifier after a '!' ( Attribute Flag ).",
                ParseError.InvalidAttrName => "Invalid identifier for attribute found.",
                ParseError.NotTypeInference => "The type cannot be inferred from usage. Please specify with `:`.",
                ParseError.ExpectedBang => "A '!' is expected here.",
                ParseError.EndOfTokenSequence => "No more tokens expected.",
                ParseError.ExpectedExpression => "An expression was expected after a '='.",
            } });

            std.debug.print("   -> {s}\x1B[32m      {s}\x1B[0m\n", .{ file_lines[i], underline.items });

            break;
        }
    }
}

pub const ParseError = error{
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
    ExpectedColon,
    ExpectedIdentifier,
    InvalidType,
    NoBracket,
    MissingCurlyBracket,
    ExpectedEquals,
    ExpectedNumber,
    ExpectedAttrIdentifier,
    InvalidAttrName,
    NotTypeInference,
    EndOfTokenSequence,
    ExpectedExpression,
    ExpectedBang,
    InvalidIdentifier,
};
