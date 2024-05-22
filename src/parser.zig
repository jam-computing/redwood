const std = @import("std");

const stdlib = @import("stdlib.zig");

const attr = @import("attribute.zig").attr;
const node = @import("node.zig").node;
const node_object = @import("node.zig").node_object;
const method = @import("node.zig").method;
const Token = @import("token.zig").Token;
const ParseResult = @import("error.zig").ParseResult;
const ParseError = @import("error.zig").ParseError;

pub fn parse(tokens: []const Token, alloc: std.mem.Allocator) ParseResult {
    var import_map = std.StringHashMap(stdlib.imports).init(alloc);

    var value_map = std.StringHashMap(stdlib.value).init(alloc);

    var frame_count: usize = 0;

    var i: usize = 0;

    while (i < tokens.len) {
        switch (tokens[i]) {
            .keyword => |keyword| {
                switch (keyword) {
                    .import => {
                        const import_res = parse_import(&i, &tokens);

                        if (import_res.err) |e| {
                            return e;
                        }

                        const imp = import_res.imp.?;
                        const identifier = import_res.value.?;

                        import_map.put(identifier, imp) catch {
                            return ParseResult.Err(ParseError.ExistingIdentifer, i);
                        };

                        std.debug.print("{} imported as {s}\n", .{ imp, identifier });
                    },
                    .let => blk: {
                        i += 1;
                        const iden_res = parse_identifier(&i, &tokens);

                        if (iden_res.err) |e| {
                            return e;
                        }

                        const type_res = parse_type_decl(&i, &tokens);

                        if (type_res.err) |e| {
                            if (e.kind.? == ParseError.EndOfTokenSequence) {
                                break :blk;
                            }
                            return e;
                        }

                        const attr_res = parse_attr_decl(&i, &tokens);

                        if (attr_res.err) |e| {
                            return e;
                        }

                        if (attr_res.value) |v| {
                            if (v == .frame_count) {
                                frame_count = v.frame_count;
                            }
                        }

                        if (should_ignore_name(iden_res.value.?)) {
                            break :blk;
                        }

                        value_map.put(
                            iden_res.value.?,
                            stdlib.value{
                                .type = type_res.value.?,
                                .name = iden_res.value.?,
                            },
                        ) catch {
                            return ParseResult.Err(ParseError.AllocatorError, i);
                        };
                    },
                    else => {},
                }
            },
            .at => {
                i += 1;
                const identifier_res = parse_identifier(&i, &tokens);

                if (identifier_res.err) |e| {
                    return e;
                }

                const identifier_name = identifier_res.value.?;
                var n: ?node = null;

                // If the node accessing actually exists
                if (value_map.get(identifier_name)) |val| {
                    if (val.type != stdlib._type.node) {
                        return ParseResult.Err(ParseError.InvalidType, i);
                    }
                    n = val.type.node;
                } else {
                    std.debug.print("Could not identify the node name\n", .{});
                    return ParseResult.Err(ParseError.InvalidNodeIdentifier, i);
                }

                const method_res = parse_method(&i, &tokens);

                if (method_res.err) |e| {
                    return e;
                }

                const attr_res = parse_attr_decl(&i, &tokens);

                if (attr_res.err) |e| {
                    return e;
                }

                var meth = method_res.value.?;

                if (attr_res.value) |v| {
                    std.debug.print("Attribute value found: {}\n", .{v});
                    meth.attr = v;
                }

                n.?.fns.?.put(meth.name, meth) catch {
                    return ParseResult.Err(ParseError.FunctionCreationError, i);
                };

                var val = value_map.get(identifier_name) orelse {
                    return ParseResult.Err(ParseError.InvalidIdentifier, i);
                };

                if (!value_map.remove(identifier_name)) {
                    return ParseResult.Err(ParseError.InvalidNodeIdentifier, i);
                }

                val.type.node = n.?;

                value_map.put(identifier_name, val) catch {
                    return ParseResult.Err(ParseError.InvalidNodeIdentifier, i);
                };

                // std.debug.print("Added fn, new count: {}\n", .{n.?.fns.count()});
            },
            .identifier => {
                const identifier_res = parse_identifier(&i, &tokens);

                if (identifier_res.err) |e| {
                    return e;
                }

                const t = stdlib._type.infer(identifier_res.value.?) orelse {
                    break;
                };

                if (t != stdlib._type.u) {
                    return ParseResult.Err(ParseError.InvalidType, i);
                }

                const attr_res = parse_attr_decl(&i, &tokens);

                if (attr_res.err) |e| {
                    return e;
                }

                switch (attr_res.value.?) {
                    .frame_count => {
                        frame_count = t.u;
                    },
                    else => {},
                }
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

    return ParseResult{
        .values = vals.toOwnedSlice() catch {
            return ParseResult.Err(ParseError.AllocatorError, i);
        },
        .kind = null,
        .token_num = 0,
        .frame_count = frame_count,
        .imports = import_map,
    };
}

fn parse_attr_decl(i: *usize, tokens: *const []const Token) struct { value: ?attr, err: ?ParseResult } {
    i.* += 1;

    if (tokens.len - 1 == i.*) {
        return .{ .err = null, .value = null };
    }

    if (tokens.*[i.*] != Token.bang) {
        return .{ .err = null, .value = null };
    }

    i.* += 1;

    if (tokens.len - 1 == i.*) {
        return .{ .err = ParseResult.Err(ParseError.ExpectedAttrIdentifier, i.*), .value = null };
    }

    if (tokens.*[i.*] != Token.identifier) {
        return .{ .err = ParseResult.Err(ParseError.ExpectedAttrIdentifier, i.*), .value = null };
    }

    const attrib = attr.is_type(tokens.*[i.*].identifier) orelse {
        return .{ .err = ParseResult.Err(ParseError.InvalidAttrName, i.*), .value = null };
    };

    return .{ .value = attrib, .err = null };
}

fn parse_infer_type_decl(i: *usize, tokens: *const []const Token) struct { value: ?stdlib._type, err: ?ParseResult } {
    if (tokens.*[i.*] != Token.equals) {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.ExpectedColon, i.*),
        };
    }

    i.* += 1;

    if (tokens.*[i.*] != Token.expr) {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.ExpectedIdentifier, i.*),
        };
    }

    const rw_type = stdlib._type.infer(tokens.*[i.*].expr);

    if (rw_type) |t| {
        return .{
            .value = t,
            .err = null,
        };
    } else {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.InvalidType, i.*),
        };
    }
}

