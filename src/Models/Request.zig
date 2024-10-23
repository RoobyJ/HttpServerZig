const HttpHeader = @import("HttpHeader.zig");

pub const request = struct {
    header: HttpHeader.httpHeader,
    body: []const u8
};
