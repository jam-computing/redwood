pub const Token = union(enum) { one, two, three, four, five, six, seven, eight, nine, equals, space, newline, colon, semicolon, minus, plus, star, fslash, bslash, carot, percent, bang, andpercand, lbracket, rbracket, lcurly, rcurly, lsquare, rsquare, underscore, identifier: []const u8, none };
pub const Keyword = enum { plane };

const std = @import("std");

pub const ParseError = error{ InvalidTokenOrder, InvalidObjIdentifier, InvalidColourIdentifier };

const fn_data = struct { object: fn_object, colour: ?[]const u8 };
const fn_object = enum {
    none,
    plane,
    pub fn str_to_obj(str: []const u8) ?fn_object {
        if (std.mem.eql(u8, str, "plane")) {
            return fn_object.plane;
        }
        if (std.mem.eql(u8, str, "none")) {
            return fn_object.plane;
        }
        return null;
    }
};

pub fn parse(tokens: []const Token) ParseError!?fn_data {
    var i: usize = 0;
    var data: fn_data = fn_data{ .object = .none, .colour = null };
    while (i < tokens.len) {
        // std.debug.print("Token: {}\n", .{token});
        switch (tokens[i]) {
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
            else => {},
        }
        i += 1;
    }

    return data;
}
