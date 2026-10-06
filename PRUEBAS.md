# Cómo probar las novedades en Roblox Studio

Abre `ShooterRob.rbxlx` (o conecta Rojo) y usa estas dos formas de probar:

- **Jugar solo**: botón **Play** (F5). Con un solo jugador entran **bots** hasta llenar la partida (10: 5 contra 5), así
  que se puede probar casi todo sin nadie más.
- **Varios jugadores**: pestaña **Test → Clients and Servers → Local Server** con **2 o 3 jugadores**. Sirve
  para equipos, marcador, espectar y pantalla de muerte entre jugadores.

Para no esperar, en `src/shared/GameConfig.luau` puedes bajar temporalmente `IntermissionTime` (por
ejemplo a 5) y los `RoundTime` de `ModeSettings`. Para forzar un modo, pon `Modes = { "ELIM" }` (o el que
quieras probar) y vuelve a dejarlo como estaba al acabar.

## Lista rápida

| Qué | Cómo comprobarlo | Qué debería pasar |
|---|---|---|
| **Bots** | Play solo y pulsa JUGAR | Aparecen bots con nombre "Bot …" en los dos equipos; caminan, te disparan (fallan más de lejos) y se pueden eliminar. Al entrar un segundo jugador se quita un bot de su equipo. |
| **Bots realistas (5 contra 5)** | Play solo en Construction, Duelo por equipos | Tu equipo y el rival tienen 5 cada uno (tú + 4 bots). Los bots se reparten por las tres rutas; el tirador sube a una ventana o altura y se queda vigilando; los de subfusil y escopeta corren hacia ti. Si disparas cerca de un bot que no te ve, se gira y viene. Disparan en ráfagas de lejos, recargan (se nota la pausa), se esconden si les dejas con poca vida y vuelven, y si te escondes tras una esquina a veces te tiran una granada. |
| **Los 9 mapas 5v5** | Vota cada uno (o ponlo primero en `MapBuilder.Order`) | Construction, Coastal, Terminal, Mall Rush, Rooftop District, Metro Yard, Desert Base, Dockyard e Industrial Yard. En cada uno: sales en una base cerrada (desde fuera no se ve dentro), hay 2-3 rutas a cada sitio, los letreros A/B se ven de lejos, ninguna escalera ni puerta atasca, no hay sitios donde caerse y no se puede subir a tejados ni pilas de contenedores con el supersalto (te para una pared invisible). Qué mirar en cada mapa y lo pendiente: `MAP_DEVELOPMENT.md`. |
| **Minimapa** | En partida | Arriba a la izquierda, con los edificios del mapa; tu flecha gira con la cámara; tus compañeros en azul; cuando un enemigo dispara (sin silenciador) aparece un punto rojo unos segundos; con el Radar de la racha se ven todos. PASE · TIENDA queda justo debajo. |
| **Escala y alturas** | Recorre las zonas altas (torre de Construction, azoteas de Rooftop, pasarela de Metro Yard, azotea del cuartel de Desert Base, azotea del control de Dockyard, pasarela de Industrial Yard) | Las escaleras se suben sin saltar, las barandillas no dejan caer y desde arriba se ve el sitio que vigila esa posición, pero no la base enemiga. |
| **Pasos de los bots** | Partida con bots, quieto detrás de una pared | Se oyen los pasos de un bot enemigo que se acerca corriendo (más alto que los de tus compañeros). |
| **Destello de la mira** | Desert Base o Dockyard con bots | El bot tirador enemigo, apostado en una torre o una azotea, brilla cuando mira hacia ti; si se mueve o mira a otro lado, el destello se apaga. |
| **Aviso de granada** | Partida con bots | Cuando un bot te lanza una granada aparece un 💣 rojo alrededor de la mira señalando dónde está; aléjate y desaparece. Tus granadas no lo muestran. |
| **Bots que se agachan** | Construction o Desert Base, a distancia de un bot | El tirador (y a veces los de fusil) se agacha mientras te dispara y se levanta al moverse. |
| **Pantalla final** | Termina una partida (baja `ModeSettings.TDM.ScoreToWin` para ir rápido) | Tras la killcam: fundido, la cámara enseña a tu equipo en su base (tus avatares con su arma), VICTORIA + "L Í M I T E   D E   P U N T O S…", 100 VS 72 contando, tarjetas, MVP con corona y destello, recompensas (+XP, +monedas, caja si tocó, ±RP), barra de nivel (sube con destello si toca), desafíos y desbloqueo solo si los hubo. VER MARCADOR abre la tabla de los dos equipos. JUGAR DE NUEVO o, sin tocar nada, al acabar la pantalla pasa sola a buscar la siguiente (CANCELAR lo evita). En Buscar y destruir el motivo es el de la última ronda (BOMBA DESACTIVADA, OBJETIVO COMPLETADO, RONDA DECISIVA GANADA). |
| **Bomba plantada** | Buscar y destruir: planta la bomba | Aparece la bomba en el suelo con una luz roja que parpadea y pita; los pitidos se aceleran al final. Al explotar o desactivarse desaparece. |
| **Portador de la bomba** | Buscar y destruir atacando | Arriba pone si llevas tú la bomba («💣 LLEVAS LA BOMBA») o quién la lleva. Si el portador muere, la bomba queda en el suelo (💣 en el minimapa y encima del sitio) y la recoge el primer atacante que pase por encima. Un atacante sin la bomba no puede plantar. |
| **Versiones de luz** | Juega varias partidas en el mismo mapa | A veces la presentación pone «· Atardecer» o «· Noche» (en Industrial Yard, «· Día») y el mapa sale con esa luz: la geometría es la misma, solo cambian la luz y las luces encendidas (ventanas, focos, marquesinas). |
| **Sonido ambiente** | Juega en Coastal o Dockyard, Rooftop District y Desert Base | Olas en la costa y el puerto, viento de altura en las azoteas, viento seco en el desierto. En la pantalla de inicio no suena. |
| **Muñeco de trapo** | Elimina a un bot (y deja que te eliminen) | El cuerpo cae doblándose de forma natural en vez de romperse en piezas; con una granada sale despedido. El bot desaparece a los pocos segundos. |
| **Flujo de partida** | Play → JUGAR | BUSCANDO PARTIDA (con la votación) → al construirse el mapa, PARTIDA ENCONTRADA (destello y sonido) → nombre del mapa en grande → TU EQUIPO VS RIVALES con los personajes → ELIGE TU CLASE (la última marcada) → PREPÁRATE 3-2-1 ¡YA! y la cámara baja a tu espalda. Todos salen a la vez. En Eliminación la cuenta es la preparación de la ronda. |
| **Escuadra, Armamento, Operador** | Lobby → ESCUADRA / ARMAMENTO / OPERADOR | Escuadra: tus compañeros en 3D con LISTO/NO LISTO y 👑. Armamento: elige categoría y arma, las barras se animan; EQUIPAR EN CLASE n la pone en esa clase. Operador: roles, el traje sobre tu avatar, EQUIPAR o COMPRAR. Esc/B vuelve. |
| **Móvil** | Studio → Device Emulator, un teléfono apaisado | Lobby compacto (5 botones), textos legibles, nada se solapa; en partida, los botones táctiles de siempre. |
| **Medallas** | Duelo por equipos | La primera baja de la partida da «🩸 PRIMERA SANGRE»; si eliminas a quien te mató, «😤 VENGANZA»; un francotirador a lo lejos, «🔭 LARGA DISTANCIA». Las placas salen bajo «ELIMINADO» y se van solas, con su +XP. |
| **Radar de los bots** | Duelo por equipos con bots | Cuando un bot enemigo hace 3 bajas seguidas sale «📡 ¡El enemigo tiene radar!» y durante 12 s los bots rivales van directos a donde estás; si es un bot de tu equipo, ves el radar tú también. Mientras dura el radar enemigo, el minimapa tiene borde rojo y pone «📡 RADAR ENEMIGO». |
| **Buscar y destruir: salida escalonada** | `Modes = { "SND" }` en un mapa con los sitios a la misma distancia (todos menos Mall Rush) | Al empezar cada ronda los atacantes esperan 3 s («Los defensores se colocan…») mientras los defensores ya se mueven. En Mall Rush cada equipo defiende el sitio de su mitad y salen a la vez. |
| **Votación** | Espera al descanso entre partidas | La primera opción es siempre uno de los nueve mapas 5v5 con Duelo por equipos, Dominio o Buscar y destruir. |
| **Buscar y destruir** | `Modes = { "SND" }` y Play solo en Construction | "💣 ATACAS: planta la bomba en A o B" (o DEFIENDES). Ve al sitio (anillo amarillo con 💣A / 💣B, también en el minimapa) y quédate dentro: "PLANTANDO EN A..." y a los 4 s "¡BOMBA PLANTADA EN A!" con cuenta atrás de 35 s. Si defiendes, quédate junto a la bomba 6 s: "¡BOMBA DESACTIVADA!". A la ronda siguiente se cambian los papeles. Los bots atacan juntos y defienden. |
| **Dominio** | `Modes = { "DOM" }` y Play solo en Construction | "🏴 ¡DOMINIO!". Arriba, tres insignias A B C. Quédate en la A: la barra se llena en ~5 s y pasa a tu color ("🚩 Rojo captura A", +50 XP). Tu marcador sube 1 punto cada 3 s por bandera. Si entra un enemigo, la letra sale con "!" y la captura se para. Los bots van a por B y C y defienden las suyas. |
| **Ventajas** | Ajustes → Ventaja → elige cada una y juega | Ligero: corres algo más. Persistente: tras recibir daño la vida sube antes. Fantasma: con dos jugadores (Local Server), el otro no te ve en rojo en su minimapa al disparar. La elección se recuerda al volver a entrar. |
| **Disparo automático** | Ajustes → Disparo automático → Siempre (en PC) o juega en el móvil; apunta a un bot enemigo sin pulsar | El arma dispara sola mientras la mira está sobre él; sobre un compañero, no. Con "No", nunca. |
| **Presentación de la partida** | Pulsa JUGAR y espera a que empiece la ronda | Pantalla oscura unos segundos: ENCRUCIJADA / Duelo por equipos, EQUIPO ROJO con tu nombre en amarillo y sus bots, "5 VS 5" y EQUIPO AZUL. Se desvanece sola. |
| **Apariciones dinámicas** | Duelo por equipos en Construction; muere varias veces | La primera vez sales en tu base. Después reapareces por el mapa, cerca de tus compañeros y lejos de los enemigos (no al lado de uno). |
| **Agacharse** | Anda y pulsa C; luego corre y pulsa C | Andando: la cámara baja, vas despacio y la mira se cierra un poco; C otra vez o correr te levanta. Corriendo: te deslizas como antes. Otro jugador (Local Server) te ve más bajo. |
| **Vida que se recupera** | Recibe daño y escóndete | A los 4 s sin daño la vida sube sola hasta 100 en unos 2 s. |
| **Eliminación** | `Modes = { "ELIM" }` | "RONDA 1 · ¡Una sola vida!", cuenta atrás con todos quietos (no se puede disparar ni saltar), "¡YA!". Al morir no hay Regenerar ni Revivir: se observa a compañeros. La ronda se la lleva el equipo que quede en pie. Arriba: "En pie: Rojo X – Y Azul". |
| **Marcador** | Mantén **Tab** | Dos columnas por equipo (o una lista en Todos contra todos) con bajas, muertes y K/D; los bots salen con 🤖 y tu fila en amarillo. |
| **Regalos por jugar** | Espera 2 minutos en partida | El botón 🎁 de la izquierda cuenta hacia atrás; al llegar a 0 late y se recoge con **H** (+40 monedas). Si sales y vuelves a entrar el mismo día, no se reinicia. |
| **Pantalla final en el móvil** | Device Emulator, teléfono apaisado; termina una partida | VICTORIA, marcador, MVP, recompensas, nivel y JUGAR DE NUEVO; los compañeros, desafíos y desbloqueos, en el marcador (botón MARCADOR). Nada se solapa. |
| **Splat-X** | Menú (B) → Armas → Splat-X (nivel 2) | Dispara bolas de pintura: manchas de colores en paredes y suelo que se desvanecen a los 5 s. |
| **Skins animadas** | Menú → Skins → Arcoíris o Prisma (cómpralas con monedas: en Studio puedes darte monedas desde la consola, ver abajo) | El arma cambia de color sin parar (en la mano, en la tienda y en las armas de los demás). |
| **Armas cuerpo a cuerpo** | Menú → Armas → abajo: Martillo de juguete o Katana (dátelas con nivel/monedas, ver abajo) | Al reaparecer llevas esa arma en la ranura 3; la F golpea con ella (la katana llega más lejos). |
| **Tarjeta de controles** | Entra en partida con un jugador nuevo | Sale una tarjeta con los controles; "¡A JUGAR!" la cierra. En Studio sin DataStore activado sale cada vez (es normal). |
| **Evento de Halloween** | Juega una ronda | Aparecen caramelos que flotan y brillan; al tocarlos: "🍬 Caramelo +5 🪙 (1/100)" y sube el contador de abajo a la izquierda, que dice el siguiente premio ("→ Traje" a los 50). Hay calabazas en el mapa. |
| **Infección (zombis)** | `Modes = { "INF" }` y Play solo | "La infección empieza en…", y al llegar a 0 un bot (o tú) se convierte en zombi verde con ojos rojos y garras. Arriba: supervivientes contra zombis. Si te alcanzan, reapareces como zombi (brazos verdes, solo garras, sin granadas). Ganan los supervivientes si queda alguno al acabar el tiempo. |
| **Calabazas** | `Modes = { "CAL" }` y Play solo | "🎃 ¡CALABAZAS!". Cada eliminado deja una calabaza flotando sobre un anillo de su color. Si pasas por encima de la de un enemigo: punto para tu equipo y "+60 XP 🎃 Calabaza confirmada"; la de un compañero: "Calabaza recuperada" sin punto. Los bots corren a por ellas. Desaparecen a los 30 s. |
| **Ruleta diaria** | Lobby → EVENTOS (o el aviso 🎡 RULETA GRATIS) | Gira unos segundos con clics y se para en un premio ("¡Has ganado 100 🪙!"). El segundo giro del día dice "Vuelve mañana" (los giros con Robux salen cuando pongas `Shop.Wheel.SpinProductId`). |
| **Colgantes** | Menú → Skins → abajo, compra la Calabacita y reaparece | Una calabacita cuelga del lateral del arma y se balancea al girar rápido la cámara. Los demás también la ven. |
| **Rangos** | Termina una partida | En el resumen sale tu rango (🥉 BRONCE) y los RP ganados; contra bots +8 si ganas. En la pantalla de inicio: "🥉 Bronce (8 RP)". El icono sale también en el marcador (Tab) y en el chat. |
| **Pantalla de arranque** | Play | «SHOOTER NEW» con la barra por fases (CARGANDO INTERFAZ → ARMAS → MAPAS → PREPARANDO PARTIDA), un consejo y el mapa desenfocado; se va en cuanto el lobby está listo. |
| **Novedades** | Con datos guardados de antes (o pon `NewsSeen = 0` desde la consola) | En la pantalla de inicio sale la tarjeta "¡NOVEDADES DE HALLOWEEN!"; "¡A JUGAR!" la cierra y no vuelve a salir. |
| **Bots en Captura la bandera** | `Modes = { "CTF" }` y Play solo | Los bots van a por tu bandera, se la llevan a su base y puntúan; si los eliminas, la bandera cae. |
| **Escalada de armas solo** | `Modes = { "GUN" }` | Hay bots; cada baja (también a bots) te sube de arma. |
| **Guadaña y Calabazooka** | Menú → Armas | Guadaña (cuerpo a cuerpo, 1500 monedas). Calabazooka (lanzacohetes) sale bloqueada con "🎃 75 caramelos"; al conseguirla dispara calabazas. |
| **Mira** | Menú → Ajustes → Mira | Cambia el color (6) y el tamaño; se nota al momento en la mira. |
| **SE BUSCA** | Play solo, haz 5 bajas seguidas sin morir | Arriba: "💰 SE BUSCA: tú · 25 🪙 por su cabeza" y en grande "¡TE BUSCAN!". Los bots van más a por ti. Con 2 jugadores (Local Server), el otro ve un cartel rojo sobre tu cabeza; si te elimina, "¡RECOMPENSA COBRADA! +25 🪙". |
| **Retos semanales** | Menú → Retos | Debajo de los 3 retos de hoy: "📅 RETOS DE LA SEMANA · nuevos en Xd Yh" con 3 retos azules más largos (barras de progreso que avanzan al jugar) y la caja de premio por completarlos. |
| **Títulos** | Menú → Perfil → abajo | Rejilla de títulos: Novato elegido; los que no tienes con 🔒 y lo que falta ("100 bajas") o su precio. Compra "Payaso de feria" (800): queda elegido y en el marcador (Tab) sale rosa junto a tu nombre. |
| **Indicador de daño** | Play solo y deja que un bot te dispare de lado o por la espalda | Alrededor de la mira sale una marca roja con una flecha que apunta hacia el bot (a la derecha, abajo si está detrás…) y se desvanece en algo más de 1 s. Con el escudo de reaparición no sale. |
| **Asistencias** | Dispara a un bot y deja que otro bot o un compañero lo remate | "🤝 ASISTENCIA Bot …" en azul y "+20 XP Asistencia" (contra bots vale la mitad). Perfil → Asistencias sube. |
| **Pack de Halloween** | Pon un ID en el `ProductId` del pack de Halloween (`Shop.Bundles`, el primero) y abre la Tienda | Arriba del todo, tarjeta naranja-morada "🎃 PACK DE HALLOWEEN · quedan X días" con lo que trae. En Studio la compra de prueba entrega 2500 monedas, el efecto Calabazas, la Calabacita y el grafiti Calabaza, y la tarjeta desaparece. |
| **Pack Aventurero** | Pon un ID en el `ProductId` del pack Aventurero (`Shop.Bundles`, el tercero) y abre la Tienda | Arriba, tarjeta "🏴‍☠️ PACK AVENTURERO · ¡NUEVO!" con los tres trajes y el resto; al comprarlo (compra de prueba en Studio) tienes Sheriff Vaquero, Capitán Pirata y Caballero Real en Trajes. |
| **Traje Caballero Real** | Menú → Trajes → Caballero Real (2600 monedas) | Yelmo plateado con rendija y penacho azul, sobreveste azul con rombo dorado, hombreras, guanteletes y capa. |
| **Traje Capitán Pirata** | Menú → Trajes → Capitán Pirata (2400 monedas) | Tricornio negro con calavera, parche en el ojo, barba, casaca roja con botones dorados y faldones detrás. |
| **Traje Sheriff Vaquero** | Menú → Trajes → Sheriff Vaquero (2200 monedas) | Sombrero de vaquero marrón con cinta dorada, pañuelo rojo, chaleco de cuero abierto con estrella dorada y cartuchera en la pierna derecha. |
| **Te faltan monedas** | Con algún pack de monedas con ID puesto, intenta comprar algo caro sin monedas suficientes | Sale "Te faltan N monedas" y al momento el menú pasa a la Tienda, bajado hasta los packs de 🪙 Monedas. |
| **Efecto Rodadora** | Menú → Efectos → Rodadora (900) → "Ver" | Polvareda color arena, bolas de matojos que salen rodando, un 🤠 que sube y un 🌵. |
| **Grafitis** | En partida, mira una pared cerca y pulsa **J** | Aparece un círculo azul con "GG" pintado en la pared. Menú → Efectos → abajo: compra la Calabaza y pulsa J otra vez (a los 6 s): el anterior desaparece y sale la calabaza con "BOO!". |
| **Premio del grupo** | Pon el ID de tu grupo en `GameConfig.Group.Id` y publica (en Studio el grupo puede no comprobarse) | En la pantalla de inicio sale ⭐ ÚNETE AL GRUPO +500 🪙. Si ya estás en el grupo: "✅ ¡+500 🪙! Gracias" y el botón desaparece. Si no, sale la ventana de Roblox para unirte. |
| **Pase de 50 niveles** | Menú → Pase | Los niveles cercanos al tuyo; al final "… y N niveles más". |
| **Pantalla de muerte** | Muere con la tienda abierta | La tienda se cierra sola y la B no gasta un revivir al cerrarla. |
| **Ballesta** | Menú → Armas → Ballesta (nivel 9 o 2000 monedas) | Arco de metal con cuerda y virote de punta roja. Un disparo y recarga sola; a la cabeza mata de un tiro. |
| **Invitaciones** | Hace falta publicar y una cuenta nueva: invita a un amigo con 👥 INVITA | Cuando entra por primera vez: a él "¡Te invitó …! +500 🪙" y a ti "¡… entró con tu invitación! +500 🪙". |
| **Potenciadores** | Pon un ID en `ProductId` de `Shop.Boosters` (en Studio la compra es de prueba) y cómpralo en la Tienda | "⚡ ¡XP DOBLE 30 MIN!", debajo del marcador "⚡ x2 XP 29:59" bajando (se para en la portada) y la XP de cada baja sale el doble. La tarjeta dice "✔ Activo: quedan N min". |
| **Mapa destacado** | Mira la portada (debajo de la ruleta: "⭐ Hoy: <mapa> +25% XP") y juega hasta que en la votación salga ese mapa | La tarjeta dice "⭐ Mapa del día: más XP"; al empezar en ese mapa sale "⭐ ¡MAPA DESTACADO DE HOY! +25% XP" y cada baja da un 25% más de XP. |
| **Primera victoria del día** | Pantalla de inicio, y luego gana una partida | En el lobby, el aviso "🏆 1.ª VICTORIA +150 🪙". Al ganar: "🏆 ¡Primera victoria del día! +150 🪙" y el texto de la portada desaparece hasta mañana. |
| **Caja sorpresa** | Juega varias partidas enteras | De vez en cuando (y como mucho a las 15 partidas) sale en grande "🎁 ¡CAJA SORPRESA!" y en la Tienda tienes una caja gratis más. |
| **Premio de regreso** | Con el guardado activado, en la consola del servidor: `require(game.ServerScriptService.Server.Modules.PlayerData).Get(game.Players:GetPlayers()[1]).LastPlayDay -= 5`; para el juego y vuelve a darle a Play | A los pocos segundos de entrar: "👋 ¡BIENVENIDO DE VUELTA! Regalo por volver: +400 🪙, 1 caja gratis y ⚡ XP doble 30 min" (y debajo del marcador "⚡ x2 XP 30:00" al entrar en partida). |
| **Roblox Premium** | Menú → Tienda → abajo del VIP | Tarjeta "⭐ Roblox Premium · +20% monedas y XP" con el botón "Hazte Premium" (o "✔ Bonus activo" si tu cuenta ya es Premium). |
| **Disparos y retroceso** | Dispara ráfagas largas con el ARX-27 contra una pared, y luego tiros sueltos con el francotirador | En la ráfaga la mira sube y tira a un lado siempre de forma parecida (se puede compensar bajando el ratón); al soltar, la mira baja sola buena parte. El arma da un golpe con rebote en la mano. El primer tiro quieto va al centro de la mira; corriendo los tiros se abren. El francotirador sacude la cámara y suena el cerrojo tras cada disparo. |
| **Movimiento realista** | En partida, anda, corre (Shift) sin parar y salta desde una azotea | Al arrancar acelera en vez de ir a tope de golpe; la cabeza se balancea un poco al andar y más al correr; corriendo aparece una barra fina bajo la mira que baja y a los ~6 s se pone roja: dejas de correr y saltas menos hasta recuperarte. De lado o hacia atrás no se corre. Al caer desde alto: golpe de cámara, sonido de aterrizaje y un frenazo breve. |
| **Killcam** | Deja que un bot te elimine (en Duelo por equipos); luego en Eliminación, y con una granada | Unos 2 s en blanco y negro desde la posición del bot mirando hacia ti (se ve tu cuerpo, no el del bot), con «▶ KILLCAM» y «Bot … · arma»; luego la pantalla de muerte normal. Un clic o un toque la salta. En Eliminación o con granada no sale. |
| **Killcam final** | En Duelo por equipos, baja el objetivo de puntos (`ModeSettings.TDM.ScoreToWin = 3`) y elimina a 3 bots; en Eliminación, gana una ronda eliminando al último | Al hacer la baja que cierra la partida o la ronda, todo se congela y se ve la repetición desde tus ojos (o los de quien la hizo) con «▶ KILLCAM FINAL»; luego sale la pantalla final o la siguiente ronda. |
| **Uniforme militar** | Juega sin traje equipado | Apareces con uniforme de soldado y el brazalete de tu equipo. En Ajustes → 🪖 «Mi avatar», al reaparecer vuelves a tu avatar. Con un traje comprado, sale tu traje. |
| **Asistencia de apuntado** | Studio → Test → Device (teléfono). Pon la mira cerca (sin tocarlo) de un bot enemigo y apunta con 🎯 | La mira se va sola hacia el pecho del bot; al empezar a apuntar da un saltito hacia él. Con un compañero o detrás de una pared, nada. Con ratón (PC), nada. En Ajustes se puede poner Suave o No. |
| **Apuntar con realismo** | Apunta (clic derecho / 🎯) a una pared cercana y luego a lo lejos | Lo lejano se ve algo borroso y lo que miras nítido; los bordes de la pantalla se oscurecen. Con el Signal-7 (visor) no cambia. |
| **Eco del sitio** | Con auriculares, dispara en la calle y luego dentro de la nave de Construction o del almacén de Desert Base | Dentro, el disparo retumba más (eco de habitación); fuera, eco de ciudad. |
| **Aturdimiento y supresión** | Lanza una granada (G) a unos pasos de ti, sin que te mate; luego deja que un bot te dispare de lejos | Con la explosión: destello, imagen borrosa un momento, pitido y todo suena apagado 2-3 s. Con las balas que pasan cerca: un parpadeo de desenfoque. Con poca vida se oye el latido. |
| **Efectos de pantalla reducidos** | Ajustes → 👁 Efectos de pantalla → Reducidos; apunta y lanza una granada cerca | Sin desenfoque al apuntar ni destello/desenfoque con la explosión (el sonido sí se apaga). |
| **Fogonazo y trazadoras realistas** | Dispara una ráfaga larga con el fusil contra una pared y suelta | Fogonazos cortos y distintos en cada disparo; rayas cálidas en una de cada tres balas; al soltar, un hilo de humo sube del cañón. |
| **Recarga táctica** | Con el fusil, dispara 5 balas y recarga (R); luego vacía el cargador y recarga | La primera recarga es más corta (barra del HUD más rápida); la de vacío tarda más y monta el arma al final. |
| **Granada cocinada** | Mantén G 1,5 s y suelta junto a un bot; luego un toque rápido | Mientras la mantienes, el indicador cuenta hacia atrás en rojo y pita cada vez más rápido; al soltar, explota casi al caer. Con un toque, sale con la mecha entera como siempre. |
| **Se oye a quien recarga** | Con auriculares, acércate a un bot detrás de una pared mientras gasta el cargador | Al recargar se oye su cargador (fuera y dentro) en su posición. Al disparar una ráfaga, se oyen los casquillos caer. |
| **Avisos de los compañeros** | En Duelo por equipos con bots, mira a un compañero bot durante un tiroteo | Cuando recarga sale «🔄 ¡Recargando!» sobre su cabeza; si lanza una granada, «💣 ¡Granada!». Los enemigos no muestran nada. |
| **Linternas de noche** | Juega un mapa en su versión de noche | Tu arma ilumina lo que tienes delante con sombras; L la apaga. Los bots llevan la suya: se ven sus haces de luz a lo lejos. |
| **Visor de francotirador realista** | Con el Signal-7, apunta con el visor a un punto lejano; luego mantén Mayús | La mira se mueve un poco sola; con Mayús se queda quieta unos segundos («Aguantando la respiración…») y al acabarse el aire se mueve más («Sin aire…»). |
| **Soldados con el arma a dos manos** | Juega con bots (o con otro jugador en Test → Clients and Servers) y míralos de cerca | Llevan el fusil con la culata al hombro y las dos manos en el arma (no con un brazo estirado); con pistola, los brazos al frente. El arma se ve de tamaño real al lado del cuerpo. Si algo se ve raro, `GameConfig.TwoHandedPose = false`. |
| **Tu cuerpo en primera persona** | En una partida, mira hacia el suelo y camina | Ves tus piernas y botas moviéndose; al agacharte (C) desaparecen. |
| **Efectos de recompensa** | Haz bajas a bots, varias seguidas; abre cajas; sube de nivel (consola: `PD.AddXP(p, 5000, "Prueba")`) | Con 10 bajas sin morir, «🔥 ¡RACHA DE 10!». Al disparar a un bot, su cuerpo destella en blanco con cada impacto (rojo al eliminarlo) y el número de daño se suma en uno solo que crece. Cada baja: destello en los bordes, X que entra girando, chispas donde cae y un golpe grave; las seguidas, aviso más grande y de otro color. Arriba de los avisos de XP, un "+150" que cuenta hacia arriba. Al subir de nivel, rayos, confeti y fanfarria. La barra de nivel de abajo pone «Próximo: …». En la caja, si sale Épico o mejor, celebración. Haz más bajas que en tu mejor partida (al menos 5): en el resumen, «🏆 ¡NUEVO RÉCORD!». Las monedas del resumen vuelan al contador. En el panel de retos de la izquierda, cada baja que cuenta hace saltar el contador. Con un arma a 22-24 bajas, sale «🎯 …: ¡N bajas para el camuflaje Carbono!». En Tienda, el premio diario muestra los 7 días (el de hoy latiendo); al reclamarlo, celebración. Con el premio diario sin recoger, la pestaña Tienda pone «Tienda 🔴1». Al llegar a 10 bajas totales en partida: «🏅 ¡LOGRO! 🎯 Consigue 10 bajas». En Eliminación, queda el último de tu equipo contra 2 o más: «⚔ 1 CONTRA N»; si ganas la ronda, «🔥 ¡CLUTCH!». Al empezar la partida, tras la presentación, «¡A LUCHAR!». Si eres el MVP, celebración. Al ganar una partida, confeti; en el resumen, «Solo te faltan X XP para el nivel N». |
| **Botín** | Elimina varios bots (para probar rápido, en la consola de servidor: `require(game.ServerScriptService.Server.Modules.Loot).BotChance = 1`) | Sale «📦 ¡Botín …! Pasa por encima para cogerlo» y un paquete girando con un rayo de luz de color donde cayó. Al pasar por encima: «📦 Botín … +N 🪙». Otro jugador no puede cogerlo; a los 15 s desaparece. |
| **Efectos en el móvil** | Studio → Test → **Device** → un teléfono en horizontal; haz bajas seguidas, sube de nivel y termina una partida | Nada tapa los botones táctiles ni el joystick: munición y vida abajo en el centro, minimapa pequeño debajo de los botones de Roblox, «⭐ TIENDA» pequeño, sin panel de retos, botones con iconos que caben, todos presentes (también 💣 granada, 📋 marcador, 😀 emotes y 🎨 grafiti) y sin pisarse; el ✈ sale cuando tienes un ataque aéreo. El aviso de baja sale por encima de la mira (no encima de los botones de habilidades), el "+250" a la derecha de la mira, como mucho 2 avisos de XP debajo. Las celebraciones caben en la pantalla. En el resumen final, confeti sin taparlo y sin los botones de habilidades encima. |
| **Sonido de las armas** | Con auriculares: dispara cada arma, recarga con el cargador vacío y a medias, cambia de arma y deja que un bot te dispare de cerca y desde lejos | Cada arma suena distinta y con "cuerpo" (el francotirador y la escopeta retumban). Recarga: se oye sacar y meter el cargador, y montar el arma si estaba vacía; la escopeta mete cartuchos. Al sacar un arma suena; con pocas balas, un "tic" en cada disparo. Los disparos lejanos llegan algo después y apagados; las balas enemigas que pasan cerca hacen "fiuu". Si algún sonido no suena o suena raro, cambia su id o tono en `Sounds.luau`. |
| **Animación de las armas** | Recarga cada arma con el cargador vacío y a medias; dispara la pistola hasta vaciarla; dispara la escopeta y el francotirador; pégate a una pared; salta; corre; da dos cuchilladas seguidas | El cargador cae y la mano izquierda trae otro (vacía: además se monta el arma); la escopeta mete cartuchos y bombea; la corredera de la pistola se mueve en cada tiro y se queda atrás sin balas; el francotirador mueve el cerrojo con la mano. Contra la pared el arma se recoge apuntando arriba; al saltar se queda atrás y al caer se hunde; corriendo se balancea más. Las dos cuchilladas van a lados opuestos. Nada atraviesa la cámara ni queda descolocado. |
| **Tablet** | Studio → Test → **Device** → un iPad | Los botones táctiles (disparar, apuntar, recargar...) quedan a la izquierda del botón de saltar, que en tablet es más grande; ninguno lo tapa. |
| **Móvil** | Studio → Test → **Device** (emulador de teléfono) | Botones táctiles: 😀 emotes, 📋 marcador, 🎁 pequeño arriba a la izquierda; nada tapado por el joystick. |

