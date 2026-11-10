#!/usr/bin/env bash

#===============================================================================
# Script: test_extract.sh
# Description: Automated test suite for the 'extract' script.
#===============================================================================

EXTRACT_CMD="./extract"
TEST_DIR="./test_env_extract"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# 1. Verify extract script exists and is executable
if [[ ! -f "$EXTRACT_CMD" ]]; then
    echo "Error: '$EXTRACT_CMD' not found in current directory."
    exit 1
fi
chmod +x "$EXTRACT_CMD"

# Clean up any previous test environment
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

info "Checking available compression tools..."
HAS_COMPRESS=false
if command -v compress >/dev/null 2>&1 && command -v uncompress >/dev/null 2>&1; then
    HAS_COMPRESS=true
else
    info "Note: 'compress' (ncompress) is not installed on this machine. Skipping .Z tests."
fi

#===============================================================================
# TEST 1: Help flag (-h)
#===============================================================================
info "Running Test 1: Help flag (-h)..."
out=$("$EXTRACT_CMD" -h 2>&1)
ret=$?
if [[ $ret -eq 0 && "$out" == *"Usage:"* ]]; then
    pass "Help flag (-h) prints usage and exits with 0"
else
    fail "Help flag (-h) failed (exit code: $ret)"
fi

#===============================================================================
# TEST 2: All formats WITH and WITHOUT extensions + plain files
#===============================================================================
info "Running Test 2: Decompressing formats (with/without extensions) and skipping plain files..."
mkdir -p "$TEST_DIR/t2"

# 1. gzip WITH extension
echo "hello gzip 1" > "$TEST_DIR/t2/file1.txt"
gzip "$TEST_DIR/t2/file1.txt" # becomes file1.txt.gz

# 2. gzip WITHOUT extension (misleading name)
echo "hello gzip no ext" > "$TEST_DIR/t2/file2_gzip_no_ext"
gzip "$TEST_DIR/t2/file2_gzip_no_ext"
mv "$TEST_DIR/t2/file2_gzip_no_ext.gz" "$TEST_DIR/t2/file2_gzip_no_ext"

# 3. bzip2 WITHOUT extension
echo "hello bzip2" > "$TEST_DIR/t2/file3_bzip_no_ext"
bzip2 "$TEST_DIR/t2/file3_bzip_no_ext"
mv "$TEST_DIR/t2/file3_bzip_no_ext.bz2" "$TEST_DIR/t2/file3_bzip_no_ext"

# 4. zip WITH misleading extension (.dat) and internal path structure
echo "hello zip" > "$TEST_DIR/t2/zipped_inner.txt"
zip -q "$TEST_DIR/t2/archive.zip" "$TEST_DIR/t2/zipped_inner.txt"
rm -f "$TEST_DIR/t2/zipped_inner.txt"
mv "$TEST_DIR/t2/archive.zip" "$TEST_DIR/t2/archive_zip.dat"

# 5. compress (.Z) WITHOUT extension (if installed)
EXPECTED_DECOMP=4
if [[ "$HAS_COMPRESS" == true ]]; then
    echo "hello compress" > "$TEST_DIR/t2/file5_compress"
    compress "$TEST_DIR/t2/file5_compress"
    mv "$TEST_DIR/t2/file5_compress.Z" "$TEST_DIR/t2/file5_compress"
    ((EXPECTED_DECOMP++))
fi

# 6. Plain uncompressed files (should NOT be decompressed)
echo "just plain text 1" > "$TEST_DIR/t2/plain1.txt"
echo "just plain text 2" > "$TEST_DIR/t2/plain2.log"
EXPECTED_NOT_DECOMP=2

