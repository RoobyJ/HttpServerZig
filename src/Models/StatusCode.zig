pub const statusCode = enum(u16) {
    @"200 OK" = 200,
    @"204 NoContent" = 204,
    @"401 Forbidden" = 401,
    @"404 BadRequest" = 404,
    @"500 InternalError" = 500
};
