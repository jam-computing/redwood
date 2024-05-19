const std = @import("std");

const node = @import("node.zig").node;
const node_object = @import("node.zig").node_object;
const node_fn = @import("node.zig").node_fn;
const Token = @import("token.zig").Token;
const redlib = @import("stdlib.zig");

pub const ParseErrorKind = error{
    InvalidNodeIdentifier,
    AllocatorError,
    InvalidTokenOrder,
    InvalidObjIdentifier,
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

pub fn parse(tokens: []const Token, alloc: std.mem.Allocator) ParseError {
    var import_map = std.AutoHashMap(u8, redlib.imports).init(alloc);
    defer import_map.deinit();

    var node_map = std.StringHashMap(node).init(alloc);
    defer node_map.deinit();

    var i: usize = 0;

    while (i < tokens.len) {
        switch (tokens[i]) {
            .keyword => |keyword| {
                switch (keyword) {
                    .import => {
                        i += 1;
                        const t = tokens[i];
                        const imp = redlib.imports.is_keyword(t.identifier) orelse {
                            std.debug.print("Invalid import\n", .{});
                            return ParseError.Err(ParseErrorKind.InvalidImport, i);
                        };
                        i += 1;
                        if (tokens[i] != Token.keyword) {
                            return ParseError.Err(ParseErrorKind.InvalidTokenOrder, i);
                        }
                        if (tokens[i].keyword != .as) {
                            return ParseError.Err(ParseErrorKind.InvalidKeywordError, i);
                        }
                        i += 1;
                        const identifier = tokens[i].identifier;

                        if (identifier.len != 1) {
                            return ParseError.Err(ParseErrorKind.InvalidImportLen, i);
                        }

                        import_map.put(identifier[0], imp) catch {
                            return ParseError.Err(ParseErrorKind.ExistingIdentifer, i);
                        };
                        std.debug.print("Imported: {} as {c}\n", .{ imp, identifier[0] });
                    },
                    .define => {
                        i += 1;
                        // keyword(define) identifier(node_name) identifier(node_object_name)
                        const node_name = tokens[i].identifier;
                        i += 1;

                        const node_object_name = tokens[i].identifier;
                        const node_obj = node_object.str_to_obj(node_object_name);

                        if (node_obj) |obj| {
                            node_map.put(node_name, node{ .name = node_name, .object = obj, .colour = null, .fns = std.StringHashMap(node_fn).init(alloc) }) catch {
                                return ParseError.Err(ParseErrorKind.ExistingIdentifer, i);
                            };
                        } else {
                            return ParseError.Err(ParseErrorKind.InvalidNodeIdentifier, i);
                        }
                    },
                    else => {},
                }
            },
            .at => {
                i += 1;
                // token(@) identifier(node_obj_name) identifier(fn_name)
                // token(lbracket) list(identifier) token(rbracket) token(equals)
                // token(math_expr)

                if (tokens[i] != Token.identifier) {
                    return ParseError.Err(ParseErrorKind.InvalidTokenOrder, i);
                }

                const node_name = tokens[i].identifier;
                var n: ?node = null;

                if (node_map.get(node_name)) |nmap_get| {
                    n = nmap_get;
                } else {
                    return ParseError.Err(ParseErrorKind.InvalidNodeIdentifier, i);
                }

                i += 1;
                if (tokens[i] != Token.identifier) {
                    return ParseError.Err(ParseErrorKind.InvalidTokenOrder, i);
                }
                const fn_name = tokens[i].identifier;
                if (n.?.fns.get(fn_name)) |_| {
                    std.debug.print("Invalid function\n", .{});
                    return ParseError.Err(ParseErrorKind.InvalidFunctionName, i);
                }

                i += 2;

                var parameters = std.ArrayList([]const u8).init(alloc);
                defer parameters.deinit();

                // Check if tokens[i] == Token.rbracket;
                while (tokens[i] != Token.rbracket) : (i += 1) {
                    if (tokens[i] == Token.identifier) {
                        parameters.append(tokens[i].identifier) catch {
                            continue;
                        };
                    } else if (tokens[i] == Token.comma) {
                        continue;
                    } else {
                        return ParseError.Err(ParseErrorKind.InvalidParameterList, i);
                    }
                }

                i += 1;
                if (tokens[i] != Token.equals) {
                    return ParseError.Err(ParseErrorKind.InvalidTokenOrder, i);
                }

                i += 1;

                if (tokens[i] != Token.expr) {
                    return ParseError.Err(ParseErrorKind.InvalidTokenOrder, i);
                }

                const _fn = node_fn{ .math = tokens[i].expr, .parameters = parameters.toOwnedSlice() catch {
                    return ParseError.Err(ParseErrorKind.InvalidFunctionParameter, i);
                } };

                n.?.fns.put(fn_name, _fn) catch {
                    return ParseError.Err(ParseErrorKind.FunctionCreationError, i);
                };

                if (!node_map.remove(node_name)) {
                    return ParseError.Err(ParseErrorKind.InvalidNodeIdentifier, i);
                }
                node_map.put(node_name, n.?) catch {
                    return ParseError.Err(ParseErrorKind.InvalidNodeIdentifier, i);
                };

                std.debug.print("Added fn, new count: {}\n", .{n.?.fns.count()});
            },
            .identifier => |_| {
                return ParseError.Err(ParseErrorKind.InvalidTokenOrder, i);
            },
            else => {},
        }
        i += 1;
    }

    var nodes = std.ArrayList(node).init(alloc);
    defer nodes.deinit();

    var values = node_map.valueIterator();
    const count = node_map.count();

    var val_count: usize = 0;

    while (values.next()) |item| {
        if (val_count == count) {
            break;
        }
        nodes.append(item.*) catch {
            std.debug.print("Error appending to nodes\n", .{});
            continue;
        };
        val_count += 1;
    }

    return ParseError{ .nodes = nodes.toOwnedSlice() catch {
        return ParseError.Err(ParseErrorKind.AllocatorError, i);
    }, .kind = null, .token_num = 0 };
}
