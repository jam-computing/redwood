const std = @import("std");

pub const LogLevel = enum {
    Info,
    Error,
};

pub const Logger = struct {
    level: LogLevel = .Info,

    pub fn info(self: *Logger, message: []const u8) void {
        self.log(.Info, message);
    }

    pub fn err(self: *Logger, message: []const u8) void {
        self.log(.Error, message);
    }

    pub fn log(message: []const u8, level: LogLevel) !void {
        var stdout = std.io.getStdOut().writer();
        switch (level) {
            .Info => {
                try stdout.print("\x1B[32m[INFO] ", .{}); // Green for Info
            },
            .Error => {
                try stdout.print("\x1B[31m[ERROR] ", .{}); // Red for Error
            },
        }
        try stdout.print("{s}\x1B[0m\n", .{message});
    }
};
