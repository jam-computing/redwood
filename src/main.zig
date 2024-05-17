const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");
const logger = @import("logger.zig");
const Token = @import("token.zig").Token;

pub fn main() !void {
    const alloc: std.mem.Allocator = std.heap.page_allocator;
    const name = try get_file_name() orelse "";

    const file_lines = get_file(name, alloc) catch {
        try logger.Logger.log("Error reading file\n", logger.LogLevel.Error);
        return;
    } orelse unreachable;

    var token_lines = std.ArrayList([]const Token).init(alloc);
    defer token_lines.deinit();

    for (file_lines) |line| {
        try token_lines.append(lexer.lex(line, alloc) catch {
            std.debug.print("Could not lex\n", .{});
            return;
        });
    }

    var tokens = std.ArrayList(Token).init(alloc);
    defer tokens.deinit();

    for (token_lines.items) |line| {
        for (line) |t| {
            try tokens.append(t);
        }
    }

    const output = parser.parse(try tokens.toOwnedSlice(), alloc) catch |err| {
        switch (err) {
            parser.ParseError.InvalidTokenOrder => std.log.err("Unexpected Token Found, panicing", .{}),
            parser.ParseError.InvalidObjIdentifier => std.log.err("Invalid Object Identifier, panicing", .{}),
            parser.ParseError.InvalidColourIdentifier => std.log.err("Invalid Colour Identifier, panicing", .{}),
            parser.ParseError.InvalidImport => std.log.err("Import of value that does not exist, panicing", .{}),
            parser.ParseError.InvalidImportLen => std.log.err("Import alias too long, should only be one char", .{}),
            parser.ParseError.InvalidNodeIdentifier => std.log.err("Node name is invalid or already taken", .{}),
            else => std.log.err("Error not handled. Panicing", .{}),
        }
        return;
    };

    if (output) |nodes| {
        for (nodes) |node| {
            std.debug.print("Node Object: {}, Node Colour: {?s}, Node Fn Count: {}\n", .{ node.object, node.colour, node.fns.count() });
            var iter = node.fns.iterator();
            while (iter.next()) |f| {
                std.debug.print("{}, \n", .{f});
            }
        }
    } else {
        std.debug.print("No output\n", .{});
    }
}

fn get_file_name() !?[]const u8 {
    var args = std.process.args();

    var i: u8 = 0;
    while (args.next()) |arg| {
        if (i == 1) {
            return arg;
        }
        i += 1;
    }
    return null;
}

fn get_file(name: []const u8, alloc: std.mem.Allocator) !?[][]const u8 {
    var file = std.fs.cwd().openFile(name, .{}) catch {
        return null;
    };

    defer file.close();

    var buff_reader = std.io.bufferedReader(file.reader());
    const reader = buff_reader.reader();

    var buf = std.ArrayList([]const u8).init(alloc);
    defer buf.deinit();
    while (try reader.readUntilDelimiterOrEofAlloc(alloc, '\n', 4096)) |line| {
        var wnline = try alloc.alloc(u8, line.len + 1);
        std.mem.copyForwards(u8, wnline[0..line.len], line);
        wnline[line.len] = '\n';
        try buf.append(wnline);
    }
    return try buf.toOwnedSlice();
}
