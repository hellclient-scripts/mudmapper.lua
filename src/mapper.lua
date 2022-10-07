local Module = {}
-- 内部函数，验证标签是否有效
function Module.ValidateTags(tags, p)
    local matched = false
    for k, v in pairs(tags) do
        if (v) then
            if (p.excludetags[k]) then
                return false
            end
            if (p.tags[k]) then
                matched = true
            end
        end
    end
    return next(p.tags) == nil or matched
end
-- 导出类，通过Mapper.newpath()创建
-- 房间出口
Module.Path = {
    -- 移动指令
    command = "",
    -- 移动延时，小于等于1作为1处理
    delay = 0,
    -- 起点房间ID
    from = "",
    -- 终点房间ID
    to = "",
    -- 标签为主键的bool值表，mapper设置了对应标签才能使用该路径
    tags = {},
    -- 标签为主键的bool值表，mapper没有设置对应标签才能使用该路径
    excludetags = {},
}
-- 内部函数
function Module.Path:new(o)
    o = o or {
        command = "",
        delay = 0,
        from = "",
        to = "",
        tags = {},
        excludetags = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end
-- 内部类，房间信息
Module.Room = {
    -- 房间id
    id = "",
    -- 房间名
    name = "",
    -- Path数组，房间出口列表
    exits = {},
}
-- 内部函数，新建房间
function Module.Room:new(o)
    o = o or {
        id = "",
        name = "",
        exits = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- 导出类，Mapper本体
Module.Mapper = {
    -- 房间列表，不要直接修改
    rooms = {},
    -- 标签列表，不要直接修改
    tags = {},
    -- 飞行路径列表，不要直接修改
    fly = {},

}
-- 内部函数，新建mapper
function Module.Mapper:new(o)
    o = o or {
        rooms = {},
        tags = {},
        fly = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- 导出函数，获取飞行路径列表，Path的数组
function Module.Mapper:flylist()
    return self.fly
end

-- 导出函数，设置飞行路径列表，fly为Path的数组
function Module.Mapper:setflylist(fly)
    self.fly = fly
end
-- 导出函数，清除所有标签
function Module.Mapper:flashtags(tagnames)
    self.tags = {}
end
-- 导出函数，添加标签，将传入的字符串数组对应的标签设置为true
function Module.Mapper:addtags(fly)
    for i, v in ipairs(fly) do
        self.tags[v] = true
    end
end
-- 导出函数，设置标签，将给到的标签名设置为指定的布尔值
function Module.Mapper:settag(tagname, enabled)
    self.tags[tagname] = enabled
end

-- 导出函数，获取所有有效的标签列表，返回值为字符串数组
function Module.Mapper:alltags()
    local result = {}
    for k, v in pairs(self.tags) do
        if (v) then
            table.insert(result, k)
        end
    end
    return result
end
-- 导出函数，遍历指定的房间列表
-- targers为字符串数组，第一个值为起点
-- fly为是否使用飞行路径
-- max_distance为房间间的最大距离，小于等于0不限制
-- 返回值为Module.WalkAllResult实例
function Module.Mapper:walkall(targets, fly, max_distance)
    local a = Module.WalkAll:new()
    a.rooms = self.rooms
    a.tags = self.tags
    a.fly = self.fly
    a.targets = targets
    a.maxdistance = max_distance
    if (not fly) then
        a.fly = nil
    end
    return a:start()
end
-- 导出函数，寻找起点和终点列表之间的最短路径
-- from 起点房间id
-- fly 是否使用飞行路径
-- to 终点房间id的字符串列表
-- 返回值，找不到路径为nil，找到为Module.Step的数组
function Module.Mapper:getpath(from, fly, to)
    local w = self:newwalking()
    w.from = from
    w.to = to
    if (not fly) then
        w.fly = nil
    end
    return w:walk()
end
-- 内部函数，创建新一轮寻路
function Module.Mapper:newwalking()
    local walking = Module.Walking:new()
    walking.rooms = self.rooms
    walking.tags = self.tags
    walking.fly = self.fly
    return walking
end

-- 导出函数，获取给定房间名的ID列表
-- name为需要查询的房间名
-- 返回值为房间id的字符串数组
function Module.Mapper:getroomid(name)
    local result = {}
    for k, v in pairs(self.rooms) do
        if (v.name == name) then
            table.insert(result, v.id)
        end
    end
    return result

end
-- 导出函数，获取房间id对应的房间名
-- id为房间id
-- 返回值为房间名，没找到房间返回空字符串
function Module.Mapper:getroomname(id)
    local result = self.rooms[id]
    if (result == nil) then
        return ""
    end
    return result.name
end

-- 导出函数，初始化房间并设置房间名
-- id 房间id
-- name 房间名
function Module.Mapper:setroomname(id, name)
    local result = self.rooms[id]
    if (result == nil) then
        result = Module.Room:new()
        result.id = id
        self.rooms[id] = result
    end
    result.name = name
end
-- 导出函数，为房间添加出口
-- id为起点房间
-- p为Module.Path实例
-- 添加成功返回ture,添加失败返回false
function Module.Mapper:addpath(id, p)
    if (p.command == "") then
        return false
    end
    local room = self.rooms[id]
    if (room == nil) then
        return false
    end
    table.insert(room.exits, p)
    return true
end
-- 导出函数，重置房间
-- id为房间id
function Module.Mapper:clearRoom(id)
    local room = Module.Room:new()
    room.id = id
    self.rooms[id] = room
end

-- 导出函数，获取出口列表
-- id为起点房间id
-- all为布尔质，为true返回所有出口，为false仅返回根据当前标签可用的出口
-- 返回值为Path数组
function Module.Mapper:getexits(id, all)
    local result = {}
    local room = self.rooms[id]
    if (room == nil) then
        return result
    end
    for k, v in ipairs(room.exits) do
        if (all or Module.ValidateTags(self.tags, v)) then
            table.insert(result, v)
        end
    end
    return result
end

-- 导出函数，重置mapper
function Module.Mapper:reset()
    self.rooms = {}
    self.tags = {}
    self.fly = {}
end
-- 导出类，路径的每一步移动
Module.Step = {
    -- 当前步的目的地
    to = "",
    -- 当前步的起点
    from = "",
    -- 当前步的指令
    command = "",
    -- 当前步的耗时
    delay = 0,
    -- 计算用，不要使用
    remain = 0,
}

-- 内部函数，新建Step
function Module.Step:new(o)
    o = o or {
        to = "",
        from = "",
        command = "",
        delay = 0,
        remain = 0,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- 内部类，代表空step
Module.EmptyStep = Module.Step:new()

-- 内部类，路径计算器
Module.Walking = {
    -- 同mapper tags
    tags = {},
    -- 同mapper rooms
    rooms = {},
    -- 起点房间ID
    from = "",
    -- 重点房间列表
    to = {},
    -- 同mapper fly
    fly = {},
    -- 已经计算过的房间
    walked = {},
    -- 正在探索的列表
    forwading = {},
    -- 最大距离
    maxdistance = 0
}
-- 内部函数，新建计算类
function Module.Walking:new(o)
    o = o or {
        tags = {},
        rooms = {},
        from = "",
        to = {},
        fly = {},
        walked = {},
        forwading = {},
        maxdistance = 0
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- 内部函数，生成飞行step
function Module.Walking:flystep(p)
    local step = self:step(p)
    step.from = self.from
    return step
end

-- 内部函数，根据Path生成Step
function Module.Walking:step(p)
    local length = p.delay
    if (length < 1) then
        length = 1
    end
    return Module.Step:new({
        to = p.to,
        from = p.from,
        command = p.command,
        delay = length,
        remain = length,
    })
end

-- 内部函数，行走计算
function Module.Walking:walk()
    local distance = 0
    local rooms = self.rooms
    local tolist = {}
    -- 未找到房间则返回空
    if (rooms[self.from] == nil) then
        return nil
    end
    self.walked[self.from] = Module.EmptyStep
    -- 将起点房间出口加入探索列表
    for i, v in ipairs(rooms[self.from].exits) do
        if (self.walked[v.to] == nil and self:ValidateTags(v)) then
            table.insert(self.forwading, self:step(v))
        end
    end
     -- 将飞行路径加入探索列表
    for i, v in ipairs(self.fly) do
        if (self.walked[self.to] == nil and self:ValidateTags(v)) then
            table.insert(self.forwading, self:flystep(v))
        end
    end
    -- 无有效出口则失败
    if #self.forwading == 0 then
        return nil
    end
    -- 转换tolist为表，方便对比
    for i, v in ipairs(self.to) do
        if (rooms[v] ~= nil) then
            if (self.from == v) then
                return {}
            end
            tolist[v] = true
        end
    end
    -- 目标为空则失败
    if (next(tolist) == nil) then
        return nil
    end
    local matchedRoom = ""
    -- Matching:
    while (true) do
        local breakMatching=false
        -- 下一轮探索队列
        local newexits = {}
        distance = distance + 1
        if (self.maxdistance > 0 and distance > self.maxdistance) then
            break
        end
        while (true) do
            local breaked=false
            -- 实现continue，实在无语
            repeat
                -- 弹出探索队列对一个，进行探索
                local v = self.forwading[1]
                if (v == nil) then
                    breaked=true
                    break
                end
                local step = v
                table.remove(self.forwading, 1)
                if (self.walked[step.to] ~= nil or rooms[step.to] == nil) then
                    break
                end
                if (self.maxdistance > 0 and step.Delay > self.maxdistance) then
                    break
                end
                -- 扣减移动步伐延迟
                step.remain = step.remain - 1
                -- 还在延迟则雅入下一轮探索队列
                if (step.remain > 0) then
                    table.insert(newexits, step)
                    break
                end
                self.walked[step.to] = step
                -- 是终点则结束
                if (tolist[step.to]) then
                    matchedRoom = step.to
                    breakMatching=true
                    break
                end
                -- 将新房间的有效出口压入下一轮探索
                for exiti, exit in ipairs(rooms[step.to].exits) do
                    if (self.walked[exit.to] == nil and self:ValidateTags(exit)) then
                        table.insert(newexits, self:step(exit))
                    end
                end
            until true
            --实现continue时的break,唉……
            if (breakMatching or breaked) then
                break
            end
        end
        -- 实现break两层……
        if (breakMatching) then
            break
        end
        -- 一轮探索结束，将下一轮探索的列表引入
        for i, v in ipairs(newexits) do
            table.insert(self.forwading, v)
        end
        -- 没新的探索列表则失败
        if (#self.forwading == 0) then
            break
        end
    end
    if (matchedRoom == "") then
        return nil
    end
    local result = {}
    local step = self.walked[matchedRoom]
    -- 合并路径
    while true do
        if (step == nil or step == Module.EmptyStep) then
            break
        end
        table.insert(result, 1, step)
        step = self.walked[step.from]
    end
    local steps = {}
    for i, v in ipairs(result) do
        if (v == nil) then
            break
        end
        steps[i] = v
    end
    return steps
end

-- 内部函数，验证标签是否有效
function Module.Walking:ValidateTags(p)
    return Module.ValidateTags(self.tags, p)
end

-- 导出类，动态遍历结果
Module.WalkAllResult={
    -- 移动步列表，Step数组
    steps={},
    -- 成功遍历的房间，字符串数组
    walked={},
    -- 未能遍历的房间，字符串数组
    notwalked={},
}

-- 内部函数，新建动态遍历结果
function Module.WalkAllResult:new(o)
    o = o or {
        steps={},
        walked={},
        notwalked={},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end
-- 内部类，动态遍历计算类
Module.WalkAll={
    -- 目标列表
	targets={},
    -- 最大距离
	maxdistance=0,
    -- 同mapper
	rooms={},
    -- 同mapper
	tags={},
    -- 同mapper
	fly={},
}
function Module.WalkAll:new(o)
    o = o or {
        targets={},
        maxdistance=0,
        rooms={},
        tags={},
        fly={},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end
-- 内部函数，新建遍历寻路
function Module.WalkAll:newwalking()
	local walking = Module.Walking:new()
	walking.rooms = self.rooms
	walking.tags = self.tags
	walking.fly = self.fly
	return walking
end
-- 内部函数，遍历移动
function Module.WalkAll:walk(fr, to)
	local w = self:newwalking()
	w.from = fr
	w.to = to
	w.maxdistance = self.maxdistance
	return w:walk()
end
-- 内部函数，过滤
function  Module.WalkAll:filter(input, filtered)
	local result ={}
    for i,v in ipairs(input) do
		if (v ~= filtered) then
            table.insert(result,v)
        end
    end
	return result
end

-- 内部函数，计算动态遍历
function Module.WalkAll:start()
	local result =Module.WalkAllResult:new()
	if (#self.targets < 2)then
		return result
    end
    -- 第一个目标为遍历起点
	local fr = self.targets[1]
    local left={}
    for i,v in ipairs(self.targets) do
        if i>1 then
            table.insert(left,v)
        end
    end
	result.walked = {fr}
    -- 尝试移动
    while (#left>0) do
        local steps= self:walk(fr,left)
        -- 生下的房间都不能去则结束
        if steps==nil or (#steps==0) then
            break
        end
        for i,v in ipairs(steps) do
            table.insert(result.steps,v)
        end
		fr = steps[#steps].to
		left = self:filter(left, fr)
        table.insert(result.walked,fr)
    end
	result.notwalked = left
	return result
end

-- 导出类，新建路径
Module.newpath = function()
    return Module.Path:new()
end

-- 导出类，新建Mapper
Module.newmapper = function()
    return Module.Mapper:new()
end
return Module
