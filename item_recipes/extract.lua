-- code to execute in Factorio
-- ex : using /c command with the code stripped of comments (sed -e "s/-- .*$//g")
-- will produce "anki_item_recipes.txt" script output file to import in Anki

local items = {}

-- map each item to a list of recipes
for _, recipe in pairs(game.recipe_prototypes) do
  for _, product in ipairs(recipe.products) do
    local recipes = items[product.name]
    if not recipes then
      recipes = {}
      items[product.name] = recipes
    end

    table.insert(recipes, recipe)
  end
end

local data = {}

local function format_item(name, amount)
  return "<div class=\"item\"><img src=\"factorio_base_graphics_icons_"..name..".png\" /><span>"..(amount or "").."</span></div>"
end

for name, recipes in pairs(items) do
  local proto = game.item_prototypes[name] or game.fluid_prototypes[name]

  local ldata = {}
  table.insert(ldata, name) -- name
  table.insert(ldata, format_item(name)) -- icon

  local recipes_data = {}
  for _, recipe in ipairs(recipes) do
    local ingredients_data = {}
    for _, ingredient in ipairs(recipe.ingredients) do
      table.insert(ingredients_data, format_item(ingredient.name, ingredient.amount))
    end

    table.insert(recipes_data, "<div>"..table.concat(ingredients_data).."</div>")
  end

  table.insert(ldata, table.concat(recipes_data)) -- recipes

  table.insert(data, table.concat(ldata, ";"))
end

game.write_file("anki_item_recipes.txt", table.concat(data, "\n"))
