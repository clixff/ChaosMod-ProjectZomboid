local json = require("ChaosMod/thirdparty/Json")

---@class ChaosBridge
ChaosBridge = ChaosBridge or {}

local PROTOCOL_VERSION = 1
local MAX_LINES = 300
local POLL_INTERVAL_MS = 1000
local SESSION_ID_LEN = 16
local SESSION_ID_ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

local LUA_FILE = "ChaosMod/events/chaos-bridge-lua.jsonl"
local LUA_FILE_BACKUP = "ChaosMod/events/chaos-bridge-lua.jsonl.backup"
local NODE_FILE = "ChaosMod/events/chaos-bridge-node.jsonl"
local NODE_FILE_BACKUP = "ChaosMod/events/chaos-bridge-node.jsonl.backup"

-- Outbound state (we write LUA_FILE)
ChaosBridge.outSessionId = nil ---@type string | nil
ChaosBridge.outLineCount = 0 -- Event lines written, excluding header
ChaosBridge.outSeq = 0
ChaosBridge.pending = {} ---@type table<integer, table>
ChaosBridge.flushAccumMs = 0

-- Inbound state (we read NODE_FILE)
ChaosBridge.inSessionId = nil ---@type string | nil
ChaosBridge.inLineNumber = 0 -- Last successfully consumed line in NODE_FILE (1 = header)
ChaosBridge.inLastTs = 0
ChaosBridge.lastResetEmittedFor = nil ---@type string | nil
ChaosBridge.pollAccumMs = 0

ChaosBridge.startTime = 0 -- os.time() at Init; events with ts < startTime are ignored

---@type table<string, fun(payload: table)>
ChaosBridge.handlers = {}

ChaosBridge.enabled = false

local function generateSessionId()
    local result = {}
    local alphaLen = #SESSION_ID_ALPHABET
    for i = 1, SESSION_ID_LEN do
        local idx = ChaosUtils.RandIntegerRange(1, alphaLen + 1)
        result[i] = string.sub(SESSION_ID_ALPHABET, idx, idx)
    end
    return table.concat(result)
end

local function encodeJsonLine(obj)
    local ok, str = pcall(json.Encode, obj)
    if not ok or type(str) ~= "string" then
        return nil
    end
    return str
end

local function decodeJsonLine(str)
    if type(str) ~= "string" or str == "" then return nil end
    local ok, val = pcall(json.Decode, str)
    if not ok then return nil end
    return val
end

local function isTableNonEmpty(tbl)
    if type(tbl) ~= "table" then return false end
    for _, _ in pairs(tbl) do return true end
    return false
end

local function nowSec()
    return math.floor(os.time())
end

local function writeHeaderTruncate(filename, sessionId, startTime)
    local writer = getFileWriter(filename, true, false)
    if not writer then
        print("[ChaosBridge] Failed to open " .. filename .. " for writing")
        return false
    end
    local headerStr = encodeJsonLine({ sessionId = sessionId, start = startTime })
    if not headerStr then
        writer:close(); return false
    end
    writer:write(headerStr .. "\n")
    writer:close()
    return true
end

local function appendLines(filename, lines)
    if #lines == 0 then return true end
    local writer = getFileWriter(filename, true, true)
    if not writer then
        print("[ChaosBridge] Failed to open " .. filename .. " for append")
        return false
    end
    for _, line in ipairs(lines) do
        writer:write(line .. "\n")
    end
    writer:close()
    return true
end

local function copyFile(srcFilename, dstFilename)
    local reader = getFileReader(srcFilename, false)
    if not reader then return false end
    local writer = getFileWriter(dstFilename, true, false)
    if not writer then
        reader:close(); return false
    end
    while true do
        local line = reader:readLine()
        if line == nil then break end
        writer:write(line .. "\n")
    end
    reader:close()
    writer:close()
    return true
end

local function rotateOutbound()
    copyFile(LUA_FILE, LUA_FILE_BACKUP)
    ChaosBridge.outSessionId = generateSessionId()
    ChaosBridge.outLineCount = 0
    ChaosBridge.outSeq = 0
    ChaosBridge.pending = {}
    writeHeaderTruncate(LUA_FILE, ChaosBridge.outSessionId, nowSec())
    print("[ChaosBridge] Rotated outbound, new sessionId: " .. ChaosBridge.outSessionId)
end

local function flushPending()
    if #ChaosBridge.pending == 0 then return end
    local lines = {}
    for _, evt in ipairs(ChaosBridge.pending) do
        local line = encodeJsonLine(evt)
        if line then table.insert(lines, line) end
    end
    ChaosBridge.pending = {}
    if appendLines(LUA_FILE, lines) then
        ChaosBridge.outLineCount = ChaosBridge.outLineCount + #lines
    end
end

local function processEvent(evt)
    if type(evt) ~= "table" then return end
    local name = evt.event
    if type(name) ~= "string" then return end
    local ts = type(evt.ts) == "number" and evt.ts or 0
    if ts < ChaosBridge.startTime then return end
    if ts < ChaosBridge.inLastTs then return end
    if ts > ChaosBridge.inLastTs then
        ChaosBridge.inLastTs = math.floor(ts)
    end

    if name == "bridge-reset-session" then
        rotateOutbound()
        return
    end

    local handler = ChaosBridge.handlers[name]
    if handler then
        local ok, err = pcall(handler, evt.payload or {})
        if not ok then
            print("[ChaosBridge] Handler for '" .. name .. "' errored: " .. tostring(err))
        end
    end
