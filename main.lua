getgenv().Methods = {
    FireServer = true,
    InvokeServer = true,
 }
 
 getgenv().Blacklisted = {
    CharacterSoundEvent = true,
 }
--get table function I stole from google
local function get_table(node)
    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output,output_str)
    output_str = table.concat(output)

    return (output_str)
end

rconsolename("Remote Spy")

local function log(Method, Event, Args, color)
    color = color or "@@WHITE@@"
    rconsoleprint(color)
    rconsoleprint(("Method: %s\n"):format(Method))
    rconsoleprint(("Event: %s\n"):format(tostring(Event)))
    rconsoleprint(("Path %s\n"):format(tostring(Event:GetFullName())))
    if #Args ~= 0 then
        rconsoleprint(("Args: %s\n"):format(get_table(Args)))
    end
    rconsoleprint(("Script:\n"))
    if  #Args == 0 then
        rconsoleprint(("game.%s:%s()\n\n\n"):format(Event:GetFullName(), Method))
    else
        rconsoleprint(("game.%s:%s(unpack(%s))\n\n\n"):format(Event:GetFullName(), Method, get_table(Args)))
    end
    
end

local meta = getrawmetatable(game)
local old = meta.__namecall
if setreadonly then
	setreadonly(meta, false)
else
	make_writeable(meta, true)
end
local callMethod = getnamecallmethod or get_namecall_method
local newClosure = newcclosure or function(f)
	return f
end

meta.__namecall = newClosure(function(Event, ...)
	local cmethod = callMethod()
	local arguments = {...}
    local color = (getgenv().Methods["FireServer"] and tostring(cmethod) == "FireServer" and "@@YELLOW@@") or (getgenv().Methods["InvokeServer"] and tostring(cmethod) == "InvokeServer" and "@@LIGHT_MAGENTA@@") or nil

	if color and not getgenv().Blacklisted[tostring(Event)] then
        log(cmethod, Event, arguments, color)
    end

	return old(Event, ...)
end)

if setreadonly then
	setreadonly(meta, true)
else
	make_writeable(meta, false)
end
