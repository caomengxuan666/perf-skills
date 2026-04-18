# System Call Analysis with perf

## Overview

This guide focuses on analyzing system call overhead and identifying syscall bottlenecks using Linux `perf`.

## Quick Workflow

```bash
# Record syscalls only
perf record -p <PID> -g -e syscalls:sys_enter_* -o syscalls.data -- sleep 30

# Analyze syscall frequency
perf report --stdio -i syscalls.data -g none --sort symbol | head -50

# Interactive analysis
perf report -i syscalls.data -g graph
```

## Recording Syscalls

### Method 1: All Syscalls

```bash
# Record all syscalls (high overhead, use sparingly)
perf record -p <PID> -g -e 'syscalls:sys_enter_*' -o syscalls.data -- sleep 30
```

### Method 2: Specific Syscalls

```bash
# Record only file operations
perf record -p <PID> -g -e 'syscalls:sys_enter_read,syscalls:sys_enter_write,syscalls:sys_enter_openat' -o io.data -- sleep 30

# Record network operations
perf record -p <PID> -g -e 'syscalls:sys_enter_sendto,syscalls:sys_enter_recvfrom,syscalls:sys_enter_connect' -o net.data -- sleep 30
```

### Method 3: Use tracepoint (recommended)

```bash
# List available syscall tracepoints
perf list syscalls:sys_enter*

# Record common syscalls
perf record -p <PID> -g -e 'syscalls:sys_enter_write,syscalls:sys_enter_read,syscalls:sys_enter_epoll_wait' -o syscalls.data -- sleep 30
```

## Analyzing Syscall Overhead

### Step 1: Check Kernel vs User-Space Split

```bash
# Get overall split
perf report --stdio -i perf.data --sort dso -g none | head -20

# If kernel is >30%, investigate syscalls
```

### Step 2: Identify Hot Syscalls

```bash
# From full profile
perf report --stdio -i perf.data -g none | grep -E 'syscalls:|entry_SYSCALL'

# Or record syscalls specifically
perf report --stdio -i syscalls.data -g none --sort symbol | head -30
```

### Step 3: Trace to User-Space Caller

```bash
# Find user-space code making the syscall
perf report --stdio -i syscalls.data -g graph --max-stack 20 | grep -B 10 '<syscall_name>'

# Or use interactive mode
perf report -i syscalls.data -g graph
# Navigate: find syscall, press Enter to expand caller stack
```

## Common Syscall Bottlenecks

### 1. Write System Calls

**Symptoms:**
- High `syscalls:sys_enter_write`
- High `syscalls:sys_enter_writev`
- Many small writes

**Diagnosis:**
```bash
# Analyze write frequency
perf stat -e syscalls:sys_enter_write -p $PID -- sleep 10

# Find caller
perf report --stdio -i syscalls.data -g graph --symbol-filter 'sys_enter_write'
```

**Solutions:**

```cpp
// Bad: Many small writes
for (const auto& item : items) {
    write(fd, &item, sizeof(item));  // System call per item
}

// Good: Buffer and batch write
std::vector<Item> buffer;
for (const auto& item : items) {
    buffer.push_back(item);
    if (buffer.size() >= 1024) {
        write(fd, buffer.data(), buffer.size() * sizeof(Item));
        buffer.clear();
    }
}
// Final flush
if (!buffer.empty()) {
    write(fd, buffer.data(), buffer.size() * sizeof(Item));
}
```

### 2. Read System Calls

**Symptoms:**
- High `syscalls:sys_enter_read`
- High `syscalls:sys_enter_pread64`

**Diagnosis:**
```bash
# Analyze read patterns
perf report --stdio -i syscalls.data -g graph --symbol-filter 'sys_enter_read'

# Check read sizes (use strace for detail)
strace -p $PID -e read -s 0 -c
```

**Solutions:**

