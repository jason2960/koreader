DocSettings = {
	}

function DocToHistory(fullname)
	local i,j = 1,0
	while i ~= nil do
		i = string.find(fullname,"/",i+1)
		if i==nil then break end
		j = i
	end
	local f = string.sub(fullname,j+1,-1)
	if j>0 then return "./history/\["..string.gsub(string.sub(fullname,1,j),"/","#").."\] "..f..".lua"
	else return "./settings"..f..".lua" end
end

function HistoryToName(history)
	-- at first, search for path length
	local s = string.len(string.match(history,"%b[]"))
	-- and return the rest of string without 4 last characters (".lua")
	return string.sub(history, s+2, -5)
end

function HistoryToPath(history)
	-- 1. select everything included in brackets
	local s = string.match(history,"%b[]")
	-- 2. crop the bracket-sign from both sides
	-- 3. and finally replace decorative signs '#' to dir-char '/'
	return string.gsub(string.sub(s,2,-3),"#","/")
end

function DocSettings:open(docfile)
	lfs.mkdir("./history")
	local new = { file = DocToHistory(docfile), data = {} }
	local ok, stored = pcall(dofile,new.file)
	if ok then
		new.data = stored
	end
	return setmetatable(new, { __index = DocSettings})
end

function DocSettings:readSetting(key)
	return self.data[key]
end

function DocSettings:saveSetting(key, value)
	self.data[key] = value
end

function DocSettings:delSetting(key)
	self.data[key] = nil
end

function dump(data)
	local out = {}
	DocSettings:_serialize(data, out, 0)
	return table.concat(out)
end

function debug(...)
	local line = ""
	for i,v in ipairs(arg) do
		if type(v) == "table" then
			line = line .. " " .. dump(v)
		else
			line = line .. " " .. tostring(v)
		end
	end
	print("#"..line)
end

-- simple serialization function, won't do uservalues, functions, loops
function DocSettings:_serialize(what, outt, indent)
	if type(what) == "table" then
		local didrun = false
		table.insert(outt, "{")
		for k, v in pairs(what) do
			if didrun then
				table.insert(outt, ",")
			end
			table.insert(outt, "\n")
			table.insert(outt, string.rep("\t", indent+1))
			table.insert(outt, "[")
			self:_serialize(k, outt, indent+1)
			table.insert(outt, "] = ")
			self:_serialize(v, outt, indent+1)
			didrun = true
		end
		if didrun then
			table.insert(outt, "\n")
			table.insert(outt, string.rep("\t", indent))
		end
		table.insert(outt, "}")
	elseif type(what) == "string" then
		table.insert(outt, string.format("%q", what))
	elseif type(what) == "number" or type(what) == "boolean" then
		table.insert(outt, tostring(what))
	end
end

function DocSettings:flush()
	-- write a serialized version of the data table
	if not self.file then
		return
	end
	local f_out = io.open(self.file, "w")
	if f_out ~= nil then
		local out = {"-- we can read Lua syntax here!\nreturn "}
		self:_serialize(self.data, out, 0)
		table.insert(out, "\n")
		f_out:write(table.concat(out))
		f_out:close()
	end
end

function DocSettings:close()
	self:flush()
end
