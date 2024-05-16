const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");
const logger = @import("logger.zig");

pub fn main() !void {
    const alloc: std.mem.Allocator = std.heap.page_allocator;
    const name = try get_file_name() orelse "";

    const file_text = get_file(name, alloc) catch {
        try logger.Logger.log("Error reading file\n", logger.LogLevel.Error);
        return;
    } orelse unreachable;

    defer alloc.free(file_text);

    std.debug.print("{s}\n", .{file_text});

    const tokens = lexer.lex(file_text, alloc) catch {
        std.debug.print("Could not lex\n", .{});
        return;
    };

    std.debug.print("Token Count: {}\n", .{tokens.len});

    const output = parser.parse(tokens, alloc) catch |err| {
        switch (err) {
            parser.ParseError.InvalidTokenOrder => std.log.err("Unexpected Token Found, panicing", .{}),
            parser.ParseError.InvalidObjIdentifier => std.log.err("Invalid Object Identifier, panicing", .{}),
            parser.ParseError.InvalidColourIdentifier => std.log.err("Invalid Colour Identifier, panicing", .{}),
            parser.ParseError.InvalidImport => std.log.err("Import of value that does not exist, panicing", .{}),
            parser.ParseError.InvalidImportLen => std.log.err("Import alias too long, should only be one char", .{}),
            else => std.log.err("Error not handled. Panicing", .{}),
        }
        return;
    };

    if (output) |nodes| {
        for (nodes) |node| {
            std.debug.print("Node Object: {}, Node Colour: {?s}\n", .{ node.object, node.colour });
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

fn get_file(name: []const u8, alloc: std.mem.Allocator) !?[]const u8 {
    var file = std.fs.cwd().openFile(name, .{}) catch {
        return null;
    };

    defer file.close();

    var buff_reader = std.io.bufferedReader(file.reader());
    const reader = buff_reader.reader();

    var buf = std.ArrayList(u8).init(alloc);
    while (try reader.readUntilDelimiterOrEofAlloc(alloc, '\n', 4096)) |line| {
        try buf.appendSlice(line.ptr[0..line.len]);
        try buf.append(' ');
    }
    return buf.items;
}
