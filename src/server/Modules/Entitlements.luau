-- Qué entrega cada compra con Robux y cómo se deshace. PlayerData.processReceipt lo usa así:
--   local plan = Entitlements.Plan(data, Products.Resolve(receipt.ProductId), ctx)
--   local undo = Entitlements.Apply(data, plan)   -- se apunta el PurchaseId y se guarda
--   (si no se pudo guardar: undo() y Roblox reintentará el recibo más tarde)
-- El plan solo depende de los datos del servidor: el cliente nunca dice qué se ha comprado.
-- Nunca se entrega dos veces lo mismo: lo que ya tenías se devuelve en monedas (precio real).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Catalog = require(Shared.Economy.CosmeticCatalog)
local Products = require(Shared.Economy.Products)
local BattlePassConfig = require(Shared.Economy.BattlePassConfig)
local MonetizationConfig = require(Shared.Economy.MonetizationConfig)

local Entitlements = {}

local function robuxCompensation(robux)
	return math.floor((tonumber(robux) or 0) * MonetizationConfig.Bundles.CoinsPerRobux)
end

local function newPlan(kind, key)
	return {
		Type = kind,
		Key = key,
		Items = {}, -- { Kind, Id } que se dan
		Coins = 0, -- monedas que se dan (pack, o compensación por lo que ya tenía)
		Compensation = 0, -- (parte de Coins que es compensación)
		Add = {}, -- { Path = {"Campo"...}, Amount = n } números que se suman
		Flags = {}, -- { Path = {"Campo"...}, Value = v }
		Reveal = { Items = {} }, -- lo que enseña la escena de compra
		Message = nil,
		Event = "purchase_success",
	}
end

local function addItems(plan, data, list, isVIP)
	for _, item in list do
		if Catalog.Exists(item.Kind, item.Id) then
			if Catalog.Owns(data, item.Kind, item.Id, isVIP) then
				local coins = Catalog.Compensation(item.Kind, item.Id)
				plan.Coins += coins
				plan.Compensation += coins
			else
				table.insert(plan.Items, { Kind = item.Kind, Id = item.Id })
				table.insert(plan.Reveal.Items, { Kind = item.Kind, Id = item.Id })
			end
		end
	end
end

