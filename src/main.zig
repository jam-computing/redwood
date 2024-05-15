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
    };

    if (lines) |_| {} else {
        std.debug.print("File not found\n", .{});
        return;
    }

    defer lines.?.deinit();

    var file_bytes = std.ArrayList(u8).init(alloc);
    defer file_bytes.deinit();

    for (lines.?.items) |item| {
        try file_bytes.appendSlice(item);
    }

    const result = try file_bytes.toOwnedSlice();

    _ = lexer.lex(result, alloc) catch {
        std.debug.print("Could not lex\n", .{});
        return;
    };

    // [x] read in file
    // [x] lex
    // [ ] parse
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
