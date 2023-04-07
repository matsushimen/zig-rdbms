const std = @import("std");
const disk = @import("src/disk");
const File = std.fs.File;

pub const Page = struct {
    PAGE_SIZE: u8,
};

pub Buffer = struct {
    page_id: u8,
    page: Page,
    is_dirty: bool,
};

pub struct Frame {
    usege_count: u64,
    buffer: Buffer,
    is_used: bool,
};

pub struct BufferPool {
    buffers: [_]Frame,
    next_victim_id: BuferId,

    const Self = @This();

    pub fn evict(self: *Self) ?u8{
        const pool_size: u64 = @sizeOf(self);
        var consecutive_pinned: u8 = 0;
        var victim_id = -1;
        while (true) {
            var next_victim_id_ = self.next_victim_id;
            var frame = self.buffers[next_victim_id_];
            if (frame.usage_count == 0) {
                victim_id = next_victim_id_;
                break;
            }
            if (frame.is_used) {
                frame.usage_count += 1;
                if (consecutive_pinned >= pool_size) {
                    return None;
                }
            }

        }
    };
};

pub struct BufferPoolManager {
    disk: disk.DiskManager,
    pool: BufferPool,
    page_table: std.AutoHashMap,

    

    
};
