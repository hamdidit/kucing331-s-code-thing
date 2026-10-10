local T = {}
local uniqueid='UNIQUEID'
local currentlyuniqueid=0

--==Other stuff that didnt fit==--

local offsettext='                    '
-- DeepLevel count as an indicator for a recursive table
--     and how deep is the table
function T.PrintTable(_table:{[any]:any},DeepLevel:number?) 
 if typeof(_table)~="table" then warn(`{_table} is not a table`)return end
    local added=''
    for j,k in _table do  
            added..=`\n`
            
            if DeepLevel then
               for i=1, DeepLevel do
                  added..='    ' 
               end
                
            end
            added..=`{offsettext}` -- to not make the output window look awkward
            added..=`[{j}]: `
        if typeof(k)=='table' then
            added..="{"
            added..=printall(k,(DeepLevel or 0)+1 ) 
        else
            if typeof(k)=='string' then
                k=`"{k}"`
            end
            
            added..=tostring(k)
        end
        
        added..=','
        
    
    end

    if not DeepLevel then
        print(`\{{_table}\} = \{ {added}`)
    else
        added..=`\n{offsettext}\}`
        return added
    end
    
end


-- run a function that yield and does not stop upon error
-- does not gave accurate error addreses
function T.SafeFunction(func:(...any)->(...any))
	local a,b =pcall(func)
	if not a then
		task.spawn(function()error(b)end)
	end
end
-- instance.new() that use the existing one with the same name if exist
function T.NewInstance(_Class:string,_Parent:Instance,Name:string)
	local v:Instance=_Parent:FindFirstChild(Name) or Instance.new(_Class,_Parent)
	v.Name=Name
	return v
end

function T.FindHumanoid(_Parent:Instance):Humanoid
	if _Parent:IsA('Humanoid') then
		return _Parent
	end
	local Humanoid=_Parent:FindFirstChildWhichIsA('Humanoid')
	if Humanoid then
		return Humanoid
	end
	local Parent=T.FindRig(_Parent)
	if not Parent then
		return
	end
	
	Humanoid=Parent:FindFirstChildWhichIsA('Humanoid') 
	return Humanoid 
end

-- get a rig that has humanoid
function T.FindRig(_Parent:Instance):Model
	if _Parent:IsA('Model') then
		if _Parent:FindFirstChildWhichIsA('Humanoid') then
			return _Parent
		end
		return
	end
	local Parent=_Parent:FindFirstAncestorWhichIsA('Model') or _Parent.Parent
	if Parent==workspace then
		return
	end 
	
	if not Parent:FindFirstChildWhichIsA('Humanoid') then
		return
	end
	
	
	return Parent
end

-- Deeply copy the table to avoid sync
function T.DeepCopy(tble:{any}):{any}
	local totable={}
	for i,v in tble do
		local _v=v
		if typeof(v)=='table' then
			_v=T.DeepCopy(v)			
		end
		totable[i]=_v
	end

	return totable
end

-- table.remove() by finding value
function T.TableRemove( _table:{any},value)
	local find=table.find(_table,value)
	if not find then return end
	table.remove(_table,
		find
	)
	
	return true
end
-- set a transparency depends on its instance
function T.SetTransparency(_instance:Instance,transparency:number)
	assert(_instance and transparency)
	if _instance:IsA('BasePart') or  _instance:IsA('Decal') or _instance:IsA('Texture') then
		_instance.Transparency=transparency
	end
end

function T.FireAllExceptClient(_player:Player,Remote:RemoteEvent,...)
	for _,v in game.Players:GetPlayers() do
		if _player==v then continue end
		Remote:FireClient(v,...)
	end
	
end

function T.FormatInputToString(Input:InputObject,Another:string?):string
	local RETURN=''
	if Another and typeof(Input)=='string' then
		RETURN=`{Input}_{Another}`
	else
		RETURN=`{Input.UserInputType.Name}_{Input.KeyCode.Name}`
	end
	
	return 	 RETURN
end

