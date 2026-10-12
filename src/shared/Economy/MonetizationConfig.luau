-- Reglas de la monetización (sin pay-to-win). Todo lo que se vende con Robux es estética,
-- colección o presentación: nada cambia daño, vida, retroceso, velocidad ni estadísticas. Un jugador
-- que no paga puede jugarlo todo, progresar y ganar.
--
-- Este módulo solo tiene interruptores y números; los productos con su ProductId y su precio están
-- en Economy/Products, los objetos en Economy/CosmeticCatalog, la rotación en Economy/StoreRotation
-- y el pase en Economy/BattlePassConfig. Ver ECONOMY.md.
local MonetizationConfig = {}

-- La moneda gratis del juego (se gana jugando). No hay otra moneda premium: se paga en Robux.
MonetizationConfig.Currency = { Name = "monedas", Icon = "💰" }

-- Cosas que existían y daban ventaja o azar de pago. Apagadas; los recibos de compras antiguas se
-- siguen entregando (Roblox puede reintentarlos), pero no se vuelven a vender.
MonetizationConfig.Rules = {
	SellRevives = false, -- "Revivir instantáneo" con Robux: volver donde caíste es ventaja en combate
	PaidWheelSpins = false, -- giros de ruleta con Robux: azar de pago
	Wheel = false, -- la ruleta entera (estética de casino: premios "jackpot"); el premio diario la sustituye
	CoinCrates = false, -- abrir cajas con monedas (las monedas se venden con Robux: azar de pago indirecto)
	VIPCrates = false, -- el VIP ya no da cajas extra (azar ligado a un pase de pago): da monedas
	VIPDailyCoins = 100, -- (lo que da el VIP al recoger el premio diario en vez de la caja)
	WeaponsForCoins = false, -- las armas se desbloquean solo por nivel, igual para todos
	PassXPFromPaidBoosts = false, -- el VIP y los potenciadores de pago no aceleran el pase
}

-- Pack de inicio: solo para jugadores nuevos (hasta MaxLevel), una vez. En la portada sale como un
-- aviso pequeño; la tarjeta grande se ve UNA vez (StarterSeen) y luego solo en la tienda.
MonetizationConfig.StarterPack = { MaxLevel = 15, MinMatches = 1 }

-- Bonus de la primera compra con Robux: una tarjeta de jugador exclusiva (no da ventaja). Se dice en
-- la tienda en una línea, sin ventanas.
MonetizationConfig.FirstPurchaseBonus = { Kind = "Card", Id = "PrimerGolpe", Text = "Tu primera compra incluye la tarjeta PRIMER GOLPE" }

-- Packs con Robux de los que ya tienes algo: el precio en Robux no puede cambiar (lo fija el
-- producto), así que lo que ya tenías se devuelve en monedas: su precio en monedas si lo tiene, o
-- sus Robux x CoinsPerRobux. Se dice antes de comprar. Si ya lo tienes TODO no se vende.
MonetizationConfig.Bundles = { CoinsPerRobux = 10 }

-- Oferta pequeña después de la partida ("DOMINASTE CON PHANTOM-X"): solo según lo que hiciste en la
-- partida (el arma con la que más bajas hiciste). Como mucho una de cada EveryMatches partidas, a
-- partir de MinMatches partidas jugadas, y nunca de algo que ya tienes. Se cierra con un toque.
MonetizationConfig.PostMatchOffer = { Enabled = true, MinMatches = 3, EveryMatches = 4, MinWeaponKills = 6 }

-- Tienda diaria: Size objetos al día (iguales para todos, cambian a las 00:00 UTC); el destacado
-- cambia cada semana (lunes 00:00 UTC). Los relojes cuentan hasta esas horas de verdad.
MonetizationConfig.DailyStore = { Size = 6 }

-- Venta de niveles del pase: solo dentro de la pantalla del pase, un nivel por compra.
MonetizationConfig.TierSkip = { Enabled = true }

-- Etiqueta NUEVO: los objetos que entran en el catálogo llevan NUEVO hasta que los ves en la tienda.
MonetizationConfig.NewItems = {
	"Skin:Inferno", "Skin:Ciber", "Skin:ArticoTactico", "Skin:Callejero", "Skin:GrietaVacio", "Skin:OperacionRoja",
	"Outfit:OperacionRoja", "Outfit:ArticoTactico",
	"Charm:Chapa", "Charm:Bala", "Charm:Calaverita",
	"KillEffect:Pixel", "KillEffect:OroFlash", "KillEffect:ChoqueRojo",
	"Pose:Bajada", "Pose:AlCielo", "Pose:Saludo", "Pose:Brazos", "Pose:Senala",
	"MVPIntro:Giro", "MVPIntro:Ascuas", "MVPIntro:Columna",
	"Card:Tactico", "Card:Carbono", "Card:Neon", "Card:Glaciar", "Card:Infierno", "Card:Oro", "Card:Vacio",
}

-- Analítica: solo nombres de evento y datos del juego (ids de objetos, precios, pestañas). Nada
-- personal. El cliente solo puede mandar estos eventos y como mucho ClientPerMinute por minuto.
MonetizationConfig.Analytics = {
	Enabled = true,
	ClientPerMinute = 30,
	ClientEvents = {
		store_open = true,
		item_preview = true,
		purchase_prompt = true,
		purchase_cancel = true,
		bundle_view = true,
		battlepass_open = true,
		starter_pack_view = true,
	},
	-- (los que solo manda el servidor, cuando algo pasa de verdad)
	ServerEvents = {
		purchase_success = true,
		battlepass_purchase = true,
		starter_pack_purchase = true,
		coin_purchase = true,
		battlepass_claim = true,
	},
}

return MonetizationConfig