-- resolved = Products.Resolve(productId); ctx = { IsVIP = bool, Now = os.time() }
function Entitlements.Plan(data, resolved, ctx)
	if not resolved then
		return nil
	end
	ctx = ctx or {}
	local def = resolved.Def
	local plan = newPlan(resolved.Type, resolved.Key)
	if resolved.Type == "Coins" then
		plan.Coins = def.Coins
		plan.Message = "+" .. def.Coins .. " MONEDAS"
		plan.Event = "coin_purchase"
	elseif resolved.Type == "Booster" then
		table.insert(plan.Add, { Path = { def.Field }, Amount = def.Minutes * 60 })
		plan.Message = def.Icon .. " ¡" .. string.upper(def.Name) .. " " .. def.Minutes .. " MIN!"
		plan.Reveal.Title = string.upper(def.Name) .. " · " .. def.Minutes .. " MIN"
		plan.Reveal.Icon = def.Icon
	elseif resolved.Type == "Revives" then
		table.insert(plan.Add, { Path = { "Revives" }, Amount = def.Revives })
		plan.Message = "+" .. def.Revives .. " REVIVIR INSTANTÁNEO"
		plan.Reveal.Title = plan.Message
		plan.Reveal.Icon = "💖"
	elseif resolved.Type == "WheelSpins" then
		local shop = require(Shared.Shop)
		table.insert(plan.Add, { Path = { "WheelSpins" }, Amount = shop.Wheel.SpinsPerPurchase })
		plan.Message = "+" .. shop.Wheel.SpinsPerPurchase .. " GIROS"
	elseif resolved.Type == "Starter" then
		plan.Event = "starter_pack_purchase"
		plan.Coins = def.Coins
		if data.StarterPack then
			-- (compra repetida: Roblox ya cobró, se entregan solo las monedas)
			plan.Message = "+" .. def.Coins .. " MONEDAS"
		else
			addItems(plan, data, Products.BundleItems(def), ctx.IsVIP)
			table.insert(plan.Flags, { Path = { "StarterPack" }, Value = true })
			plan.Message = "¡PACK DE INICIO DESBLOQUEADO!"
			plan.Reveal.Title = "PACK DE INICIO"
		end
	elseif resolved.Type == "Bundle" then
		plan.Coins = def.Coins or 0
		if type(data.Bundles) == "table" and data.Bundles[def.Id] then
			-- (ya lo tenía: solo las monedas que traiga, o lo que vale en monedas si no trae)
			if plan.Coins == 0 then
				plan.Coins = robuxCompensation(def.Robux)
				plan.Compensation = plan.Coins
			end
			plan.Message = "+" .. plan.Coins .. " MONEDAS"
		else
			addItems(plan, data, Products.BundleItems(def), ctx.IsVIP)
			table.insert(plan.Flags, { Path = { "Bundles", def.Id }, Value = true })
			plan.Message = (def.Icon or "📦") .. " ¡" .. def.Name .. " DESBLOQUEADO!"
			plan.Reveal.Title = def.Name
			plan.Reveal.Premium = def.Premium == true
		end
	elseif resolved.Type == "Item" then
		local kind, id = Catalog.ParseKey(resolved.Key)
		addItems(plan, data, { { Kind = kind, Id = id } }, ctx.IsVIP)
		if #plan.Items == 0 then
			-- (lo compró en otro sitio a la vez: lo pagado vuelve en monedas)
			plan.Coins = robuxCompensation(def.Robux)
			plan.Compensation = plan.Coins
		end
		local item = Catalog.Item(kind, id)
		plan.Message = item and ("¡" .. string.upper(item.Name) .. "!") or "¡COMPRA COMPLETADA!"
	elseif resolved.Type == "PassPremium" then
		plan.Event = "battlepass_purchase"
		local pass = data.Pass
		local season = BattlePassConfig.Current(ctx.Now)
		if season and season.Id == resolved.Key and type(pass) == "table" and pass.Season == season.Id and not pass.HasPremium then
			table.insert(plan.Flags, { Path = { "Pass", "HasPremium" }, Value = true })
			plan.Message = "🎖️ ¡PASE PREMIUM ACTIVADO!"
			plan.Reveal.Title = "PASE PREMIUM"
			plan.Reveal.Pass = true
		else
			plan.Coins = robuxCompensation(def.Robux)
			plan.Compensation = plan.Coins
			plan.Message = "+" .. plan.Coins .. " MONEDAS"
		end
	elseif resolved.Type == "TierSkip" then
		plan.Event = "battlepass_purchase"
		local pass = data.Pass
		local season = BattlePassConfig.Current(ctx.Now)
		local room = type(pass) == "table" and season and pass.Season == season.Id and (BattlePassConfig.MaxXP() - pass.XP) or 0
		local amount = math.min(room, (def.Tiers or 1) * BattlePassConfig.XPPerTier)
		if amount > 0 then
			table.insert(plan.Add, { Path = { "Pass", "XP" }, Amount = amount })
			plan.Message = "🎖️ +" .. (def.Tiers or 1) .. " NIVEL DEL PASE"
			plan.Reveal.Title = "NIVEL DEL PASE"
			plan.Reveal.Pass = true
		else
			plan.Coins = robuxCompensation(def.Robux)
			plan.Compensation = plan.Coins
			plan.Message = "+" .. plan.Coins .. " MONEDAS"
		end
	else
		return nil
	end
	-- Bonus de la primera compra con Robux: una tarjeta exclusiva (una vez)
	local bonus = MonetizationConfig.FirstPurchaseBonus
	if bonus and not data.FirstPurchase then
		table.insert(plan.Flags, { Path = { "FirstPurchase" }, Value = true })
		if Catalog.Exists(bonus.Kind, bonus.Id) and not Catalog.Owns(data, bonus.Kind, bonus.Id) then
			table.insert(plan.Items, { Kind = bonus.Kind, Id = bonus.Id })
			plan.Reveal.Bonus = { Kind = bonus.Kind, Id = bonus.Id }
		end
	end
	plan.Reveal.Coins = plan.Coins
	plan.Reveal.Compensation = plan.Compensation
	plan.Reveal.Type = plan.Type
	plan.Reveal.Key = plan.Key
	return plan
end

local function walk(data, path, create)
	local t = data
	for i = 1, #path - 1 do
		local key = path[i]
		if type(t[key]) ~= "table" then
			if not create then
				return nil, nil
			end
			t[key] = {}
		end
		t = t[key]
	end
	return t, path[#path]
end

-- Aplica el plan. Devuelve la función que lo deshace (solo lo que este plan cambió).
function Entitlements.Apply(data, plan)
	local log = {}
	for _, item in plan.Items do
		if Catalog.Grant(data, item.Kind, item.Id) then
			table.insert(log, function()
				Catalog.Revoke(data, item.Kind, item.Id)
			end)
		end
	end
	if plan.Coins ~= 0 then
		data.Coins = (tonumber(data.Coins) or 0) + plan.Coins
		table.insert(log, function()
			data.Coins -= plan.Coins
		end)
	end
	for _, add in plan.Add do
		local t, key = walk(data, add.Path, true)
		t[key] = (tonumber(t[key]) or 0) + add.Amount
		table.insert(log, function()
			local current, k = walk(data, add.Path, false)
			if current then
				current[k] = math.max(0, (tonumber(current[k]) or 0) - add.Amount)
			end
		end)
	end
	for _, flag in plan.Flags do
		local t, key = walk(data, flag.Path, true)
		local before = t[key]
		t[key] = flag.Value
		table.insert(log, function()
			local current, k = walk(data, flag.Path, false)
			if current then
				current[k] = before
			end
		end)
	end
	return function()
		for i = #log, 1, -1 do
			log[i]()
		end
	end
end

return Entitlements