```cpp
// Bad: Read byte-by-byte
char c;
while (read(fd, &c, 1) > 0) {
    process(c);  // Syscall per byte
}

// Good: Read in chunks
char buffer[4096];
ssize_t bytes_read;
while ((bytes_read = read(fd, buffer, sizeof(buffer))) > 0) {
    for (int i = 0; i < bytes_read; i++) {
        process(buffer[i]);  // One syscall per 4KB
    }
}
```

### 3. epoll_wait (Network I/O)

**Symptoms:**
- High `syscalls:sys_enter_epoll_wait`
- Application appears blocked in epoll_wait

**Diagnosis:**
```bash
# Check epoll_wait duration
perf record -p $PID -g -e 'syscalls:sys_enter_epoll_wait' -o epoll.data -- sleep 30

# Analyze call sites
perf report --stdio -i epoll.data -g graph
```

**Solutions:**

```cpp
// Bad: epoll_pwait with timeout on every iteration
while (running) {
    int n = epoll_pwait(epoll_fd, events, MAX_EVENTS, 100, NULL);  // 100ms timeout
    // Process events
}

// Good: Infinite timeout, use timeout only for periodic tasks
while (running) {
    int n = epoll_pwait(epoll_fd, events, MAX_EVENTS, -1, NULL);  // Wait indefinitely
    // Process events
}

// Alternative: Edge-triggered mode
epoll_event ev;
ev.events = EPOLLIN | EPOLLET;  // Edge-triggered
epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fd, &ev);
```

### 4. Futex Calls (Lock Contention)

**Symptoms:**
- High `syscalls:sys_enter_futex`
- High `futex_wait`, `futex_wake`

**Diagnosis:**
```bash
# Record futex calls
perf record -p <PID> -g -e 'syscalls:sys_enter_futex' -o futex.data -- sleep 30

# Analyze contention
perf report --stdio -i futex.data -g graph
```

**Solutions:**

```cpp
// Bad: Coarse-grained lock holding
std::mutex mtx;
void process_items(const std::vector<Item>& items) {
    std::lock_guard<std::mutex> lock(mtx);  // Lock for entire function
    for (const auto& item : items) {
        // This could be parallelized
        heavy_computation(item);
    }
}

// Good: Minimize lock scope
void process_items(const std::vector<Item>& items) {
    std::vector<Result> results(items.size());
    // Only lock for critical section
    {
        std::lock_guard<std::mutex> lock(mtx);
        for (size_t i = 0; i < items.size(); i++) {
            results[i] = compute(items[i]);
        }
    }
    // Compute outside lock
    for (size_t i = 0; i < items.size(); i++) {
        heavy_computation(results[i]);
    }
}

// Better: Lock-free algorithms or per-thread data
```

### 5. mmap/munmap Calls

**Symptoms:**
- High `syscalls:sys_enter_mmap`
- High `syscalls:sys_enter_munmap`

**Diagnosis:**
```bash
# Analyze memory mapping
perf report --stdio -i syscalls.data -g graph --symbol-filter 'mmap'

# Check for frequent mmap/munmap
perf script -i syscalls.data | grep -c mmap
```

**Solutions:**

```cpp
// Bad: mmap/munmap per allocation
void* allocate(size_t size) {
    void* ptr = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    return ptr;
}
void deallocate(void* ptr, size_t size) {
    munmap(ptr, size);
}

// Good: Use allocator (mimalloc, jemalloc, tcmalloc)
// or implement memory pool
class MemoryPool {
    void* pool_;
    size_t size_;
public:
    MemoryPool(size_t size) : size_(size) {
        pool_ = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    }
    ~MemoryPool() {
        munmap(pool_, size_);
    }
    void* allocate(size_t size) {
        // Pool allocation, no syscall per alloc
    }
};
```

## Optimization Strategies

### 1. Batch Operations

Reduce syscall count by batching:

```cpp
// Bad: Individual operations
for (const auto& item : items) {
    send(fd, &item, sizeof(item), 0);  // Syscall per item
}

// Good: Batch send
std::vector<Item> batch;
for (const auto& item : items) {
    batch.push_back(item);
    if (batch.size() >= 1024) {
        send(fd, batch.data(), batch.size() * sizeof(Item), 0);
        batch.clear();
    }
}
```