## Tienda y pase (monetización sin pay-to-win)

Todo el detalle en `ECONOMY.md`. En Studio las compras con Robux son de prueba (no cobran): para
probarlas pon ids de productos de prueba (o los reales) en `src/shared/Economy/Products.luau` y
`Shop.luau`; con id `0` sale "PRÓXIMAMENTE".

| Qué | Cómo comprobarlo | Qué debería pasar |
|---|---|---|
| **Tienda** | Lobby → TIENDA | DESTACADO con el evento (Operación Zona Roja hasta el 3 nov), pack de la semana, pack de inicio (si eres nivel ≤ 15) y tienda diaria con su reloj ("NUEVA EN 5 H 12 MIN", hasta las 00:00 UTC). Pestañas ARMAS, OPERADORES, CHARMS, EFECTOS, POSES, PACKS, PASE y MONEDAS. |
| **Previsualizar** | 👁 en cualquier objeto | Arma en 3D que se gira arrastrando y se acerca con la rueda / pellizco / + −, con ◀ ▶ para verla en tus armas; traje y poses en tu personaje; intro de MVP en bucle; PROBAR en los efectos de baja. Dice "Solo estética". Esc o CERRAR. |
| **Compra con Robux** | COMPRAR en un objeto con id | Se abre la ventana de Roblox. Si cancelas, el botón vuelve a COMPRAR y no te dan nada. Si compras: COMPRA COMPLETADA → objeto → nombre → rareza → EQUIPAR AHORA → EQUIPADO ✓. La primera compra regala la tarjeta PRIMER GOLPE. |
| **Compra con monedas** | COMPRAR en un objeto con 🪙 | Ventana de confirmación con lo que te queda; CANCELAR no compra; CONFIRMAR compra y sale la escena de compra. Sin monedas suficientes no deja confirmar. |
| **Ya lo tienes** | Mira algo que ya tengas | Dice EQUIPAR / EQUIPADO ✓, nunca COMPRAR. En los packs, lo tuyo sale con ✓ TUYO y se dice cuántas monedas te devuelven. |
| **Pase** | Lobby → PASE DE BATALLA | Temporada, reloj, tu nivel y XP, pista con GRATIS y PREMIUM (empieza en tu nivel). Toca una casilla con RECLAMAR o RECLAMAR TODO: las recompensas entran por la derecha. PREMIUM y +1 NIVEL abren la compra de Roblox. Misiones de temporada a la derecha (en el móvil, botón MISIONES). |
| **Puntos rojos** | Lobby | TIENDA con punto si hay novedades sin ver; PASE si hay algo por reclamar. Al verlas / reclamarlo se quitan. |
| **Pantalla final** | Acaba una partida | En RECOMPENSAS sale la XP del pase (¡NIVEL N! si sube). Si ganas, tu equipo hace sus poses de victoria y el MVP su intro. De vez en cuando (desde la 4.ª partida, si hiciste 6+ bajas con un arma), una tarjeta pequeña "DOMINASTE CON …" con ✕. |
| **Sin ventaja de pago** | — | No hay ruleta, ni revivir con Robux (la pantalla de muerte dice "Se ganan jugando"), ni cajas con monedas (las cajas ganadas se abren igual), ni armas con monedas (se desbloquean por nivel). |