fn parse_type_decl(i: *usize, tokens: *const []const Token) struct { value: ?stdlib._type, err: ?ParseResult } {
    const alloc = std.heap.page_allocator;

    i.* += 1;
    // If no colon then infer type // TERRIBLE IEDEA WHAT
    if (tokens.*[i.*] != Token.colon) {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.ExpectedColon, i.*),
        };
    }

    // let a: uint
    // @fn name(): v3

    i.* += 1;

    const iden_res = parse_identifier(i, tokens);

    if (iden_res.err) |e| {
        return .{
            .value = null,
            .err = e,
        };
    }

    const type_name = iden_res.value.?;

    var rw_type = stdlib._type.is_type(type_name) orelse {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.InvalidType, i.*),
        };
    };

    if (rw_type == .node) {
        const node_res = parse_type_node(i, tokens, alloc);
        if (node_res.err) |e| {
            return .{
                .value = null,
                .err = e,
            };
        } else {
            rw_type.node = node_res.value.?;
        }
    } else if (rw_type == .u) {
        const uint_res = parse_type_uint_assign(i, tokens);
        if (uint_res.err) |e| {
            return .{
                .value = null,
                .err = e,
            };
        } else {
            rw_type.u = uint_res.value.?;
        }
    }

    return .{
        .value = rw_type,
        .err = null,
    };
}

/// Parses an identifier pattern.
/// NOTE: This does not increment [i].
/// You should call `i += 1` before calling this.
fn parse_identifier(i: *usize, tokens: *const []const Token) struct { value: ?[]const u8, err: ?ParseResult } {
    if (tokens.*[i.*] != Token.identifier) {
        return .{ .err = ParseResult.Err(ParseError.ExpectedAttrIdentifier, i.*), .value = null };
    }
    return .{ .err = null, .value = tokens.*[i.*].identifier };
}

fn should_ignore_name(name: []const u8) bool {
    if (name[0] == '_') {
        return true;
    }

    return false;
}

fn parse_type_node(i: *usize, tokens: *const []const Token, alloc: std.mem.Allocator) struct { value: ?node, err: ?ParseResult } {
    i.* += 1;

    if (tokens.*[i.*] != Token.lcurly) {
        return .{
            .value = node{
                .object = .none,
                .colour = null,
                .fns = std.StringHashMap(method).init(alloc),
            },
            .err = null,
        };
    }

    i.* += 1;

    if (tokens.*[i.*] == Token.rcurly) {
        return .{
            .value = node{ .object = .none, .colour = null, .fns = std.StringHashMap(method).init(alloc) },
            .err = null,
        };
    }

    if (tokens.*[i.*] != Token.identifier) {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.AllocatorError, i.*),
        };
    }

    const node_obj = node_object.str_to_obj(tokens.*[i.*].identifier) orelse {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.InvalidType, i.*),
        };
    };

    const n = node{
        .object = node_obj,
        .colour = null,
        .fns = std.StringHashMap(method).init(alloc),
    };

    i.* += 1;

    if (tokens.*[i.*] != Token.rcurly) {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.MissingCurlyBracket, i.*),
        };
    }

    return .{
        .value = n,
        .err = null,
    };
}

