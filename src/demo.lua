-- 格式化输出路径列表
function Dumpsteps(path)
    if path==nil then
        return "nil"
    end
    local count=#path
    local commnds={}
    local delay=0
    local to=path[#path].to
    local from=path[1].from
    local result=""
    for i,v in pairs(path) do
        table.insert(commnds,v.command)
        delay=delay+v.delay
    end
    result=result.."count:"..count..","
    result=result.."from:"..from..","
    result=result.."to:"..to..","
    result=result.."commands:"..table.concat(commnds,";")..","
    result=result.."delay:"..delay..","
    return result
end

local Mapper=require "mapper"

-- 新建mapper实例
local m=Mapper.newmapper()
-- 初始化房间
m:setroomname("shanghai","上海")
m:setroomname("beijing","北京")
m:setroomname("hangzhou","杭州")
m:setroomname("ningbo","宁波")
m:setroomname("xiaoxianchen1","小县城")
m:setroomname("xiaoxianchen2","小县城")
m:setroomname("xiaoxianchen3","小县城")

local paths={
    {from="shanghai",to="beijing",command="坐火车"},
    {from="beijing",to="shanghai",command="坐火车回"},
    {from="hangzhou",to="shanghai",command="坐汽车",excludetags={yunche=true}},
    {from="shanghai",to="hangzhou",command="坐汽车回",excludetags={yunche=true}},
    {from="hangzhou",to="beijing",command="坐飞机",tags={rich=true}},
    {from="beijing",to="hangzhou",command="坐飞机回",tags={rich=true}},
    {from="hangzhou",to="shanghai",command="骑自行车",delay=10},
    {from="shanghai",to="hangzhou",command="骑自行车回",delay=10},
    {from="ningbo",to="shanghai",command="骑自行车2",delay=10},
    {from="shanghai",to="ningbo",command="骑自行车回2",delay=10},

}

-- 引入飞行路径
local path=Mapper.newpath()
path.command="包车"
path.to="beijing"
m:setflylist({path})


for i,v in ipairs(paths) do
    local path=Mapper.newpath()
    path.from=v.from or ""
    path.to=v.to or ""
    path.command=v.command or ""
    path.delay=v.delay or 0
    path.tags=v.tags or {}
    path.excludetags=v.excludetags or {}
    m:addpath(path.from,path)
end

-- 获取hangzhou的可用出口,没有rich坐飞机不可用
-- 2
print(#m:getexits("hangzhou"))
-- 获取hangzhou的全部出口
-- 3
print(#m:getexits("hangzhou",true))
-- 获取shanghai的房间名
-- 上海
print(m:getroomname("shanghai"))
-- 获取不存在的newyork房间
-- ""
print(m:getroomname("newyork"))
-- 获取房间名为上海的房间
-- shanghai
print(table.concat(m:getroomid("上海"),","))
-- 获取房间名为纽约的房间
-- ""
print(table.concat(m:getroomid("纽约"),","))
-- 获取房间名为小县城的房间
-- xiaoxianchen3,xiaoxianchen2,xiaoxianchen1
print(table.concat(m:getroomid("小县城"),","))
-- 获取shanghai到beijing的路径
-- count:1,from:shanghai,to:beijing,commands:坐火车,delay:1,
print(Dumpsteps(m:getpath("shanghai",false,{"beijing"})))
-- 获取hangzhou到beijing的路径，经过shanghai
-- count:2,from:hangzhou,to:beijing,commands:坐汽车;坐火车,delay:2,
print(Dumpsteps(m:getpath("hangzhou",false,{"beijing"})))
-- 开启飞行列表
-- count:1,from:hangzhou,to:beijing,commands:包车,delay:1,
print(Dumpsteps(m:getpath("hangzhou",true,{"beijing"})))
-- 不存在的起点
-- nil
print(Dumpsteps(m:getpath("newyork",false,{"beijing"})))
-- 不存在的终点
-- nil
print(Dumpsteps(m:getpath("shanghai",false,{"newyork"})))
-- 终点中包含不可用房间
-- count:1,from:shanghai,to:beijing,commands:坐火车,delay:1,
print(Dumpsteps(m:getpath("shanghai",false,{"newyork","beijing"})))
-- 设置rich标签
m:settag("rich",true)
-- 有钱,所以坐飞机
-- count:1,from:hangzhou,to:beijing,commands:坐飞机,delay:1,
print(Dumpsteps(m:getpath("hangzhou",false,{"beijing"})))
-- 重置标签
m:flashtags()
-- 不晕车,可以做汽车
-- count:1,from:hangzhou,to:shanghai,commands:坐汽车,delay:1,
print(Dumpsteps(m:getpath("hangzhou",false,{"shanghai"})))
-- 阿,晕车了
m:settag("yunche",1)
-- 晕车了,只能骑自行车
-- count:1,from:hangzhou,to:shanghai,commands:骑自行车,delay:10,
print(Dumpsteps(m:getpath("hangzhou",false,{"shanghai"})))
-- 重置标签
m:flashtags()
-- 宁波去杭州,多条路线找delay最短的
-- count:2,from:ningbo,to:hangzhou,commands:骑自行车2;坐汽车回,delay:11,
print(Dumpsteps(m:getpath("ningbo",false,{"hangzhou"})))
-- 宁波就近去beijing或者hangzhou,杭州近
-- count:2,from:ningbo,to:beijing,commands:骑自行车2;坐火车,delay:11,
print(Dumpsteps(m:getpath("ningbo",false,{"beijing","hangzhou"})))

-- 动态遍历房间
local result=m:walkall({"shanghai","beijing","ningbo","hangzhou","xiaoxianchen1","xiaoxianchen2","xiaoxianchen3"},0)
-- 遍历成功的房间
-- shanghai,beijing,hangzhou,ningbo
print(table.concat(result.walked,","))
-- 遍历失败的房间
print(table.concat(result.notwalked,","))
-- 遍历路径
-- count:5,from:shanghai,to:ningbo,commands:坐火车;坐火车回;坐汽车回;坐汽车;骑自行车回2,delay:14,
print(Dumpsteps(result.steps))