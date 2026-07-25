-- Micro Editor Custom Initialization Script

local micro = import("micro")

-- Auto-detect UTF-16 encoding based on Byte Order Mark (BOM)
function onBufferOpen(buf)
    local path = buf.Path
    if path == nil or path == "" then
        return
    end

    -- Attempt to open the file in binary mode
    local file, err = io.open(path, "rb")
    if not file then
        return
    end

    -- Read the first 2 bytes to check for UTF-16 BOM
    local bytes = file:read(2)
    file:close()

    if not bytes or #bytes < 2 then
        return
    end

    local b1 = string.byte(bytes, 1)
    local b2 = string.byte(bytes, 2)

    local encoding = nil
    if b1 == 0xFF and b2 == 0xFE then
        encoding = "utf-16le"
    elseif b1 == 0xFE and b2 == 0xFF then
        encoding = "utf-16be"
    end

    if encoding then
        local current_encoding = buf.Settings["encoding"]
        if current_encoding ~= encoding then
            buf:SetOption("encoding", encoding)
            -- Clear buffer content first to prevent ReOpen view artifacts
            buf:Replace(buf:Start(), buf:End(), "")
            buf:ReOpen()
            micro.InfoBar():Message("UTF-16 BOM detected. Encoding set to " .. encoding)
        end
    end
end
