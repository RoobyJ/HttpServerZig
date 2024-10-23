const StatusCode = @import("StatusCode.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const response = struct {
    httpVersion: []const u8,
    connection: []const u8,
    contentType: []const u8,
    statusCode: StatusCode.statusCode,
    message: []const u8,

    pub fn getResponseHeader(self: response, allocator: Allocator) ![]const u8 {
        const httpHead = try std.fmt.allocPrint(
            allocator,
            "{s} {s} \r\n" ++
                "Connection: {s}\r\n" ++
                "Content-Type: {s}\r\n" ++
                "Content-Length: {d}\r\n" ++
                "\r\n",
            .{ self.httpVersion, @tagName(self.statusCode), self.connection, self.contentType, self.message.len },
        );
        return httpHead;
    }
};