Para probar el pase rápido, en la consola del **servidor**:

```lua
local PD = require(game.ServerScriptService.Server.Modules.PlayerData)
local p = game.Players:GetPlayers()[1]
PD.AddPassXP(p, 30000) -- 10 niveles del pase
```

## Probar la Navidad ahora (sin esperar a diciembre)

En `src/shared/GameConfig.luau`, dentro de `GameConfig.Events`: al de Halloween ponle `EndsAt = 0` y al
de Navidad `StartsAt = 0`. Al darle a Play: regalos (cajas de colores) en vez de caramelos, muñecos de
nieve en los mapas, la tarjeta "🎄 ¡LLEGA LA NAVIDAD!" para quien ya
había jugado y los premios del evento (Papá Noel a los 50 regalos). **Vuelve a dejar las fechas como
estaban antes de publicar.**

## Darte monedas o nivel en Studio (para probar la tienda)

Con el juego en marcha, en la consola de **servidor** (Ver → Output / barra de comandos, en el lado
servidor):

```lua
local PD = require(game.ServerScriptService.Server.Modules.PlayerData)
local p = game.Players:GetPlayers()[1]
PD.AddCoins(p, 10000, false)
PD.AddXP(p, 5000, "Prueba")
```

## Si algo falla

Abre **Output** (Ver → Output): los errores del juego salen en rojo con el archivo y la línea. Copia ese
texto y pásamelo tal cual: con eso lo arreglo directamente.
