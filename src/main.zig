const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");
const logger = @import("logger.zig");

pub fn main() !void {
    const alloc: std.mem.Allocator = std.heap.page_allocator;
    const name = try get_file_name() orelse "";

    const lines = get_file(name, alloc) catch {
        try logger.Logger.log("Error reading file\n", logger.LogLevel.Error);
        return;
    } orelse unreachable;

    defer lines.deinit();

    var i: usize = 0;
    for (lines.items) |line| {
        std.debug.print("Line: {}\n", .{i});

        const tokens = lexer.lex(line, alloc) catch {
            std.debug.print("Could not lex\n", .{});
            return;
        };

        std.debug.print("Parsing line\n", .{});
        const output = parser.parse(tokens) catch |err| {
            switch (err) {
                parser.ParseError.InvalidTokenOrder => std.log.err("Unexpected Token Found, panicing", .{}),
                parser.ParseError.InvalidObjIdentifier => std.log.err("Invalid Object Identifier, panicing", .{}),
                parser.ParseError.InvalidColourIdentifier => std.log.err("Invalid Colour Identifier, panicing", .{}),
            }
            return;
        };

        if (output) |o| {
            std.debug.print("obj: {}\ncol: {?s}\n", .{ o.object, o.colour });
        }

        // Send to server if repl?
        // Store in file in not?
        i += 1;
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

fn get_file(name: []const u8, alloc: std.mem.Allocator) !?std.ArrayList([]const u8) {
    const max_line: usize = 4096;

    var file = std.fs.cwd().openFile(name, .{}) catch {
        return null;
    };

    defer file.close();

    var buff_reader = std.io.bufferedReader(file.reader());
    const reader = buff_reader.reader();
    var al: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(alloc);

    while (try reader.readUntilDelimiterOrEofAlloc(alloc, '\n', max_line)) |line| {
        try al.append(line);
    }

    return al;
}
