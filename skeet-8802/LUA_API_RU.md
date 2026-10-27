# Clover API 1.0

Модуль `clover_api_8802` предоставляет безопасную обёртку над существующим Lua API сборки. Он не создаёт новые возможности движка: доступность настроек, событий и методов зависит от хоста.

```lua
local api = require('clover_api_8802')
local ref, err = api.settings.reference('RAGE', 'Aimbot', 'Enabled')
if ref then
    local value = api.settings.get(ref)
    local ok, problem = api.settings.set(ref, value)
    if not ok then client.error_log(problem) end
else
    client.error_log(err)
end

api.events.on('paint', function()
    -- Рисование через штатный renderer, если он доступен в этой сборке.
end)
```

- `api.settings.reference(tab, section, name)` возвращает все ссылки штатного `ui.reference`, либо `nil, ошибка`.
- `api.settings.get(ref)` возвращает значения штатного `ui.get`; `set`, `visible`, `on_change` возвращают `true` либо `nil, ошибка`.
- `api.events.on(name, fn)` и `off(name, fn)` используют штатные методы подписки. `off` может быть недоступен в конкретном хосте.
- `api.available('renderer', 'text')` проверяет наличие метода. Исходные пространства доступны через `api.ui`, `api.client`, `api.renderer`, `api.entity`, `api.globals`, `api.database`.

Эта версия не перечисляет все контролы и не предоставляет доступ к недокументированным внутренним полям, памяти, управлению выстрелами или тем функциям, которые хост не экспортирует. Наличие функции не гарантирует, что конкретный контроль или событие поддерживается.

DLL создаёт файл clover_api_8802.lua при запуске, если его ещё нет. Если этот файл уже существует, он сохраняется; для обновления установленного модуля сравните его с файлом source/lua/clover_api.lua в архиве.

## Меню — Clover API 2.0

`api.menu.group(tab, section)` создаёт обёртку для раздела, а `group:reference(name)` возвращает объект существующей настройки. Его методы: `get()`, `set(...)`, `visible(bool)`, `on_change(fn)` и `update(...)`. Если `ui.reference` возвращает несколько связанных контролов, `reference` также возвращает несколько объектов.

`group:create(type, name, ...)` создаёт штатный контрол через Lua API хоста. Типы: `checkbox`, `slider`, `combobox`, `multiselect`, `hotkey`, `color`, `textbox`, `label`, `button`, `listbox`. Дополнительные аргументы передаются в соответствующую штатную функцию `ui.new_*`; конкретная сборка может поддерживать не все типы и места. `api.menu.types()` показывает доступные конструкторы. Создание и изменение контролов возможно только там, где это разрешает сам хост.

```lua
local api = require('clover_api_8802')
local rage = assert(api.menu.group('RAGE', 'Aimbot'))
local enabled, err = rage:reference('Enabled')
if enabled then enabled:set(true) else client.error_log(err) end

local lua_menu = assert(api.menu.group('LUA', 'A'))
local checkbox, problem = lua_menu:create('checkbox', 'My option')
if checkbox then
    checkbox:on_change(function() client.log('My option changed') end)
else
    client.error_log(problem)
end
```

`on_change` использует `ui.set_callback` и может заменить ранее установленный callback. Удаление, перемещение, переименование штатных элементов и прямое изменение закрытых внутренних данных этой версией не поддерживаются. Перезапишите установленный `clover_api_8802.lua` файлом новой версии вручную: автоматический установщик сохраняет существующий файл.
