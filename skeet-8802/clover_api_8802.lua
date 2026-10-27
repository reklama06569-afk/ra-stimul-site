-- Clover API 1.0. Uses the host's existing GameSense APIs and permissions.
local M = { version = '1.0.0' }
local function invoke(object, method, ...)
 if type(object) ~= 'table' or type(object[method]) ~= 'function' then
  return nil, 'Host API unavailable: ' .. method
 end
 local results = { pcall(object[method], ...) }
 if not results[1] then return nil, tostring(results[2]) end
 table.remove(results, 1)
 return unpack(results)
end
function M.available(name, method)
 local object = ({ui=ui, client=client, renderer=renderer, entity=entity, globals=globals, database=database})[name]
 return type(object)=='table' and (not method or type(object[method])=='function')
end
M.settings = {}
function M.settings.reference(tab, section, name)
 if type(tab)~='string' or type(section)~='string' or type(name)~='string' then return nil, 'Expected tab, section and name strings' end
 return invoke(ui, 'reference', tab, section, name)
end
function M.settings.get(ref) if ref==nil then return nil, 'Missing setting reference' end;return invoke(ui, 'get', ref) end
function M.settings.set(ref, ...) if ref==nil then return nil, 'Missing setting reference' end;local _,err=invoke(ui,'set',ref,...);if err then return nil,err end;return true end
function M.settings.visible(ref, value) if ref==nil then return nil,'Missing setting reference' end;local _,err=invoke(ui,'set_visible',ref,value);if err then return nil,err end;return true end
function M.settings.on_change(ref, callback)
 if ref==nil or type(callback)~='function' then return nil,'Expected setting reference and callback' end
 local _,err=invoke(ui,'set_callback',ref,callback);if err then return nil,err end;return true
end
M.events={}
function M.events.on(name, callback)
 if type(name)~='string' or type(callback)~='function' then return nil,'Expected event name and callback' end
 local _,err=invoke(client,'set_event_callback',name,callback);if err then return nil,err end;return true
end
function M.events.off(name, callback)
 if type(name)~='string' or type(callback)~='function' then return nil,'Expected event name and callback' end
 local _,err=invoke(client,'unset_event_callback',name,callback);if err then return nil,err end;return true
end
-- Host namespaces remain available for controls, drawing, entities and game events.
M.ui, M.client, M.renderer, M.entity, M.globals, M.database = ui,client,renderer,entity,globals,database
return M
