-- will generate note data file to import into Anki
-- parameters: <factorio game path> <locale>

local factorio_path, locale = ...
if not factorio_path then error("missing factorio_path argument") end
if not locale then error("missing locale argument") end

local function load_locale(locale)
  local lang = {}

  local file, err = io.open(factorio_path.."/data/base/locale/"..locale.."/base.cfg", "r")
  if file then
    local line
    repeat
      line = file:read("*l")
      if line then
        line = string.gsub(line, "\r", "")
        local k,v = string.match(line, "^(.-)=(.*)$")
        if k then lang[k] = v end
      end
    until not line

    file:close()
  else
    print("error reading locale \""..locale.."\": "..err)
  end

  return lang
end

-- load locale
local lang = load_locale(locale)

local function list_lua(path)
  local files = {}
  local find = io.popen("find \""..path.."\" -type f -name \"*.lua\"")

  local line
  repeat
    line = find:read("*l")
    table.insert(files, line)
  until not line

  find:close()

  return files
end

local icons = {} -- map of item name => icon path
local items = {} -- map of item => list of recipes

-- called at every data:extend(data)
local function process_data(data)
  for _, entry in pairs(data) do
    if entry.type == "recipe" then
      -- map each item to a list of recipes
      local recipe_data = entry.normal or entry
      local ingredients = recipe_data.ingredients or {recipe_data.ingredient}
      local results = recipe_data.results or {recipe_data.result}

      for _, product in ipairs(results) do
        local name = type(product) == "table" and (product.name or product[1]) or product
        local recipes = items[name]
        if not recipes then
          recipes = {}
          items[name] = recipes
        end

        table.insert(recipes, ingredients)
      end
    else -- register icon
      if entry.icon then
        local icon = string.gsub(string.gsub(entry.icon, "__base__", "base"), "/", "_")
        icons[entry.name] = icon
      end
    end
  end
end

local env = setmetatable({
  data = {extend = function(self, data) process_data(data) end}
}, { __index = function() return function()end end, __newindex = function() end})

local function process_file(path)
  local f, err = loadfile(path)
  if f then
    setfenv(f, env)

    local ok, err = pcall(f)
    if not ok then
      print("processing error for \""..path.."\": "..err)
    end
  else
    print("processing error for \""..path.."\": "..err)
  end
end

-- process items
for _, file in ipairs(list_lua(factorio_path.."/data/base/prototypes/item")) do
  process_file(file)
end
for _, file in ipairs(list_lua(factorio_path.."/data/base/prototypes/fluid")) do
  process_file(file)
end
-- process recipes
for _, file in ipairs(list_lua(factorio_path.."/data/base/prototypes/recipe")) do
  process_file(file)
end

-- generate Anki notes data
local data = {}

local function format_item(icon, amount)
  return "<div class=\"item\"><img src=\"factorio_"..icon.."\" /><span>"..(amount or "").."</span></div>"
end

for name, recipes in pairs(items) do
  local ldata = {}
  table.insert(ldata, lang[name] or name) -- name

  local icon = icons[name] or name..".png"
  table.insert(ldata, format_item(icon)) -- icon

  local recipes_data = {}
  for _, recipe in ipairs(recipes) do
    local ingredients_data = {}
    for _, ingredient in ipairs(recipe) do
      local name = type(ingredient) == "table" and (ingredient.name or ingredient[1]) or ingredient
      local icon = icons[name] or name..".png"

      table.insert(ingredients_data, format_item(icon))
    end

    table.insert(recipes_data, "<div>"..table.concat(ingredients_data).."</div>")
  end

  table.insert(ldata, table.concat(recipes_data)) -- recipes

  table.insert(data, table.concat(ldata, ";"))
end

local output = io.open("anki_notes.txt", "w")
output:write(table.concat(data, "\n"))
output:close()