out=$("$EXTRACT_CMD" -v "$TEST_DIR/t2"/* 2>&1)
ret=$?

if [[ $ret -eq $EXPECTED_NOT_DECOMP ]]; then
    pass "Return code matches number of uncompressed files ($ret)"
else
    fail "Expected return code $EXPECTED_NOT_DECOMP, got $ret"
fi

if [[ "$out" == *"Decompressed $EXPECTED_DECOMP archive"* ]]; then
    pass "Output accurately reports $EXPECTED_DECOMP decompressed archives"
else
    fail "Output did not report $EXPECTED_DECOMP decompressed archives. Output was: $out"
fi

if [[ -f "$TEST_DIR/t2/file1.txt" && -f "$TEST_DIR/t2/file2_gzip_no_ext" && -f "$TEST_DIR/t2/file3_bzip_no_ext" && -f "$TEST_DIR/t2/zipped_inner.txt" ]]; then
    pass "All archives unpacked into the exact same directory without nested folder duplication"
else
    fail "Some extracted files are missing in $TEST_DIR/t2"
fi

#===============================================================================
# TEST 3: Overwriting existing files
#===============================================================================
info "Running Test 3: Overwriting existing files..."
mkdir -p "$TEST_DIR/t3"

echo "NEW_CONTENT" > "$TEST_DIR/t3/target.txt"
gzip "$TEST_DIR/t3/target.txt" # creates target.txt.gz

# Create an existing file with the same unpacked name
echo "OLD_CONTENT" > "$TEST_DIR/t3/target.txt"

"$EXTRACT_CMD" "$TEST_DIR/t3/target.txt.gz" >/dev/null 2>&1
content=$(cat "$TEST_DIR/t3/target.txt" 2>/dev/null)

if [[ "$content" == "NEW_CONTENT" ]]; then
    pass "Existing file was overwritten without interactive prompt"
else
    fail "Existing file was NOT overwritten (content: '$content')"
fi

#===============================================================================
# TEST 4: Directory traversal WITHOUT -r vs WITH -r
#===============================================================================
info "Running Test 4: Recursive (-r) vs Non-Recursive directory handling..."
mkdir -p "$TEST_DIR/t4/sub1/sub2"

echo "root archive" > "$TEST_DIR/t4/root.txt"
gzip "$TEST_DIR/t4/root.txt"

echo "sub1 archive" > "$TEST_DIR/t4/sub1/sub1.txt"
bzip2 "$TEST_DIR/t4/sub1/sub1.txt"

echo "sub2 archive" > "$TEST_DIR/t4/sub1/sub2/sub2.txt"
gzip "$TEST_DIR/t4/sub1/sub2/sub2.txt"

echo "sub2 plain" > "$TEST_DIR/t4/sub1/sub2/plain.txt"

# Run WITHOUT -r (should only unpack root.txt.gz)
out_no_r=$("$EXTRACT_CMD" "$TEST_DIR/t4")
ret_no_r=$?

if [[ -f "$TEST_DIR/t4/root.txt" && -f "$TEST_DIR/t4/sub1/sub1.txt.bz2" ]]; then
    pass "Without -r: unpacked top-level directory and ignored subdirectories"
else
    fail "Without -r: failed to isolate top-level directory"
fi

# Run WITH -r (should unpack sub1.txt.bz2 and sub2.txt.gz, and count root.txt + plain.txt as 2 not decompressed)
out_with_r=$("$EXTRACT_CMD" -r -v "$TEST_DIR/t4" 2>&1)
ret_with_r=$?

if [[ -f "$TEST_DIR/t4/sub1/sub1.txt" && -f "$TEST_DIR/t4/sub1/sub2/sub2.txt" && $ret_with_r -eq 2 ]]; then
    pass "With -r: recursively unpacked all sub-archives and returned $ret_with_r (uncompressed files)"
else
    fail "With -r: failed recursive test (exit code: $ret_with_r)"
fi

# Clean up test environment
rm -rf "$TEST_DIR"

echo "----------------------------------------"
echo -e "Tests completed: ${GREEN}$PASS_COUNT passed${NC}, ${RED}$FAIL_COUNT failed${NC}."