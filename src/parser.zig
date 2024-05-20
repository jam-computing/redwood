const std = @import("std");

const node = @import("node.zig").node;
const node_object = @import("node.zig").node_object;
const node_fn = @import("node.zig").node_fn;
const Token = @import("token.zig").Token;
const stdlib = @import("stdlib.zig");
const ParseResult = @import("error.zig").ParseResult;
const ParseError = @import("error.zig").ParseError;

pub fn parse(tokens: []const Token, alloc: std.mem.Allocator) ParseResult {
    var import_map = std.StringHashMap(stdlib.imports).init(alloc);
    defer import_map.deinit();

    var value_map = std.StringHashMap(stdlib.value).init(alloc);
    defer value_map.deinit();

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
                        const imp = stdlib.imports.is_keyword(t.identifier) orelse {
                            return ParseResult.Err(ParseError.InvalidImport, i);
                        };

                        i += 1;
                        if (tokens[i] != Token.keyword) {
                            return ParseResult.Err(ParseError.InvalidTokenOrder, i);
                        }

                        if (tokens[i].keyword != .as) {
                            return ParseResult.Err(ParseError.InvalidKeywordError, i);
                        }

                        i += 1;

                        if (tokens[i] != Token.identifier) {
                            return ParseResult.Err(ParseError.InvalidTokenOrder, i);
                        }
                        const identifier = tokens[i].identifier;

                        import_map.put(identifier, imp) catch {
                            return ParseResult.Err(ParseError.ExistingIdentifer, i);
                        };

                        std.debug.print("{} imported as {s}\n", .{ imp, identifier });
                    },
                    .let => {
                        i += 1;
                        // keyword(let) identifier(iden) colon identifier(type)
                        const iden = tokens[i].identifier;
                        i += 1;

                        if (tokens[i] != Token.colon) {
                            return ParseResult.Err(ParseError.ExpectedColon, i);
                        }

                        i += 1;

                        if (tokens[i] != Token.identifier) {
                            return ParseResult.Err(ParseError.InvalidTokenOrder, i);
                        }

                        const type_name = tokens[i].identifier;

                        var rw_type = stdlib._type.is_type(type_name) orelse {
                            return ParseResult.Err(ParseError.InvalidType, i);
                        };

                        if (rw_type == .node) blk: {
                            i += 1;
                            if (tokens[i] != Token.lcurly) {
                                rw_type.node = node{ .object = .none, .colour = null, .fns = std.StringHashMap(node_fn).init(alloc) };
                                break :blk;
                            }

                            i += 1;

                            if (tokens[i] == Token.rcurly) {
                                rw_type.node = node{ .object = .none, .colour = null, .fns = std.StringHashMap(node_fn).init(alloc) };
                                break :blk;
                            }

                            if (tokens[i] != Token.identifier) {
                                return ParseResult.Err(ParseError.AllocatorError, i);
                            }

                            const node_obj = node_object.str_to_obj(tokens[i].identifier) orelse {
                                return ParseResult.Err(ParseError.InvalidType, i);
                            };

                            rw_type.node = node{ .object = node_obj, .colour = null, .fns = std.StringHashMap(node_fn).init(alloc) };

                            i += 1;

                            if (tokens[i] != Token.rcurly) {
                                return ParseResult.Err(ParseError.MissingCurlyBracket, i);
                            }
                        }

                        value_map.put(iden, stdlib.value{ .type = rw_type, .name = iden }) catch {
                            return ParseResult.Err(ParseError.AllocatorError, i);
                        };
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
                    return ParseResult.Err(ParseError.InvalidTokenOrder, i);
                }

                const node_name = tokens[i].identifier;
                var n: ?node = null;

                if (node_map.get(node_name)) |nmap_get| {
                    n = nmap_get;
                } else {
                    return ParseResult.Err(ParseError.InvalidNodeIdentifier, i);
                }

                i += 1;

                if (tokens[i] != Token.identifier) {
                    return ParseResult.Err(ParseError.InvalidTokenOrder, i);
                }

                const fn_name = tokens[i].identifier;

                i += 1;

                if (tokens[i] != Token.lbracket) {
                    return ParseResult.Err(ParseError.NoBracket, i);
                }

                i += 1;

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
                        return ParseResult.Err(ParseError.InvalidParameterList, i);
                    }
                }

                i += 1;
                if (tokens[i] != Token.colon) {
                    return ParseResult.Err(ParseError.ExpectedColon, i);
                }

                i += 1;
                if (tokens[i] != Token.identifier) {
                    return ParseResult.Err(ParseError.ExpectedIdentifier, i);
                }

                _ = tokens[i].identifier;

                i += 1;
                if (tokens[i] != Token.equals) {
                    return ParseResult.Err(ParseError.InvalidTokenOrder, i);
                }

                i += 1;

                if (tokens[i] != Token.expr) {
                    return ParseResult.Err(ParseError.InvalidTokenOrder, i);
                }

                const _fn = node_fn{ .math = tokens[i].expr, .return_type = stdlib._type.none, .parameters = parameters.toOwnedSlice() catch {
                    return ParseResult.Err(ParseError.InvalidFunctionParameter, i);
                } };

                n.?.fns.?.put(fn_name, _fn) catch {
                    return ParseResult.Err(ParseError.FunctionCreationError, i);
                };

                if (!node_map.remove(node_name)) {
                    return ParseResult.Err(ParseError.InvalidNodeIdentifier, i);
                }
                node_map.put(node_name, n.?) catch {
                    return ParseResult.Err(ParseError.InvalidNodeIdentifier, i);
                };

                // std.debug.print("Added fn, new count: {}\n", .{n.?.fns.count()});
            },
            .identifier => |_| {
                return ParseResult.Err(ParseError.InvalidTokenOrder, i);
            },
            else => {},
        }
        i += 1;
    }

    var vals = std.ArrayList(stdlib.value).init(alloc);
    defer vals.deinit();

    var values = value_map.valueIterator();
    const count = value_map.count();

    var val_count: usize = 0;

    while (values.next()) |item| {
        if (val_count == count) {
            break;
        }
        vals.append(item.*) catch {
            std.debug.print("Error appending to values\n", .{});
            continue;
        };
        val_count += 1;
    }

    return ParseResult{ .values = vals.toOwnedSlice() catch {
        return ParseResult.Err(ParseError.AllocatorError, i);
    }, .kind = null, .token_num = 0 };
}