fn parse_type_uint_assign(i: *usize, tokens: *const []const Token) struct { value: ?usize, err: ?ParseResult } {
    i.* += 1;

    if (tokens.*[i.*] != Token.equals) {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.ExpectedEquals, i.*),
        };
    }

    i.* += 1;
    if (tokens.*[i.*] != Token.expr) {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.ExpectedNumber, i.*),
        };
    }

    const num = tokens.*[i.*].expr;

    const value = stdlib._type.infer(num) orelse {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.NotTypeInference, i.*),
        };
    };

    return .{
        .value = value.u,
        .err = null,
    };
}

fn parse_import(i: *usize, tokens: *const []const Token) struct { imp: ?stdlib.imports, value: ?[]const u8, err: ?ParseResult } {
    i.* += 1;
    if (tokens.*[i.*] != Token.identifier) {
        return .{
            .imp = null,
            .value = null,
            .err = ParseResult.Err(ParseError.InvalidTokenOrder, i.*),
        };
    }
    const t = tokens.*[i.*];

    const imp = stdlib.imports.is_keyword(t.identifier) orelse {
        return .{
            .imp = null,
            .value = null,
            .err = ParseResult.Err(ParseError.InvalidImport, i.*),
        };
    };

    i.* += 1;
    if (tokens.*[i.*] != Token.keyword) {
        return .{
            .imp = null,
            .value = null,
            .err = ParseResult.Err(ParseError.InvalidTokenOrder, i.*),
        };
    }

    if (tokens.*[i.*].keyword != .as) {
        return .{
            .imp = null,
            .value = null,
            .err = ParseResult.Err(ParseError.InvalidKeywordError, i.*),
        };
    }

    i.* += 1;

    if (tokens.*[i.*] != Token.identifier) {
        return .{
            .imp = null,
            .value = null,
            .err = ParseResult.Err(ParseError.InvalidTokenOrder, i.*),
        };
    }
    const identifier = tokens.*[i.*].identifier;

    return .{
        .value = identifier,
        .imp = imp,
        .err = null,
    };
}

fn parse_expr(i: *usize, tokens: *const []const Token) struct { value: ?[]const u8, err: ?ParseResult } {
    i.* += 1;

    if (tokens.*[i.*] != Token.equals) {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.ExpectedEquals, i.*),
        };
    }

    i.* += 1;

    if (tokens.*[i.*] != Token.expr) {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.ExpectedExpression, i.*),
        };
    }

    const expression = tokens.*[i.*].expr;

    return .{
        .value = expression,
        .err = null,
    };
}

fn parse_method(i: *usize, tokens: *const []const Token) struct { value: ?method, err: ?ParseResult } {
    i.* += 1;
    const name_res = parse_identifier(i, tokens);

    if (name_res.err) |e| {
        return .{
            .value = null,
            .err = e,
        };
    }

    // f(t): v3 = expr
    const parameter_res = parse_parameters(i, tokens);

    if (parameter_res.err) |e| {
        return .{ .value = null, .err = e };
    }

    const type_res = parse_type_decl(i, tokens);

    if (type_res.err) |e| {
        return .{ .value = null, .err = e };
    }

    const expr_res = parse_expr(i, tokens);

    if (expr_res.err) |e| {
        return .{
            .value = null,
            .err = e,
        };
    }

    const m = method{
        .name = name_res.value.?,
        .parameters = parameter_res.value.?,
        .return_type = type_res.value.?,
        .math = expr_res.value.?,
        .attr = null,
    };

    return .{
        .value = m,
        .err = null,
    };
}

/// Parses pattern for method parameters.
/// Returns list of parameter identifiers
fn parse_parameters(i: *usize, tokens: *const []const Token) struct { value: ?[][]const u8, err: ?ParseResult } {
    const alloc = std.heap.page_allocator;

    i.* += 1;

    if (tokens.*[i.*] != Token.lbracket) {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.NoBracket, i.*),
        };
    }

    i.* += 1;

    var paras = std.ArrayList([]const u8).init(alloc);

    defer paras.deinit();

    // Check if tokens[i] == Token.rbracket;
    while (tokens.*[i.*] != Token.rbracket) : (i.* += 1) {
        if (tokens.*[i.*] != Token.identifier) {
            paras.append(tokens.*[i.*].identifier) catch {
                continue;
            };
        } else if (tokens.*[i.*] == Token.comma) {
            continue;
        } else {
            return .{
                .value = null,
                .err = ParseResult.Err(ParseError.InvalidParameterList, i.*),
            };
        }
    }

    if (tokens.*[i.*] != Token.rbracket) {
        return .{
            .value = null,
            .err = ParseResult.Err(ParseError.NoBracket, i.*),
        };
    }

    return .{
        .value = paras.toOwnedSlice() catch {
            return .{
                .value = null,
                .err = ParseResult.Err(ParseError.AllocatorError, i.*),
            };
        },
        .err = null,
    };
}
