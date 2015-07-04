-- leng.lua: meddling with indexing.
-- Written by Tommy Ettinger. MIT License.

local leng = {}

local seqmeta = {
  __index = function(t, k)
    if type(k) == 'table' and rawget(getmetatable(k) or {}, '_domain') then
      local r = k.rank
      -- look up and return a seq
    else
      return t[k]
    end
    
  end
  
}

local function seq(t)
  local working, i = {}, 1
  for _,v in ipairs(t) do
    working[i] = v
    i = i + 1
  end
  setmetatable(t, seqmeta)
end

local domain = {}

local domainmeta = {_domain = true,
  __call = function(d, ...)
    if select('#', ...) ~= 1 then return nil end
    local keys = (...)
    local limits, offset, stride, length_product, bound = {}, 0, 1, 1, true
    for i=1, d.rank do
      if keys[i] ~= nil and bound then
        limits[i] = {keys[i], keys[i]}
        if d[i].length then
          offset = offset + (keys[i] - d[i].start) * length_product
          length_product = length_product * d[i].length
        else
          bound = false
        end
      else
        limits[i] = {}
        if d[i].length then
          stride = stride * d[i].length
        else
          bound = false
        end
      end
      
      local dom = domain[d.rank](limits)
    end
    
  end  
}


setmetatable(domain, 
  {
    __index = function(dom,r)
      if type(r) ~= 'number' or r < 1 then error("Rank of a domain must be an integer > 0") end
      return function(limits)
        if type(limits) ~= 'table' then error("Sizing information for a domain must be a table of tables") end
        local d = {rank = r}
        setmetatable(d, domainmeta)
        for i=1,r do
          if limits[i] and type(limits[i]) == 'table' then
            d[i] = {start = limits[i][1], stop = limits[i][2]}
            if type(limits[i][1]) == 'number' and type(limits[i][2]) == 'number' then
              d[i].length = 1 + limits[i][2] - limits[i][1]
            end
          else
            d[i] = {start = 1}
          end
        end
        d.offset = limits.offset or 0
        d.stride = limits.stride or 1
        return d
      end      
    end    
  })

-- just a reminder of how this works
--rawget(getmetatable(obj) or {}, event)
return leng