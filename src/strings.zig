const std = @import("std");

pub const Str = struct {
    start: u32, //Inclusive
    end: u32,   //Exclusive
    backer: [] const u8,

    pub fn FromSlice(slice: [] const u8) Str {
        return Str{.start = 0, .end = @intCast(slice.len), .backer = slice};
    }

    pub fn Error(self: Str, comptime fmt: []const u8, args: anytype) void {
        if (self.start > self.end){
            @panic("Str has start after end");
        }
        var linestart: u32 = 0;
        var linenum: u32 = 0;
        for (0..self.start) |i| {
            const char = self.backer[i];
            if (char == '\n' or char == '\r') {
                linestart = @intCast(i+1);
            }
            linenum += @intFromBool(char == '\n');
        }
        var lineend = linestart;
        while (lineend < self.backer.len and !(self.backer[lineend] == '\r' or self.backer[lineend] == '\n')) : (lineend += 1){}
        std.debug.print("Error on line: {}, col: {}\n\t{s}\n", .{linenum+1, self.start-linestart+1, self.backer[linestart..lineend]});
        const spad = (" " ** 256)[0..self.start-linestart];
        const curly = ("~" ** 256)[0..self.end-self.start];
        std.debug.print("\t{s}{s}\n", .{spad, curly});
        std.debug.print(fmt, args);
    }

    pub fn format(self: Str, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        return writer.print("Str{{ {}-{}: \"{s}\" }}", .{ self.start, self.end, self.backer[self.start..self.end] });
    }

    pub fn Copy(self: *Str) Str {
        return self.*;
    }

    pub fn NewReader(self: Str) Str {
        return Str{.start = self.start, .end = self.start, .backer = self.backer};
    }

    pub fn FromEndOf(self: *Str, other: Str) void {
        self.start = other.end;
    }

    pub fn PeekChar(self: *Str) !u8 {
        if (self.start >= self.end){
            return error.PeekEmptyStr;
        }
        if(self.start >= self.backer.len){
            return '\x00';
        }
        return self.backer[self.start];
    }

    pub fn PeekEnd(self: Str) u8 {
        if(self.end >= self.backer.len){
            return '\x00';
        }
        return self.backer[self.end-1];
    }

    pub fn PopChar(self: *Str) !void {
        if (self.start >= self.end){
            return error.PopEmptyStr;
        }
        self.start += 1;
    }

    pub fn CanPop(self: Str) bool {
        return self.start < self.end;
    }

    pub fn RollBack(self: *Str) void {
        self.start -= 1;
    }

    pub fn PopAmt(self: *Str, amt: u32) !void {
        if ((self.start + amt) > self.end){
            return error.PopEmptyStr;
        }
        self.start += amt;
    }

    pub fn PeekNext(self: *Str) u8 {
        if(self.end >= self.backer.len) {
            return '\x00';
        }
        return self.backer[self.end];
    }

    pub fn IndexStart(self: Str, idx: u32) u8 {
        if (self.start + idx >= self.end or self.start + idx >= self.backer.len) {
            return '\x00';
        }
        return self.backer[self.start + idx];
    }

    pub fn ReadNext(self: *Str) void {
        self.end += 1;
    }

    pub fn ReadAmt(self: *Str, amt: u32) void {
        self.end += amt;
    }

    pub fn CanRead(self: Str) bool {
        return self.end < self.backer.len;
    }

    pub fn ReleaseEnd(self: *Str) void {
        self.end -= 1;
    }

    pub fn CountReadAll(self: *Str, validator: fn(u8) bool) !u32 {
        var amt: u32 = 0;
        while (validator(try self.PeekChar())) {
            amt += 1;
            try self.PopChar();
        }
        return amt;
    }

    pub fn ReadAll(self: *Str, validator: fn(u8) bool) void {
        while (validator(self.PeekNext())) {
            self.ReadNext();
        }
    }

    pub fn PadAtEnd(self: *Str) !void {
        if(self.end >= self.backer.len) {
            self.end += 1;
        } else {
            return error.SliceDoesNotContainEnd;
        }
    }
};

pub fn IsWS(char: u8) bool {
    return switch (char) {
        ' ' => true,
        '\t' => true,
        '\n' => true,
        '\r' => true,
        else => false,
    };
}

pub fn IsUAN(char: u8) bool {
    return switch (char) {
        '_' => true,
        'a'...'z' => true,
        'A'...'Z' => true,
        '0'...'9' => true,
        else => false,
    };
}

pub fn IsUN(char: u8) bool {
    return switch (char) {
        '_' => true,
        '0'...'9' => true,
        else => false,
    };
}

pub fn IsN(char: u8) bool {
    return switch (char) {
        '0'...'9' => true,
        else => false,
    };
}

pub fn IsUA(char: u8) bool {
    return switch (char) {
        '_' => true,
        'a'...'z' => true,
        'A'...'Z' => true,
        else => false,
    };
}