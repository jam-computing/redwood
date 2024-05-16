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

pub const ParseError = error{ InvalidTokenOrder, InvalidObjIdentifier, InvalidColourIdentifier, InvalidImport, ExistingIdentifer, InvalidImportLen };

const fn_data = struct { object: fn_object, colour: ?[]const u8 };
const fn_object = enum {
    none,
    plane,
    pub fn str_to_obj(str: []const u8) ?fn_object {
        // There HAS to be a better way to do this
        if (std.mem.eql(u8, str, "plane")) {
            return fn_object.plane;
        }
        if (std.mem.eql(u8, str, "none")) {
            return fn_object.plane;
        }
        return null;
    }
};

pub fn parse(tokens: []const Token, alloc: std.mem.Allocator) ParseError!?fn_data {
    var import_map = std.AutoHashMap(u8, redlib.imports).init(alloc);
    defer import_map.deinit();
    var i: usize = 0;
    var data: fn_data = fn_data{ .object = .none, .colour = null };
    while (i < tokens.len) {
        // std.debug.print("Token: {}\n", .{token});
        switch (tokens[i]) {
            .keyword => |keyword| {
                // swithc on keyword
                switch (keyword) {
                    .import => {
                        // Check if
                        i += 1;
                        std.debug.print("Import val = {s}\n", .{tokens[i].identifier});
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
                    else => {},
                }
            },
            .lsquare => {
                i += 1;
                if (tokens[i] == .rsquare) {
                    return ParseError.InvalidObjIdentifier;
                }
                std.debug.print("Token: {}\n", .{tokens[i]});
                if (tokens[i] != .identifier) {
                    return ParseError.InvalidTokenOrder;
                }
                const obj = fn_object.str_to_obj(tokens[i].identifier);
                if (obj) |o| {
                    data.object = o;
                } else {
                    return ParseError.InvalidObjIdentifier;
                }
            },
            .lcurly => {
                i += 1;
                if (tokens[i] == .rcurly) {
                    return ParseError.InvalidColourIdentifier;
                }
                std.debug.print("Token: {}\n", .{tokens[i]});
                if (tokens[i] != .identifier) {
                    return ParseError.InvalidTokenOrder;
                }
                data.colour = tokens[i].identifier;
            },
            .identifier => |_| {},
            else => {},
        }
        i += 1;
    }

    return data;
}
