-- Clover API 1.0. Uses the host's existing GameSense APIs and permissions.
local M = { version = '2.0.0' }
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
-- Menu groups use the native host API; the host decides which locations/types exist.
M.menu = {}
local constructors={checkbox='new_checkbox',slider='new_slider',combobox='new_combobox',multiselect='new_multiselect',hotkey='new_hotkey',color='new_color_picker',textbox='new_textbox',label='new_label',button='new_button',listbox='new_listbox'}
local control={};control.__index=control
function control:get() return M.settings.get(self.ref) end
function control:set(...) return M.settings.set(self.ref,...) end
function control:visible(value) return M.settings.visible(self.ref,value) end
function control:on_change(fn) return M.settings.on_change(self.ref,fn) end
function control:update(...) local _,err=invoke(ui,'update',self.ref,...);if err then return nil,err end;return true end
function M.menu.reference(tab, section, name)
 local refs={M.settings.reference(tab,section,name)}
 if refs[1]==nil then return nil,refs[2] end
 local result={};for i,ref in ipairs(refs) do result[i]=setmetatable({ref=ref},control) end
 return unpack(result)
end
function M.menu.create(kind, tab, section, name, ...)
 local method=constructors[kind];if not method then return nil,'Unknown control type: '..tostring(kind) end
 if type(tab)~='string' or type(section)~='string' or type(name)~='string' then return nil,'Expected tab, section and name strings' end
 local ref,err=invoke(ui,method,tab,section,name,...);if ref==nil then return nil,err or 'Host did not return a control' end
 return setmetatable({ref=ref},control)
end
function M.menu.group(tab, section)
 if type(tab)~='string' or type(section)~='string' then return nil,'Expected tab and section strings' end
 local group={tab=tab,section=section}
 function group:reference(name) return M.menu.reference(self.tab,self.section,name) end
 function group:create(kind,name,...) return M.menu.create(kind,self.tab,self.section,name,...) end
 return group
end
function M.menu.types()
 local result={};for kind,method in pairs(constructors) do if M.available('ui',method) then result[#result+1]=kind end end
 table.sort(result);return result
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
