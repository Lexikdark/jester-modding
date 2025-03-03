local function ClassCopyWithoutMetatable(orig, level, copies)
    level = level or 0
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[ClassCopyWithoutMetatable(orig_key, level + 1, copies)] = ClassCopyWithoutMetatable(orig_value, level + 1, copies)
            end
            if level ~= 0 then
                setmetatable(copy, getmetatable(orig))
            end
        end
    elseif orig_type ~= 'function' and level > 0 then
        copy = orig
    end
    return copy
end


local function ClassCopy(orig, level, copies)
    level = level or 0
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[ClassCopy(orig_key, level + 1, copies)] = ClassCopy(orig_value, level + 1, copies)
            end
            setmetatable(copy, getmetatable(orig))
        end
    elseif orig_type ~= 'function' and level > 0 then
        copy = orig
    end
    return copy
end

local Class = {}

Class.IsClass = function(arg)
    if type(arg) == 'table' then
        local mt = getmetatable(arg)
        return mt and mt.class ~= nil
    end
    return false
end

Class.GetInstanceClass = function(arg)
    if type(arg) == 'table' then
        local mt = getmetatable(arg)
        return mt.instance_class
    end
    return nil
end

Class.IsClassInstance = function(arg)
    return Class.GetInstanceClass(arg) ~= nil
end

Class.IsInstanceOf = function(arg, class)
    return Class.GetInstanceClass(arg) == class
end

local mt_class = {}

mt_class.__call = function(_, super)
    local c
    if super then
        c = ClassCopyWithoutMetatable(super)
    else
        c = {}
    end

    c.Seal = function (self)
        local mt = getmetatable(self)
        self.Seal = nil
        mt.__newindex = function ()
            error("Class prototypes are read_only", 2)
        end
        return self
    end

    local function SearchParent(k, list)
        for i = 1, #list do
            local v = list[i][k]
            if v then
                return v
            end
        end
    end

    c.new = function (self, ...)
        local obj = ClassCopy(self)
        local mt = {}
        mt.__index = self
        mt.instance_class = self
        setmetatable(obj, mt)
        if type(obj.Constructor) == 'function' then
            obj:Constructor(...)
        end
        return obj
    end

    local mt = {}
    mt.class = c
    mt.super = super
    mt.__index = mt.super

    if super then
        super_mt = getmetatable(super)
        if super_mt and super_mt.__call then
            mt.__call = super_mt.__call
        end
    end

    setmetatable(c, mt)

    return c
end

mt_class.__newindex = function ()
    error("Class is read_only", 2)
end
setmetatable(Class, mt_class)

return Class