end

local function readAllLines(filename)
    local reader = getFileReader(filename, false)
    if not reader then return nil end
    local lines = {}
    while true do
        local line = reader:readLine()
        if line == nil then break end
        table.insert(lines, line)
    end
    reader:close()
    return lines
end

local function drainBackup(oldSessionId, oldLineNumber)
    if not oldSessionId then return end
    local lines = readAllLines(NODE_FILE_BACKUP)
    if not lines or #lines == 0 then return end

    local header = decodeJsonLine(lines[1])
    if type(header) ~= "table" or header.sessionId ~= oldSessionId then return end

    local startIdx = math.max(2, oldLineNumber + 1)
    for idx = startIdx, #lines do
        local evt = decodeJsonLine(lines[idx])
        if evt then processEvent(evt) end
    end
end

local function pollIncoming()
    local lines = readAllLines(NODE_FILE)
    if not lines or #lines == 0 then return end

    local header = decodeJsonLine(lines[1])
    if type(header) ~= "table" or type(header.sessionId) ~= "string" then return end

    local newSessionId = header.sessionId
    if newSessionId ~= ChaosBridge.inSessionId then
        local oldSessionId = ChaosBridge.inSessionId
        local oldLineNumber = ChaosBridge.inLineNumber
        ChaosBridge.inSessionId = newSessionId
        ChaosBridge.inLineNumber = 1
        ChaosBridge.lastResetEmittedFor = nil
        if oldSessionId then
            drainBackup(oldSessionId, oldLineNumber)
        end
    end

    local totalLines = #lines
    local startIdx = ChaosBridge.inLineNumber + 1
    for idx = startIdx, totalLines do
        local raw = lines[idx]
        local evt = decodeJsonLine(raw)
        local isLast = (idx == totalLines)
        if evt then
            processEvent(evt)
            ChaosBridge.inLineNumber = idx
        elseif isLast then
            -- Possibly a partial trailing line; do not advance, retry next poll.
            break
        else
            print("[ChaosBridge] Skipping malformed line " .. tostring(idx))
            ChaosBridge.inLineNumber = idx
        end
    end

    if totalLines >= MAX_LINES then
        if ChaosBridge.lastResetEmittedFor ~= newSessionId then
            ChaosBridge.lastResetEmittedFor = newSessionId
            ChaosBridge.Emit("bridge-reset-session", nil)
        end
    end
end

---@param eventName string
---@param payload table | nil
function ChaosBridge.Emit(eventName, payload)
    if not ChaosBridge.enabled then return end
    if not ChaosBridge.outSessionId then return end
    ChaosBridge.outSeq = ChaosBridge.outSeq + 1
    local evt = {
        v = PROTOCOL_VERSION,
        seq = ChaosBridge.outSeq,
        event = eventName,
        ts = nowSec(),
    }
    if isTableNonEmpty(payload) then
        evt.payload = payload
    end
    table.insert(ChaosBridge.pending, evt)
end

---@param eventName string
---@param handler fun(payload: table)
function ChaosBridge.On(eventName, handler)
    ChaosBridge.handlers[eventName] = handler
end

function ChaosBridge.Init()
    ChaosBridge.startTime = nowSec()
    ChaosBridge.outSessionId = generateSessionId()
    ChaosBridge.outLineCount = 0
    ChaosBridge.outSeq = 0
    ChaosBridge.pending = {}
    ChaosBridge.flushAccumMs = 0
    ChaosBridge.inSessionId = nil
    ChaosBridge.inLineNumber = 0
    ChaosBridge.inLastTs = 0
    ChaosBridge.lastResetEmittedFor = nil
    ChaosBridge.pollAccumMs = 0
    if not writeHeaderTruncate(LUA_FILE, ChaosBridge.outSessionId, ChaosBridge.startTime) then
        print("[ChaosBridge] Init failed: cannot write header")
        return
    end
    ChaosBridge.enabled = true
    print("[ChaosBridge] Initialized, sessionId: " .. ChaosBridge.outSessionId)
end

function ChaosBridge.Shutdown()
    if not ChaosBridge.enabled then return end
    flushPending()
    ChaosBridge.enabled = false
    print("[ChaosBridge] Shutdown")
end

---@param deltaMs integer
function ChaosBridge.Tick(deltaMs)
    if not ChaosBridge.enabled then return end

    ChaosBridge.flushAccumMs = ChaosBridge.flushAccumMs + deltaMs
    if ChaosBridge.flushAccumMs >= POLL_INTERVAL_MS then
        ChaosBridge.flushAccumMs = ChaosBridge.flushAccumMs - POLL_INTERVAL_MS
        flushPending()
    end

    ChaosBridge.pollAccumMs = ChaosBridge.pollAccumMs + deltaMs
    if ChaosBridge.pollAccumMs >= POLL_INTERVAL_MS then
        ChaosBridge.pollAccumMs = ChaosBridge.pollAccumMs - POLL_INTERVAL_MS
        pollIncoming()
    end
end

return ChaosBridge
