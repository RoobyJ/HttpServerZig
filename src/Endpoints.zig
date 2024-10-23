const std = @import("std");
const Request = @import("Models/Request.zig");
const Response = @import("Models/Response.zig");
const StatusCode = @import("Models/StatusCode.zig");

pub fn FirstEndpoint(request: Request.request) Response.response {
    std.debug.print("first endpoint {any}.\n", .{request});
    return Response.response{ .httpVersion = "HTTP/1.1", .connection = "close", .contentType = "application/json", .statusCode = StatusCode.statusCode.@"200 OK", .message = "FirstEndpoint" };
}

pub fn SecondEndpoint(request: Request.request) Response.response {
    std.debug.print("second endpoint {any}.\n", .{request});
    return Response.response{ .httpVersion = "HTTP/1.1", .connection = "close", .contentType = "application/json", .statusCode = StatusCode.statusCode.@"200 OK", .message = "SecondEndpoint" };
}

pub fn home(request: Request.request) Response.response {
    std.debug.print("home endpoint: {}\n", .{request});
    return Response.response{ .httpVersion = "HTTP/1.1", .connection = "close", .contentType = "application/json", .statusCode = StatusCode.statusCode.@"200 OK", .message = "<html>test nigger </html>" };
}
