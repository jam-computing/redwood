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

    const file_lines = get_file(names[0], alloc) catch {
        try logger.Logger.log("Error reading file\n", logger.LogLevel.Error);
        return 1;
    } orelse {
        try logger.Logger.log("Error reading file\n", logger.LogLevel.Error);
        return 1;
    };

    if (names.len > 1) {
        _ = get_file(names[1], alloc) catch {
            try logger.Logger.log("Error reading file\n", logger.LogLevel.Error);
            return 1;
        } orelse {
            try logger.Logger.log("Error reading file\n", logger.LogLevel.Error);
            return 1;
        };
    }

    var token_lines = std.ArrayList([]const Token).init(alloc);
    defer token_lines.deinit();

    for (file_lines) |line| {
        try token_lines.append(lexer.lex(line, alloc) catch {
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

    err.report_compiletime_err(output, file_lines, token_lines, names[0], alloc);

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

            _ = compiler.compile_node(&n, &output.imports.?, &output.frame_count) catch {
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
