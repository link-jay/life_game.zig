const std = @import("std");
const STDOUT = std.Io.File.stdout();
var prng = std.Random.DefaultPrng.init(122);
const rand = prng.random();

const Unit = struct {
    is_live: bool,
    pos: [2]usize,

    fn die(position: [2]usize) Unit {
        return .{ .is_live = false, .pos = position };
    }

    fn relive(position: [2]usize) Unit {
        return .{ .is_live = true, .pos = position };
    }

    fn create(position: [2]usize, status: bool) Unit {
        return .{ .is_live = status, .pos = position };
    }
};

const Game = struct {
    size: usize,
    refresh_time: usize,
    game: [][]Unit,

    fn new_place(heap: std.mem.Allocator, s: usize) ![][]Unit {
        var game = try heap.alloc([]Unit, s);
        for (0..s) |i| {
            game[i] = try heap.alloc(Unit, s);
        }
        return game;
    }

    fn delete_old_place(self: Game, heap: std.mem.Allocator) void {
        for (0..self.size) |i| {
            heap.free(self.game[i]);
        }
        heap.free(self.game);
    }

    fn init(heap: std.mem.Allocator, s: usize, t: usize) !Game {
        const game = try new_place(heap, s);
        var self: Game = .{ .size = s, .refresh_time = t, .game = game };
        for (0..self.size) |i| {
            for (0..self.size) |j| {
                // NOTE: 初始化is_live
                self.game[i][j] = Unit.create(.{ i, j }, rand.boolean());
            }
        }
        return self;
    }

    fn count_neighbors_center(self: Game, pos: [2]usize) usize {
        var count: u32 = 0;
        for (pos[0] - 1..pos[0] + 1) |x| {
            for (pos[1] - 1..pos[1] + 1) |y| {
                if (x == pos[0] and y == pos[1]) {
                    continue;
                }
                count += @intFromBool(self.game[x][y].is_live);
            }
        }
        return count;
    }

    fn count_neighbors_top_bottom(self: Game, pos: [2]usize) usize {
        var count: u32 = 0;
        if (pos[1] == 0) {
            for (pos[0] - 1..pos[0] + 1) |x| {
                for (pos[1]..pos[1] + 1) |y| {
                    if (x == pos[0] and y == pos[1]) {
                        continue;
                    }
                    count += @intFromBool(self.game[x][y].is_live);
                }
            }
        } else {
            for (pos[0] - 1..pos[0] + 1) |x| {
                for (pos[1] - 1..pos[1]) |y| {
                    if (x == pos[0] and y == pos[1]) {
                        continue;
                    }
                    count += @intFromBool(self.game[x][y].is_live);
                }
            }
        }
        return count;
    }

    fn count_neighbors_left_right(self: Game, pos: [2]usize) usize {
        var count: u32 = 0;
        if (pos[0] == 0) {
            for (pos[0]..pos[0] + 1) |x| {
                for (pos[1] - 1..pos[1] + 1) |y| {
                    if (x == pos[0] and y == pos[1]) {
                        continue;
                    }
                    count += @intFromBool(self.game[x][y].is_live);
                }
            }
        } else {
            for (pos[0] - 1..pos[0]) |x| {
                for (pos[1] - 1..pos[1] + 1) |y| {
                    if (x == pos[0] and y == pos[1]) {
                        continue;
                    }
                    count += @intFromBool(self.game[x][y].is_live);
                }
            }
        }
        return count;
    }

    fn count_neighbors_left_top(self: Game, pos: [2]usize) usize {
        var count: u32 = 0;
        for (pos[0]..pos[0] + 1) |x| {
            for (pos[1]..pos[1] + 1) |y| {
                if (x == pos[0] and y == pos[1]) {
                    continue;
                }
                count += @intFromBool(self.game[x][y].is_live);
            }
        }
        return count;
    }

    fn count_neighbors_right_top(self: Game, pos: [2]usize) usize {
        var count: u32 = 0;
        for (pos[0] - 1..pos[0]) |x| {
            for (pos[1]..pos[1] + 1) |y| {
                if (x == pos[0] and y == pos[1]) {
                    continue;
                }
                count += @intFromBool(self.game[x][y].is_live);
            }
        }
        return count;
    }

    fn count_neighbors_left_bottom(self: Game, pos: [2]usize) usize {
        var count: u32 = 0;
        for (pos[0]..pos[0] + 1) |x| {
            for (pos[1] - 1..pos[1]) |y| {
                if (x == pos[0] and y == pos[1]) {
                    continue;
                }
                count += @intFromBool(self.game[x][y].is_live);
            }
        }
        return count;
    }

    fn count_neighbors_right_bottom(self: Game, pos: [2]usize) usize {
        var count: u32 = 0;
        for (pos[0] - 1..pos[0]) |x| {
            for (pos[1] - 1..pos[1]) |y| {
                if (x == pos[0] and y == pos[1]) {
                    continue;
                }
                count += @intFromBool(self.game[x][y].is_live);
            }
        }
        return count;
    }

    fn check_live(self: Game, unit: Unit, new_game: *[][]Unit) void {
        var count: usize = undefined;
        const x = unit.pos[0];
        const y = unit.pos[1];
        if (x == 0 and y == 0) {
            count = count_neighbors_left_top(self, unit.pos);
        } else if (x == self.size and y == 0) {
            count = count_neighbors_right_top(self, unit.pos);
        } else if (x == 0 and y == self.size) {
            count = count_neighbors_left_bottom(self, unit.pos);
        } else if (x == self.size and y == self.size) {
            count = count_neighbors_right_bottom(self, unit.pos);
        } else if (x == 0 or x == self.size) {
            count = count_neighbors_left_right(self, unit.pos);
        } else if (y == 0 or y == self.size) {
            count = count_neighbors_top_bottom(self, unit.pos);
        } else {
            count = count_neighbors_center(self, unit.pos);
        }
        if (unit.is_live) {
            if (count == 2 or count == 3) {
                new_game.*[x][y] = Unit.create(.{ x, y }, true);
            } else {
                new_game.*[x][y] = Unit.die(.{ x, y });
            }
        } else {
            if (count == 3) {
                new_game.*[x][y] = Unit.relive(.{ x, y });
            } else {
                new_game.*[x][y] = Unit.die(.{ x, y });
            }
        }
    }

    fn check_lives(self: *Game, heap: std.mem.Allocator) void {
        var new_game = new_place(heap, self.size) catch {
            self.delete_old_place(heap);
            std.debug.print("new_place error.\n", .{});
            std.process.exit(1);
        };
        for (0..self.size) |i| {
            for (0..self.size) |j| {
                check_live(self.*, self.game[i][j], &new_game);
            }
        }
        self.delete_old_place(heap);
        self.game = new_game;
    }

    fn start(self: *Game, drawer: *std.Io.File.Writer, proginit: std.process.Init) void {
        defer drawer.flush() catch {
            self.delete_old_place(proginit.gpa);
            std.debug.print("Game start error.\n", .{});
            std.process.exit(1);
        };
        var is_over: bool = false;
        _ = drawer.interface.write("\x1b[s") catch {
            self.delete_old_place(proginit.gpa);
            std.debug.print("terminal reflush error.\n", .{});
            std.process.exit(1);
        };
        while (!is_over) {
            _ = drawer.interface.write("\x1b[u") catch {
                self.delete_old_place(proginit.gpa);
                std.debug.print("terminal reflush error.\n", .{});
                std.process.exit(1);
            };
            is_over = true;
            for (self.game) |line| {
                for (line) |unit| {
                    if (unit.is_live == true) {
                        is_over = false;
                        _ = drawer.interface.write("# ") catch {
                            self.delete_old_place(proginit.gpa);
                            std.debug.print("print # error.\n", .{});
                            std.process.exit(1);
                        };
                    } else {
                        _ = drawer.interface.write("* ") catch {
                            self.delete_old_place(proginit.gpa);
                            std.debug.print("print * error.\n", .{});
                            std.process.exit(1);
                        };
                    }
                }
                _ = drawer.interface.write("\n") catch {
                    self.delete_old_place(proginit.gpa);
                    std.debug.print("print \\n error.\n", .{});
                    std.process.exit(1);
                };
            }
            drawer.flush() catch {
                self.delete_old_place(proginit.gpa);
                std.debug.print("flush error.\n", .{});
                std.process.exit(1);
            };
            proginit.io.sleep(.fromSeconds(1), .real) catch {
                self.delete_old_place(proginit.gpa);
                std.debug.print("sleep error.\n", .{});
                std.process.exit(1);
            };
            self.check_lives(proginit.gpa);
        }
    }

    fn over(self: Game, heap: std.mem.Allocator) void {
        std.debug.print("Game over\n", .{});
        self.delete_old_place(heap);
    }
};

pub fn main(init: std.process.Init) !void {
    var output_buf: [1024]u8 = undefined;
    var stdout = STDOUT.writer(init.io, &output_buf);
    var the_game = Game.init(init.gpa, 16, 1) catch {
        std.debug.print("Game init error, perhaps the error of new_place.\n", .{});
        std.process.exit(1);
    };
    defer the_game.over(init.gpa);
    the_game.start(&stdout, init);
}
