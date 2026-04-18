# CPU Hotspot Analysis with perf

## Overview

This guide focuses on identifying and optimizing CPU hotspots using Linux `perf`.

## Quick Workflow

```bash
# 1. Record
perf record -p <PID> -g -o perf.data -- sleep 30

# 2. Interactive analysis (start here)
perf report -i perf.data -g graph

# 3. Flat profile for top functions
perf report --stdio -i perf.data -g none --sort symbol | head -50

# 4. Annotate source if available
perf annotate -i perf.data <function>
```

## Understanding the Output

### perf report Columns

| Column | Meaning | Priority |
|--------|---------|----------|
| Overhead | % of samples in this function | High |
| Self% | Samples directly in this function | **Most important** |
| Children% | Samples in this function + callees | Low (misleading) |
| Command | Process name | Context |
| Shared Object | Library/DSO | Context |
| Symbol | Function name | Context |

### Interpreting Overhead

- **< 1%**: Ignore (noise)
- **1-5%**: Minor hotspot, optimize if easy
- **5-10%**: Moderate hotspot, worth investigating
- **10-20%**: Major hotspot, prioritize optimization
- **> 20%**: Critical hotspot, focus all effort here

### Self% vs Children%

```bash
# Self% - actual CPU time in this function
perf report --stdio -i perf.data -g none | head -20

# Children% - includes all callees (misleading)
perf report --stdio -i perf.data -g graph | head -20
```

**Rule:** Always prioritize by Self%. Children% is cumulative and can mislead.

## Hotspot Investigation Steps

### Step 1: Identify Top Hotspots

```bash
# Get top 20 by Self%
perf report --stdio -i perf.data -g none --sort symbol | head -20
```

### Step 2: Classify the Hotspot

Ask: Is this function:
- **My code?** → Optimize directly
- **Library code?** → Trace back to caller
- **System call?** → Find user-space trigger
- **Generated code?** → Check compiler flags

### Step 3: Trace the Call Chain

```bash
# Interactive mode - navigate up the stack
perf report -i perf.data -g graph

# Or use text mode
perf report --stdio -i perf.data -g graph --max-stack 20 | grep -A 10 '<hotspot>'
```

Look for:
- Your application namespace/prefix
- Specific user-space functions making the call
- Multiple call sites (which one is the primary?)

### Step 4: Analyze the Code

```bash
# If debug symbols available, annotate source
perf annotate -i perf.data <hotspot_function>

# Or use GDB to inspect the function
gdb <app>
(gdb) disassemble <hotspot_function>
```

## Common Hotspot Patterns

### Pattern 1: String Operations

**Symptoms:**
- High `strlen`, `strcmp`, `strcpy`, `memcpy`
- Many calls to string utilities

**Solutions:**
```cpp
// Bad: Repeated strlen in loop
for (int i = 0; i < strlen(s); i++) { ... }

// Good: Cache length
size_t len = strlen(s);
for (int i = 0; i < len; i++) { ... }

// Better: Use std::string_view (C++17)
std::string_view sv(s);
for (char c : sv) { ... }
```

### Pattern 2: Frequent Allocation/Free

**Symptoms:**
- High `operator new`, `malloc`, `free`
- Many small allocations

**Solutions:**
- Use object pools
- Pre-allocate buffers
- Use arena allocators
- Reduce allocation frequency

### Pattern 3: Repeated Computations

**Symptoms:**
- Same calculation in loop
- Expensive function called repeatedly

**Solutions:**
```cpp
// Bad: Recompute every iteration
for (int i = 0; i < n; i++) {
    double val = expensive_computation(i);
    // ...
}

// Good: Cache results
std::unordered_map<int, double> cache;
for (int i = 0; i < n; i++) {
    double val;
    auto it = cache.find(i);
    if (it != cache.end()) {
        val = it->second;
    } else {
        val = expensive_computation(i);
        cache[i] = val;
    }
    // ...
}
```

### Pattern 4: Unnecessary Copies

**Symptoms:**
- High `memcpy`, `memmove`
- Large data structures copied