### 2. Asynchronous I/O

Use non-blocking I/O with event loops:

```cpp
// Bad: Blocking I/O
int fd = open("file", O_RDONLY);
char buf[4096];
while (read(fd, buf, sizeof(buf)) > 0) {
    process(buf);  // Blocks on every read
}

// Good: Non-blocking I/O with epoll
int fd = open("file", O_RDONLY | O_NONBLOCK);
epoll_event ev;
ev.events = EPOLLIN;
ev.data.fd = fd;
epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fd, &ev);

// Event loop processes when data is ready
```

### 3. Use VDSO

Some syscalls are optimized via VDSO (no actual syscall):

- `gettimeofday`
- `clock_gettime`
- `getcpu`

These don't appear in syscall traces - they're user-space optimized.

### 4. Reduce Context Switches

High context switches often correlate with high syscalls:

```bash
# Check context switch rate
perf stat -e context-switches -p $PID -- sleep 10
```

Solutions:
- Use fewer threads
- Pin threads to cores (affinity)
- Use epoll/kqueue instead of many threads

## Measuring Syscall Performance

### Syscall Frequency

```bash
# Count syscalls per second
perf stat -e syscalls:sys_enter_* -p $PID -- sleep 10

# Or use strace for count
strace -p $PID -c -f
```

### Syscall Latency

```bash
# Measure time in syscalls
perf record -p $PID -g -e 'syscalls:sys_enter_*,syscalls:sys_exit_*' -o syscall-time.data -- sleep 30

# Analyze
perf report --stdio -i syscall-time.data -g graph
```

### Compare with Benchmark

```bash
# Measure baseline
perf record -p $PID -g -e cycles -o baseline.data -- sleep 30

# Optimize to reduce syscalls

# Measure improvement
perf record -p $PID -g -e cycles -o optimized.data -- sleep 30

# Compare
perf diff baseline.data optimized.data
```

## Common Mistakes

### 1. Ignoring syscall overhead

**Mistake:** "Syscalls are fast enough"

**Reality:** Each syscall has context switch overhead (~1-5μs). 1M syscalls = 1-5s overhead.

### 2. Optimizing the wrong thing

**Mistake:** Focusing on syscall itself

**Reality:** Reduce syscall frequency, not syscall speed. Syscall cost is mostly overhead, not function body.

### 3. Blocking on I/O

**Mistake:** Using blocking I/O in performance-critical paths

**Reality:** Use non-blocking I/O with event loops (epoll/kqueue) for scalability.

### 4. Lock contention masquerading as syscall overhead

**Mistake:** Blaming futex calls for slowness

**Reality:** Optimize lock usage, not futex. Contention is the real problem.

## Checklist

Before optimizing:
- [ ] Identified which syscalls are hot
- [ ] Traced to user-space caller
- [ ] Measured syscall frequency
- [ ] Checked if batching is possible

After optimizing:
- [ ] Reduced syscall count (not just time)
- [ ] Verified correctness with same workload
- [ ] Re-profiled to confirm improvement
- [ ] No regression in other metrics

## Advanced Tools

### strace

```bash
# Count syscalls
strace -c -p $PID

# Trace specific syscalls
strace -p $PID -e read,write -s 0

# Timestamp syscalls
strace -T -p $PID
```

### eBPF (advanced)

```bash
# Use bpftrace to trace syscalls
bpftrace -e 'tracepoint:syscalls:sys_enter_read { @[comm] = count(); }'

# More complex analysis
bpftrace -e 'tracepoint:syscalls:sys_enter_read { @[comm] = hist(args->count); }'
```

### perf stat

```bash
# Comprehensive syscall stats
perf stat -e syscalls:sys_enter_* -p $PID -- sleep 10

# Compare before/after
perf stat -e syscalls:sys_enter_write -p $PID -- sleep 10 > before.txt
# (optimize)
perf stat -e syscalls:sys_enter_write -p $PID -- sleep 10 > after.txt
diff before.txt after.txt
```
