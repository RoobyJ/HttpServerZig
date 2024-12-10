const std = @import("std");
const Request = @import("Models/Request.zig");
const Response = @import("Models/Response.zig");
const StatusCode = @import("Models/StatusCode.zig");
const Errors = @import("Errors.zig");
const Allocator = std.mem.Allocator;

pub fn FirstEndpoint(request: Request.request, _: std.StringHashMap([]const u8), _: Allocator) Errors.errors!Response.response {
    std.debug.print("first endpoint {any}.\n", .{request});
    return Response.response{ .httpVersion = "HTTP/1.1", .connection = "close", .contentType = "application/json", .statusCode = StatusCode.statusCode.@"200 OK", .message = "FirstEndpoint" };
}

pub fn SecondEndpoint(request: Request.request, _: std.StringHashMap([]const u8), _: Allocator) Errors.errors!Response.response {
    std.debug.print("second endpoint {any}.\n", .{request});
    return Response.response{ .httpVersion = "HTTP/1.1", .connection = "close", .contentType = "application/json", .statusCode = StatusCode.statusCode.@"200 OK", .message = "SecondEndpoint" };
}

pub fn home(_: Request.request, params: std.StringHashMap([]const u8), allocator: Allocator) Errors.errors!Response.response {
    const testId = params.get("testId");
    // add allocator for response message remember to free it after use!
    if (testId != null) std.debug.print("params key: testId, value: {?s}\n", .{testId});
    const message = try std.fmt.allocPrint(allocator, "<html><body>testId is:{?s}</body></html>", .{testId});
    return Response.response{ .httpVersion = "HTTP/1.1", .connection = "close", .contentType = "text/html", .statusCode = StatusCode.statusCode.@"200 OK", .message = message };
}
