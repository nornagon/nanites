TAU = Math.PI * 2
class World
  constructor: ->
    @resources = []
    @buildings = []
    for i in [0..30]
      @resources.push { kind:'c', x:Math.random()*200, y:Math.random()*200 }

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
  upandright = (x1 % 2 + y1 % 2) % 2 == 1
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
  if x % 2 == 1
    if y % 2 == 0
      return {x:baseX + hexSide/2 + hexSmallX, y:baseY}
    else
      return {x:baseX + hexSide/2, y:baseY}
  else
    if y % 2 == 0
      return {x:baseX + hexSide/2, y:baseY}
    else
      return {x:baseX + hexSide/2 + hexSmallX, y:baseY}
  return {x:baseX, y:baseY}

class Building
  constructor: ->
    @resources = {}

class Nanite
  constructor: ->

class GatherStation extends Building
  constructor: ->
    super

class GatherNanite extends Nanite
  constructor: ->
    super

class NaniteGame extends atom.Game
  constructor: ->
    super
    atom.input.bind atom.button.LEFT, 'click'
    @world = new World

  update: (dt) ->
    if atom.input.pressed 'click'
      building = x:atom.input.mouse.x, y:atom.input.mouse.y
      @world.buildings.push building

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
    ctx.moveTo x, y
    ctx.lineTo x+5,y+5
    ctx.lineWidth = 5
    ctx.strokeStyle = 'red'
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
      ctx.arc b.x, b.y, 15, 0, Math.PI*2, true
      ctx.stroke()
    ctx.beginPath()
    ctx.arc atom.input.mouse.x, atom.input.mouse.y, 15, 0, Math.PI*2, true
    #ctx.stroke()

game = new NaniteGame

window.onblur = -> game.stop()
window.onfocus = -> game.run()

game.run()