-- return Value x Multiplier, value, multiplier
function T.GetValueAndMultiplierOnTable(_Table):number|number|number
	assert(typeof(_Table)=='table')
	
	local value,multiplier=0,1
	for i,v in _Table do
		if tonumber(v) then
			value+=v
		else
			local str=tostring(v)
			if str:find('x') then
				multiplier+=tonumber(str:split('x')[1])
			elseif str:find('s') then
				multiplier=1
				value=tonumber(str:split('s')[1])
				break
			end
		end
	end
	
	return value*multiplier,value,multiplier
	
end

--==Math!!!==--

-- 12.2234 -> 12.2
function T.PerserveFloat(number:number,upto:number)
	upto=upto or 10
	return math.round(number*upto)/upto
end
-- 251 , 10 -> 25
function T.RemoveFloat(number:number,upto:number):number
	return math.floor(number/upto)
end

--==Connectioons==--



-- create a custom connection that can :Connect(), :Trigger(), and :Disconnect()
function T.CustomConnection()
	local _Functions={}
	local _v={
		Functions=_Functions
	}

	function _v:Connect(func:(any)->(any))
		local __v={}
		table.insert(_Functions,func)
		function __v:Disconnect()
			table.remove(_Functions,table.find(_Functions,func))
		end

		return __v
	end

	function _v:Trigger(...)
		for _,v in _Functions do 
			v(...)
		end

	end

	return _v
end

-- Collect the connection and :DisconnectAll() easily
function T.ConnectionGrouper()
	local _Connections={}
	local _v ={Conn=_Connections}
	function _v:Add(conn:RBXScriptConnection)
		table.insert(_Connections,conn)
	end

	function _v:DisconnectAll()
		for _,v in _Connections do
			v:Disconnect()
		end
		_Connections={}
	end
	return _v
end


--==Unique ID==--

--generate a random unique id for the instnace
function T.SetUniqueID(_Instance:Instance):string
	currentlyuniqueid+=1
	local id=currentlyuniqueid--game.HttpService:GenerateGUID(false)
	_Instance:SetAttribute(uniqueid,id)
	return id
end

-- get unique id from the instnace
function T.GetUniqueID(_Instance:Instance):string
	local id=_Instance:GetAttribute(uniqueid)
	if not id then
		id=T.SetUniqueID(_Instance)
	end
	return id
end

--==Get Children variant==--
--Base for other get children


--==Wait For Child Variant==--

--Base for other waitforchild
function T._WaitForChild(_Parent:Instance,Cond:(Instance)->(boolean)):Instance
	assert(_Parent)

	if not Cond then
		warn('eh :/')
		Cond=function(v)
			return true
		end
	end
	
	local wanted=nil
	local c=_Parent.ChildAdded:Connect(function(child)
		if Cond (child) then
			wanted=child
		end
	end)
	
	local alst=tick()
	while task.wait() and not wanted do
		if alst and tick()-alst>10 then
			warn(`Infinite Yield for finding a child on {_Parent}`)
			alst=nil
		end
	end
	
	c:Disconnect()
	return wanted
end

function T.WaitForCLass(_Parent:Instance,Class:string):Instance
	return T._WaitForChild(_Parent,function(v)
		return v:IsA(Class)
	end)
	
end
--==Find first child variant==--
--Base for other find first child
function T._FindFirstChild(_Parent:Instance,Cond:(Instance)->(boolean),Recursive:boolean?):Instance
	assert(_Parent)

	if not Cond then
		warn('eh :/')
		Cond=function(v)
			return false
		end
	end

	for _,v in (Recursive and _Parent:GetDescendants() or _Parent:GetChildren()) do
		if Cond(v) then 
			return v
		end
	end

	return 
end

function T.FindChildWithID(_Parent:Instance,_ID:string,...)
	return T._FindFirstChild(_Parent,function(v)
		return T.GetUniqueID(v)==_ID
	end,...)
end

function T.FindChildWithTag(_Parent:Instance,Tag:string,...)
	print(_Parent,Tag)
	return T._FindFirstChild(_Parent,function(v)
		return v:HasTag(Tag)
	end,...)
end



return T
