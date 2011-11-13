TAU = Math.PI * 2

hexSide = 22
hexSmallX = Math.cos(TAU/6) * hexSide
hexSmallY = Math.sin(TAU/6) * hexSide
hexDeltaX = hexSmallX + hexSide + hexSmallX + hexSide
hexWidth = hexSide + hexSmallX
nearestGridPointTo = (x, y) ->
  # voronoi:
  # |`.|.'|
  # |.'|`.|
  # |`.|.'|
  x1 = Math.floor (x - hexSide/2 - hexSmallX) / hexWidth
  y1 = Math.floor y / hexSmallY
  x -= x1 * hexWidth + hexSide/2 + hexSmallX
  y -= y1 * hexSmallY
  upandright = (x1 ^ y1) % 2
  if upandright
    slope = -hexSmallY / (hexSide + hexSmallX)
    yAtX = slope * x + hexSmallY
  else
    slope = hexSmallY / (hexSide + hexSmallX)
    yAtX = slope * x
  if y < yAtX
    return { x:x1, y:y1-1 }
  else
    return { x:x1, y:y1 }

xyForGridPoint = (x, y) ->
  baseX = hexWidth * x + hexSide/2 + hexSmallX
  baseY = hexSmallY * (y + 1)
  r = Math.round
  if (x ^ y) % 2
    return {x:0.5+r(baseX + hexSide/2 + hexSmallX), y:1.5+r(baseY)}
  else
    return {x:0.5+r(baseX + hexSide/2), y:1.5+r(baseY)}


dist2 = (x1, y1, x2, y2) ->
  if !x2? and !y2?
    {x:x2, y:y2} = y1
    {x:x1, y:y1} = x1
  dx = x2 - x1
  dy = y2 - y1
  dx*dx+dy*dy
dist = (x1, y1, x2, y2) ->
  unless x2? and y2?
    {x:x2, y:y2} = y1
    {x:x1, y:y1} = x1
  dx = x2 - x1
  dy = y2 - y1
  Math.sqrt dx*dx+dy*dy
normal = (x1, y1, x2, y2) ->
  if !x2? and !y2?
    {x:x2, y:y2} = y1
    {x:x1, y:y1} = x1
  d = dist x1, y1, x2, y2
  { x: (x2-x1)/d, y: (y2-y1)/d }

class World
  constructor: ->
    @resources = []
    @buildings = []
    @nanites = []
    for i in [0..10]
      @resources.push { kind:'c', x:Math.random()*200, y:Math.random()*200 }

  addBuilding: (b) ->
    @buildings.push b
  addNanite: (n) ->
    @nanites.push n

  update: (dt) ->
    b.update? dt for b in @buildings
    n.update? dt for n in @nanites

class Building
  constructor: ->
    @resources = {}

class Nanite
  constructor: ->

class GatherStation extends Building
  constructor: (@x, @y) ->
    super
    {x, y} = xyForGridPoint(@x, @y)
    @bot = new GatherNanite this, x, y
    game.world.addNanite @bot

class GatherNanite extends Nanite
  constructor: (@station, @x, @y) ->
    @speed = 1/60
    @target = null
    @state = 'seeking'
    super
  update: (dt) ->
    switch @state
      when 'seeking'
        if not @target or game.world.resources.indexOf @target < 0
          @acquireTarget()
        if not @target
          @state = 'empty'
          break
        if dist(@, @target) < 5
          i = game.world.resources.indexOf @target
          game.world.resources.splice i, 1
          @target = xyForGridPoint @station.x, @station.y
          @state = 'returning'
      when 'returning'
        if dist(@, @target) < 5
          @target = null
          @state = 'seeking'
      when 'empty'
        @target = @acquireTarget()
        if @target?
          @state = 'seeking'
        else
          @target = xyForGridPoint @station.x, @station.y
    return unless @target
    n = normal @x, @y, @target.x, @target.y
    if dist(@, @target) > @speed * dt
      @x += n.x * @speed * dt
      @y += n.y * @speed * dt
  acquireTarget: ->
    min_d = Infinity
    closest_r = null
    for r in game.world.resources
      d = dist2 @x, @y, r.x, r.y
      if d < min_d
        min_d = d
        closest_r = r
    @target = closest_r

class NaniteGame extends atom.Game
  constructor: ->
    super
    atom.input.bind atom.button.LEFT, 'click'
    @world = new World

  update: (dt) ->
    if atom.input.pressed 'click'
      {x, y} = nearestGridPointTo atom.input.mouse.x, atom.input.mouse.y
      building = new GatherStation x, y
      @world.addBuilding building
    @world.update dt

  draw: ->
    ctx = atom.context
    ctx.fillStyle = 'black'
    ctx.fillRect 0, 0, atom.width, atom.height

    # \_/ \_/ \_/ \_/ \_/
    # / \_/ \_/ \_/ \_/ \_/
    # \_/ \_/ \_/ \_/ \_/
    ctx.beginPath()
    for y in [0..Math.ceil atom.canvas.height/hexSmallY]
      baseY = y * hexSmallY + 0.5
      offsetX = - (y % 2) * (hexSmallX + hexSide)
      for x in [0..Math.ceil atom.canvas.width/hexDeltaX]
        baseX = hexDeltaX * x + offsetX + 0.5
        r = Math.round
        ctx.moveTo baseX, 0.5 + r baseY
        ctx.lineTo baseX+hexSmallX, 0.5 + r baseY+hexSmallY
        ctx.lineTo baseX+hexSmallX+hexSide, 0.5 + r baseY+hexSmallY
        ctx.lineTo baseX+hexSmallX*2+hexSide, 0.5 + r baseY
    ctx.lineWidth = 0.5
    x = atom.input.mouse.x
    y = atom.input.mouse.y
    # stroking with this gradient looks awesome, but it's super expensive
    # gr = ctx.createRadialGradient(x, y, 10, x, y, 160)
    # gr.addColorStop 0, 'rgb(0,190,0)'
    # gr.addColorStop 1, 'rgb(0,110,0)'
    ctx.strokeStyle = 'rgb(0,110,0)'
    ctx.stroke()

    {x,y} = nearestGridPointTo atom.input.mouse.x, atom.input.mouse.y
    {x,y} = xyForGridPoint x, y
    ctx.beginPath()
    ctx.arc x, y, 15, 0, TAU, true
    ctx.strokeStyle = '#0f0'
    ctx.lineWidth = 2
    ctx.stroke()

    ctx.strokeStyle = 'red'
    ctx.lineWidth = 1
    for r in @world.resources
      ctx.beginPath()
      ctx.arc r.x, r.y, 5, 0, Math.PI*2, true
      ctx.stroke()

    ctx.strokeStyle = 'rgb(0,255,0)'
    ctx.lineWidth = 2
    for b in @world.buildings
      ctx.beginPath()
      {x, y} = xyForGridPoint b.x, b.y
      ctx.arc x, y, 15, 0, TAU, true
      ctx.stroke()

    for n in @world.nanites
      ctx.beginPath()
      ctx.arc n.x, n.y, 3, 0, TAU, true
      ctx.stroke()
game = new NaniteGame

window.onblur = -> game.stop()
window.onfocus = -> game.run()

game.run()
