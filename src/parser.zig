pub const Token = union(enum) { one, two, three, four, five, six, seven, eight, nine, equals, space, newline, colon, semicolon, minus, plus, star, fslash, bslash, carot, percent, bang, andpercand, lbracket, rbracket, lcurly, rcurly, lsquare, rsquare, underscore, at, keyword: Keyword, identifier: []const u8, none };
pub const Keyword = enum {
    import,
    define,
    as,
    pub fn str_to_obj(str: []const u8) ?Keyword {
        // There HAS to be a better way to do this
        if (std.mem.eql(u8, str, "import")) {
            return Keyword.import;
        }
        if (std.mem.eql(u8, str, "define")) {
            return Keyword.define;
        }
        if (std.mem.eql(u8, str, "as")) {
            return Keyword.as;
        }
        return null;
    }
};

// Hashmap of imported things?

const std = @import("std");
const redlib = @import("stdlib.zig");

pub const ParseError = error{ AllocatorError, InvalidTokenOrder, InvalidObjIdentifier, InvalidColourIdentifier, InvalidImport, ExistingIdentifer, InvalidImportLen };

const node = struct { object: node_object, colour: ?[]const u8 };
const node_object = enum {
    none,
    plane,
    pub fn str_to_obj(str: []const u8) ?node_object {
        // There HAS to be a better way to do this
        if (std.mem.eql(u8, str, "plane")) {
            return node_object.plane;
        }
        if (std.mem.eql(u8, str, "none")) {
            return node_object.plane;
        }
        return null;
    }
};

pub fn parse(tokens: []const Token, alloc: std.mem.Allocator) ParseError!?[]node {
    var import_map = std.AutoHashMap(u8, redlib.imports).init(alloc);
    defer import_map.deinit();

    var node_map = std.StringHashMap(node).init(alloc);
    defer node_map.deinit();

    var i: usize = 0;

    while (i < tokens.len) {
        // std.debug.print("Token: {}\n", .{token});
        switch (tokens[i]) {
            .keyword => |keyword| {
                // swithc on keyword
                switch (keyword) {
                    .import => {
                        i += 1;
                        const t = tokens[i];
                        const imp = redlib.imports.is_keyword(t.identifier) orelse {
                            std.debug.print("Invalid import\n", .{});
                            return ParseError.InvalidImport;
                        };
                        // Look for as
                        i += 1;
                        if (tokens[i].keyword != .as) {
                            return ParseError.InvalidTokenOrder;
                        }
                        i += 1;
                        const identifier = tokens[i].identifier;

                        if (identifier.len != 1) {
                            return ParseError.InvalidImportLen;
                        }

                        import_map.put(identifier[0], imp) catch {
                            return ParseError.ExistingIdentifer;
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
                            node_map.put(node_name, node{ .object = obj, .colour = null }) catch {
                                return ParseError.ExistingIdentifer;
                            };
                        }

                        std.debug.print("Node {s} created as {s}\n", .{ node_name, node_object_name });
                    },
                    else => {},
                }
            },
            .identifier => |_| {},
            else => {},
        }
        i += 1;
    }

    var nodes = std.ArrayList(node).init(alloc);
    defer nodes.deinit();

    var values = node_map.valueIterator();
    const count = node_map.count();

    std.debug.print("Node Count: {}\n", .{count});

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

    return nodes.toOwnedSlice() catch {
        return ParseError.AllocatorError;
    };
}