**Solutions:**
```cpp
// Bad: Pass by value (copy)
void process(std::vector<int> data) { ... }

// Good: Pass by reference
void process(const std::vector<int>& data) { ... }

// Better: Use std::span (C++20)
void process(std::span<int> data) { ... }
```

### Pattern 5: Inefficient Data Structures

**Symptoms:**
- High `std::map::find` or `std::set::find`
- Linear search in large containers

**Solutions:**
- Use `std::unordered_map` for O(1) lookup
- Use `std::vector` + binary search for small data
- Consider sorting + binary search

## Algorithmic Improvements

### Before Optimizing Micro-Optimizations

1. **Check algorithm complexity**
   - O(n²) vs O(n log n) vs O(n)
   - Nested loops are usually the culprit

2. **Reduce loop iterations**
   - Early exit conditions
   - Loop unrolling (usually compiler does this)

3. **Cache-friendly access**
   - Sequential memory access
   - Structure of Arrays (SoA) vs Array of Structures (AoS)

### Example: Optimizing a Hot Loop

```cpp
// Before: O(n²) hotspot
void process_data(const std::vector<Item>& items) {
    for (const auto& item : items) {           // O(n)
        for (const auto& other : items) {       // O(n)
            if (item.id == other.id) {          // O(n²) total
                // process
            }
        }
    }
}

// After: O(n) with lookup table
void process_data(const std::vector<Item>& items) {
    std::unordered_map<int, const Item*> lookup;
    for (const auto& item : items) {           // O(n)
        lookup[item.id] = &item;
    }

    for (const auto& item : items) {           // O(n)
        auto it = lookup.find(item.id);         // O(1)
        if (it != lookup.end()) {
            // process
        }
    }
    // Total: O(n) vs O(n²)
}
```

## Compiler Optimizations

### Check Compiler Flags

```bash
# Check if optimized
nm <app> | grep <function>

# Use readelf to see optimization level
readelf -n <app> | grep GCC
```

### Recommended Flags

```cmake
# CMake
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
set(CMAKE_BUILD_TYPE RelWithDebInfo)

# Manual
g++ -O3 -march=native -g -o app app.cpp
```

### Profile-Guided Optimization (PGO)

```bash
# Step 1: Compile with profiling
g++ -O2 -fprofile-generate -g -o app_pgo app.cpp

# Step 2: Run with representative workload
./app_pgo <workload>

# Step 3: Re-compile with profile data
g++ -O2 -fprofile-use -g -o app app.cpp

# Result: 5-15% improvement typical
```

## Validation

### Re-profile After Changes

```bash
# Before optimization
perf record -p $PID -g -o before.data -- sleep 15
perf report --stdio -i before.data -g none > before.txt

# Make code changes, recompile

# After optimization
perf record -p $NEW_PID -g -o after.data -- sleep 15
perf report --stdio -i after.data -g none > after.txt

# Compare
diff before.txt after.txt
```

### Performance Regression Testing

```bash
# Script for automated testing
#!/bin/bash
TARGET_PCT=10  # Expect 10% improvement

BEFORE=$(grep <hotspot> before.txt | awk '{print $1}' | tr -d '%')
AFTER=$(grep <hotspot> after.txt | awk '{print $1}' | tr -d '%')

IMPROVEMENT=$(echo "scale=2; ($BEFORE - $AFTER) / $BEFORE * 100" | bc)
echo "Improvement: ${IMPROVEMENT}%"

if (( $(echo "$IMPROVEMENT >= $TARGET_PCT" | bc -l) )); then
    echo "SUCCESS: Met target"
else
    echo "FAILURE: Below target"
fi
```

## Checklist

Before optimizing:
- [ ] Profiled optimized build (-O2/-O3)
- [ ] No ASAN/sanitizers
- [ ] Debug symbols available
- [ ] Recording during actual load
- [ ] Analyzed Self% (not Children%)

After optimizing:
- [ ] Re-compiled with same flags
- [ ] Re-profiled with same workload
- [ ] Confirmed improvement in Self%
- [ ] No regression in other functions
- [ ] Tested correctness (not just performance)
