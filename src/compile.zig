const std = @import("std");
const node = @import("node.zig").node;
const method = @import("node.zig").method;

const stdlib = @import("stdlib.zig");

const iden_value_pair = struct {
    iden: []const u8,
    value: isize,
};

pub fn compile_node(_node: *const node, imports: *const std.StringHashMap(stdlib.imports), leds: *const [][]const u8, count: *const usize) !void {
    const alloc = std.heap.page_allocator;

    std.debug.print("Compiling node for {} frames\n", .{count.*});

    var iter = imports.*.iterator();

    for (0..count.*) |i| {
        var iden_value = std.ArrayList(iden_value_pair).init(alloc);
        defer iden_value.deinit();
        while (iter.next()) |e| {
            iden_value.append(.{ .iden = e.key_ptr.*, .value = @intCast(i) }) catch {
                continue;
            };
        }
        _ = compile_frame(_node, &iden_value.items, leds);
    }
}

fn compile_frame(_: *const node, _: *[]iden_value_pair, _: *const [][]const u8) ?[]const u8 {
    std.debug.print("Compiling frame.\n", .{});
    return "";
}
