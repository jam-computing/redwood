const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");
const logger = @import("logger.zig");
const Token = @import("token.zig").Token;

pub fn main() !u8 {
    const alloc: std.mem.Allocator = std.heap.page_allocator;
    const name = try get_file_name() orelse "";

    const file_lines = get_file(name, alloc) catch {
        try logger.Logger.log("Error reading file\n", logger.LogLevel.Error);
        return 1;
    } orelse {
        try logger.Logger.log("Error reading file\n", logger.LogLevel.Error);
        return 1;
    };

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

    if (output.kind) |kind| {
        const token_num = output.token_num;
        var token_counter: usize = token_num;
        var i: usize = 0;

        while (i < token_lines.items.len) : (i += 1) {
            const line = token_lines.items[i];

            if (line.len <= token_counter) {
                token_counter -= line.len;
                continue;
            }

            var underline = std.ArrayList(u8).init(alloc);
            defer underline.deinit();
            var word_num: usize = 0;
            var k: usize = 0;
            while (k < file_lines[i].len) : (k += 1) {
                if (file_lines[i][k] == ' ') {
                    word_num += 1;
                }

                if (word_num == token_counter and file_lines[i][k] != ' ') {
                    underline.append('^') catch {
                        continue;
                    };
                } else {
                    underline.append('~') catch {
                        continue;
                    };
                }
            }
            _ = underline.pop();

            // This is the line number
            std.debug.print("\x1B[31m{}\x1B[0m, on line {}\n", .{ kind, i + 1 });
            std.debug.print("{s}\x1B[32m{s}\x1B[0m\n", .{ file_lines[i], underline.items });
            break;
        }
    }

    if (output.nodes) |nodes| {
        for (nodes) |node| {
            std.debug.print("Node Object: {}, Node Colour: {?s}, Node Fn Count: {}\n", .{ node.object, node.colour, node.fns.count() });
            var iter = node.fns.iterator();
            while (iter.next()) |f| {
                std.debug.print("{}, \n", .{f});
            }
        }
    }
    return 0;
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
