const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");
const logger = @import("logger.zig");

pub fn main() !void {
    const name = try get_file_name() orelse "";

    const lines = get_file(name) catch {
        try logger.Logger.log("Error reading file\n", logger.LogLevel.Error);
        return;
    };

    if (lines) |_| {} else {
        std.debug.print("File not found\n", .{});
    }

    // read in file
    // lex
    // parse
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

fn get_file(name: []const u8) !?std.ArrayList([]const u8) {
    const alloc: std.mem.Allocator = std.heap.page_allocator;
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
