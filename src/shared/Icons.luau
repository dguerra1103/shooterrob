-- Iconos propios de la interfaz (imágenes subidas a Roblox; los originales están en assets/icons).
-- Donde la interfaz acepta un icono de texto (un emoji) también acepta uno de estos: los componentes
-- del flujo (Components.button, Components.currency, Components.icon) dibujan un ImageLabel cuando el
-- icono empieza por "rbxassetid://". Para cambiar uno, sube la imagen nueva y pega aquí su id.
local Icons = {
	Coin = "rbxassetid://119564566034796",
	Helmet = "rbxassetid://101272569347741",
	Rifle = "rbxassetid://82217394839802",
	Squad = "rbxassetid://109026370206098",
	Cart = "rbxassetid://79728480968299",
	Medal = "rbxassetid://73354953246078",
	Calendar = "rbxassetid://127894742929981",
	Shield = "rbxassetid://120507823383353",
	Gear = "rbxassetid://90191286557913",
	Gift = "rbxassetid://101827535048849",
	Trophy = "rbxassetid://73936573100041",
	Crate = "rbxassetid://122885373307903",
	Star = "rbxassetid://112808557727271",
	Skull = "rbxassetid://137046389059018",
	Crosshair = "rbxassetid://90429847289049",
	Grenade = "rbxassetid://121473914856405",
	-- Rangos (Ranks.Tiers[i].Image), lobby y HUD
	RankBronze = "rbxassetid://111133030764679",
	RankSilver = "rbxassetid://80235852211142",
	RankGold = "rbxassetid://89762985457065",
	RankPlatinum = "rbxassetid://86826419667773",
	RankDiamond = "rbxassetid://80612095791723",
	RankChampion = "rbxassetid://112524468920637",
	Backpack = "rbxassetid://107910389989875",
	Jet = "rbxassetid://93943534209400",
	Shirt = "rbxassetid://125962631327421",
	Friends = "rbxassetid://110106803010338",
	Mail = "rbxassetid://115540682321529",
	Bell = "rbxassetid://125243510330351",
	Bolt = "rbxassetid://90887498032073",
	Medkit = "rbxassetid://97208428540779",
	Knife = "rbxassetid://131311788666550",
	Pistol = "rbxassetid://101149045962121",
	Shotgun = "rbxassetid://128712200332460",
	Sniper = "rbxassetid://74277160950595",
	Launcher = "rbxassetid://119107720365802",
	Flag = "rbxassetid://85023924351801",
	Bomb = "rbxassetid://87820073027783",
	Radar = "rbxassetid://86511689190033",
	Heart = "rbxassetid://140223376194172",
	Stopwatch = "rbxassetid://97752590251406",
	Padlock = "rbxassetid://118587925358341",
	Flame = "rbxassetid://103007412304744",
	Crown = "rbxassetid://97115850135424",
	Bullets = "rbxassetid://104942070526619",
	Boost = "rbxassetid://134117658265151",
	-- Tipos de artículo de la tienda, habilidades y botones varios
	Explosion = "rbxassetid://84569966919105",
	Spotlight = "rbxassetid://133382733218413",
	Pose = "rbxassetid://138476081269399",
	Spray = "rbxassetid://88600923084782",
	Keychain = "rbxassetid://107953755269434",
	IdCard = "rbxassetid://96587274900224",
	Ribbon = "rbxassetid://130136594105134",
	XpBadge = "rbxassetid://132630117672880",
	Dash = "rbxassetid://122083851330282",
	Jump = "rbxassetid://75838984281035",
	Potion = "rbxassetid://78069869686009",
	Smiley = "rbxassetid://88579404361902",
	Clipboard = "rbxassetid://127904163748431",
	Eye = "rbxassetid://113407659056087",
	Home = "rbxassetid://106988332256311",
}

-- ¿Es una imagen (y no un emoji o un texto)?
function Icons.IsImage(icon)
	return type(icon) == "string" and string.sub(icon, 1, 13) == "rbxassetid://"
end

return Icons
