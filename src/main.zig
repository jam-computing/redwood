const std = @import("std");
const stdlib = @import("stdlib.zig");

const lexer = @import("lexer.zig");
const parser = @import("parser.zig");

const logger = @import("logger.zig");
const err = @import("error.zig");

const Token = @import("token.zig").Token;

const compiler = @import("compile.zig");

pub fn main() !u8 {
    const alloc: std.mem.Allocator = std.heap.page_allocator;
    const names = try get_file_names(alloc) orelse unreachable;

    if (names.len != 2) {
        std.debug.print("Oopsies. Please provide the correct files\n", .{});
    }

    const file_lines = get_files(&names[0], &names[1], &alloc) catch {
        try logger.Logger.log("Error reading file\n", logger.LogLevel.Error);
        return 1;
    } orelse {
        try logger.Logger.log("Error reading file\n", logger.LogLevel.Error);
        return 1;
    };

    var token_lines = std.ArrayList([]const Token).init(alloc);
    defer token_lines.deinit();

    for (file_lines) |line| {
        try token_lines.append(lexer.lex(line[0], alloc) catch {
            std.debug.print("Could not lex\n", .{});
            return 1;
        });
    }

    var tokens = std.ArrayList(Token).init(alloc);
    defer tokens.deinit();

    for (token_lines.items) |line| {
        for (line) |t| {
            try tokens.append(t);
        }
    }

    const output = parser.parse(try tokens.toOwnedSlice(), alloc);

    err.report_compiletime_err(output, file_lines[0], token_lines, names[0], alloc);

    // debug info
    if (false) {
        if (output.values) |values| {
            for (values) |value| {
                if (value.type == .node) {
                    std.debug.print("[{s}]: {}, {}\n", .{ value.name, value.type.node.object, value.type.node.fns.?.count() });
                } else if (value.type == .vector3) {
                    std.debug.print("[{s}]: {}\n", .{ value.name, value.type.vector3 });
                } else {
                    std.debug.print("[{s}]: {}\n", .{ value.name, value.type });
                }
            }
            std.debug.print("Frame Count: {}\n", .{output.frame_count});
        }
    }

    if (output.values) |values| {
        for (values) |value| {
            if (value.type != stdlib._type.node) {
                continue;
            }

            const n = value.type.node;

            _ = compiler.compile_node(&n, &output.imports.?, &file_lines[1], &output.frame_count) catch {
                continue;
            };
        }
    }

    return 0;
}

fn get_file_names(alloc: std.mem.Allocator) !?[][]const u8 {
    var args = std.process.args();

    var i: u8 = 0;
    var list = std.ArrayList([]const u8).init(alloc);
    defer list.deinit();
    while (args.next()) |arg| {
        if (i == 1) {
            if (std.mem.containsAtLeast(u8, arg, 1, ".rw")) {
                try list.append(arg);
            } else {
                std.debug.print("Please specify a file path.\n", .{});
                return null;
            }
        }
        if (i == 2) {
            if (std.mem.containsAtLeast(u8, arg, 1, ".json")) {
                try list.append(arg);
            }
        }

        i += 1;
    }
    return try list.toOwnedSlice();
}

fn get_files(source_name: *const []const u8, led_name: *const []const u8, alloc: *const std.mem.Allocator) !?[2][][]const u8 {
    var source_file = std.fs.cwd().openFile(source_name.*, .{}) catch {
        return null;
    };

    var led_file = std.fs.cwd().openFile(led_name.*, .{}) catch {
        return null;
    };

    defer source_file.close();
    defer led_file.close();

    var source_buf_reader = std.io.bufferedReader(source_file.reader());
    const source_reader = source_buf_reader.reader();

    var source_buf = std.ArrayList([]const u8).init(alloc.*);
    defer source_buf.deinit();

    while (try source_reader.readUntilDelimiterOrEofAlloc(alloc.*, '\n', 4096)) |line| {
        var wnline = try alloc.alloc(u8, line.len + 1);
        std.mem.copyForwards(u8, wnline[0..line.len], line);
        wnline[line.len] = '\n';
        try source_buf.append(wnline);
    }

    var led_buf_reader = std.io.bufferedReader(source_file.reader());
    const led_reader = led_buf_reader.reader();

    var led_buf = std.ArrayList([]const u8).init(alloc.*);
    defer led_buf.deinit();

    while (try led_reader.readUntilDelimiterOrEofAlloc(alloc.*, '\n', 4096)) |line| {
        var wnline = try alloc.alloc(u8, line.len + 1);
        std.mem.copyForwards(u8, wnline[0..line.len], line);
        wnline[line.len] = '\n';
        try source_buf.append(wnline);
    }

    return [2][][]const u8{
        try source_buf.toOwnedSlice(),
        try led_buf.toOwnedSlice(),
    };
}
